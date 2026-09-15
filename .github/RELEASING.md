# Publishing QUIET Community Edition

In Actions, choose **Release Mod Package**, then **Run workflow** on **main**.
Leave `bump` enabled and `version` blank to increment the numeric mod version by
0.01 (for example, `2.65` to `2.66`, or `2.99` to `3.00`). Set `version` to a
larger `X.YY` value to choose a specific release number.

The workflow commits only the root `mod_info.lua` version change, builds and
checks `QUIET-Community-Edition.zip`, pushes the version commit and `V<version>`
tag together, then uploads the ZIP to that tag's GitHub release. The archive
contains one `QUIET-Community-Edition/` directory with the mod files and bundled
modules. The tag, archived metadata, and committed metadata identify the same
release. Repository tooling and untracked files are excluded.

A push to main that already changes `mod_info.lua`'s version releases that exact
commit without another bump. Metadata-only edits do not publish a release.
Reusable workflow callers default to bumping; pass `bump: false` to package the
current version. Manual runs also offer that option. Only main can publish.

Release notes come from `changelog/V<version>.md` when present; otherwise they
identify the version and source commit. Keep `QUIET-Community-Edition.zip` as the
asset name for existing download links.

If the upload fails after refs are pushed, rerun the original failed run. It
reuses the version/tag only when the entire source tree matches, so a retry does
not create another version. Starting a new manual run with `bump` enabled means
a new release. An existing tag with different content is rejected, never moved.
If main advances before a new bump can be pushed, start a fresh run from main.

The workflow uses its existing `GITHUB_TOKEN` with `contents: write`. Its own
version commit does not recursively trigger another push workflow. If branch
rules later prohibit bot commits, those rules must permit the release workflow;
the script does not bypass them or force-push.

Run the regression checks with PowerShell 7 and Python installed:

```text
python .github/scripts/test_release.py
```

Tests publish refs only to temporary local bare repositories. They do not
create real GitHub tags or releases.
