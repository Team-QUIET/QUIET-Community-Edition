"""Exercise the real release script using temporary Git repos and a local bare origin."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / '.github/scripts/release.ps1'
PWSH = shutil.which('pwsh')


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='quiet-release-test-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / 'arbitrary-checkout-name'
        self.repo.mkdir()
        self.origin = self.base / 'origin.git'
        self.output = self.base / 'output'
        self.env = dict(os.environ)
        self.env.pop('GITHUB_OUTPUT', None)
        self.git('init', '-b', 'main')
        self.git('config', 'user.name', 'Release test')
        self.git('config', 'user.email', 'test@example.invalid')
        self.git('config', 'core.autocrlf', 'false')
        self.write('mod_info.lua', 'name = "QUIET"\nversion = 2.65\nuid = "unchanged"\n')
        self.write('modules/extra/mod_info.lua', 'version = 1.00\n')
        self.write('lua/file with spaces.lua', 'return true\n')
        self.write('.github/internal.yml', 'internal\n')
        self.write('.vscode/settings.json', '{}\n')
        self.write('.gitattributes', (ROOT / '.gitattributes').read_text())
        self.commit('Initial mod')
        self.initial = self.git('rev-parse', 'HEAD')
        self.git('init', '--bare', str(self.origin))
        self.git('remote', 'add', 'origin', str(self.origin))
        self.git('push', 'origin', 'main')

    def git(self, *args):
        result = subprocess.run(['git', *args], cwd=self.repo, env=self.env,
                                text=True, capture_output=True, check=True)
        return result.stdout.strip()

    def write(self, relative, content):
        path = self.repo / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding='utf-8', newline='')

    def commit(self, message):
        self.git('add', '.')
        self.git('commit', '-m', message)

    def run_release(self, *args, error=None):
        result = subprocess.run([PWSH, '-NoProfile', '-File', str(SCRIPT),
                                 '-OutputDirectory', str(self.output), *args],
                                cwd=self.repo, env=self.env, text=True, capture_output=True)
        if error:
            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertIn(error, result.stderr + result.stdout)
            return
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        return json.loads((self.output / 'release.json').read_text(encoding='utf-8-sig'))

    def test_manual_bump_archive_publish_and_retry(self):
        self.write('untracked.tmp', 'must not ship')
        result = self.run_release('-Bump')
        self.assertEqual(result['tag'], 'V2.66')
        self.assertEqual(self.git('show', f"{result['sha']}:mod_info.lua"),
                         'name = "QUIET"\nversion = 2.66\nuid = "unchanged"')
        self.assertEqual(self.git('diff-tree', '--no-commit-id', '--name-only', '-r', result['sha']),
                         'mod_info.lua')
        with zipfile.ZipFile(result['archive_path']) as archive:
            self.assertIsNone(archive.testzip())
            names = archive.namelist()
            self.assertTrue(all(n.startswith('QUIET-Community-Edition/') for n in names))
            self.assertIn('QUIET-Community-Edition/lua/file with spaces.lua', names)
            self.assertFalse(any('/.github/' in n or '/.vscode/' in n or 'untracked.tmp' in n for n in names))
            self.assertIn(b'version = 2.66', archive.read('QUIET-Community-Edition/mod_info.lua'))
            self.assertEqual(archive.read('QUIET-Community-Edition/modules/extra/mod_info.lua'), b'version = 1.00\n')
        self.run_release('-PublishRefs')
        self.assertEqual(self.git('ls-remote', 'origin', 'refs/heads/main').split()[0], result['sha'])
        self.assertEqual(self.git('ls-remote', 'origin', 'refs/tags/V2.66').split()[0], result['sha'])
        self.git('checkout', '--detach', self.initial)
        retry = self.run_release('-Bump')
        self.assertEqual(retry['sha'], result['sha'])
        self.assertEqual(retry['archive_hash'], result['archive_hash'])
        self.run_release('-PublishRefs')

    def test_push_with_real_version_change_is_not_skipped(self):
        self.write('mod_info.lua', 'name = "QUIET"\nversion = 2.66\nuid = "unchanged"\n')
        self.commit('Bump version manually')
        result = self.run_release('-Before', self.initial)
        self.assertEqual(result['should_release'], 'true')
        self.assertEqual(result['sha'], self.git('rev-parse', 'HEAD'))
        self.assertEqual(result['bumped'], 'false')
        self.git('push', 'origin', 'main')
        self.run_release('-PublishRefs')
        self.assertEqual(self.git('ls-remote', 'origin', 'refs/tags/V2.66').split()[0], result['sha'])

    def test_metadata_only_push_skips(self):
        self.write('mod_info.lua', 'name = "Updated description"\nversion = 2.65\n')
        self.commit('Metadata only')
        self.assertEqual(self.run_release('-Before', self.initial), {'should_release': 'false'})
        self.assertFalse((self.output / 'QUIET-Community-Edition.zip').exists())

    def test_rollover_uses_valid_lua_number(self):
        self.write('mod_info.lua', 'version = 2.99\n')
        self.commit('Last hundredth')
        self.assertEqual(self.run_release('-Bump')['version'], '3.00')

    def test_explicit_version_and_changelog(self):
        self.write('changelog/V2.70.md', '# Custom release notes\n')
        self.commit('Release notes')
        result = self.run_release('-Bump', '-Version', '2.70')
        self.assertEqual(result['version'], '2.70')
        self.assertEqual(Path(result['release_body']).read_text().strip(), '# Custom release notes')

    def test_reject_invalid_or_older_requested_version(self):
        for version in ['2.65', '2.64', '2.66.1', 'anything']:
            with self.subTest(version=version):
                self.run_release('-Bump', '-Version', version, error='Requested version must')
        self.assertEqual(self.git('rev-parse', 'HEAD'), self.initial)

    def test_conflicting_tag_is_never_moved(self):
        self.git('tag', 'V2.66')
        self.run_release('-Bump', error='already exists with different content')
        self.assertEqual(self.git('rev-parse', 'V2.66'), self.initial)

    def test_main_advancing_prevents_branch_and_tag_publication(self):
        self.run_release('-Bump')
        self.git('checkout', '--detach', self.initial)
        self.write('lua/new.lua', 'return false\n')
        self.commit('Concurrent change')
        other = self.git('rev-parse', 'HEAD')
        self.git('push', 'origin', 'HEAD:main')
        self.run_release('-PublishRefs', error='main advanced')
        self.assertEqual(self.git('ls-remote', 'origin', 'refs/heads/main').split()[0], other)
        self.assertEqual(self.git('ls-remote', 'origin', 'refs/tags/V2.66'), '')

    def test_modified_archive_prevents_publication(self):
        result = self.run_release('-Bump')
        with open(result['archive_path'], 'ab') as archive:
            archive.write(b'changed')
        self.run_release('-PublishRefs', error='archive changed')
        self.assertEqual(self.git('ls-remote', 'origin', 'refs/tags/V2.66'), '')

    def test_existing_tag_cannot_hide_a_missing_main_version_commit(self):
        result = self.run_release('-Bump')
        self.git('push', 'origin', f"{result['sha']}:refs/tags/V2.66")
        self.run_release('-PublishRefs', error='tagged version commit is not on main')
        self.assertEqual(self.git('ls-remote', 'origin', 'refs/heads/main').split()[0], self.initial)


if __name__ == '__main__':
    unittest.main(verbosity=2)
