[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$OutputDirectory,
    [string]$Version = '',
    [switch]$Bump,
    [string]$Before = '',
    [switch]$PublishRefs
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)
    $result = & git @Arguments
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed ($LASTEXITCODE)" }
    # Native command output is an array of lines. Regex captures need one string.
    return ($result -join "`n")
}

function Get-ModVersion([string]$Content) {
    $pattern = '(?m)^[ \t]*version[ \t]*=[ \t]*([0-9]+\.[0-9]{2})[ \t]*(?:--[^\r\n]*)?\r?$'
    $found = [regex]::Matches($Content, $pattern)
    if ($found.Count -ne 1) { throw 'Expected exactly one numeric version = X.YY in mod_info.lua' }
    return $found[0].Groups[1].Value
}

function Write-Result($Result) {
    $Result | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding utf8NoBOM
    if ($env:GITHUB_OUTPUT) {
        foreach ($key in $Result.Keys) {
            "$key=$($Result[$key])" | Out-File -LiteralPath $env:GITHUB_OUTPUT -Encoding utf8 -Append
        }
    }
}

$repoRoot = Invoke-Git rev-parse --show-toplevel
Set-Location -LiteralPath $repoRoot
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
if ($OutputDirectory.TrimEnd('/','\') -eq $repoRoot.TrimEnd('/','\') -or
    $OutputDirectory.StartsWith([IO.Path]::GetFullPath($repoRoot) + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Release output must be outside the repository'
}
$manifestPath = Join-Path $OutputDirectory 'release.json'

if ($PublishRefs) {
    $release = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($release.should_release -ne 'true') { return }
    if ((Get-FileHash -LiteralPath $release.archive_path -Algorithm SHA256).Hash -ne $release.archive_hash) {
        throw 'The verified release archive changed; refusing to publish refs'
    }
    $tagRef = "refs/tags/$($release.tag)"
    $remoteTag = Invoke-Git ls-remote origin $tagRef "$tagRef^{}"
    if ($remoteTag) {
        # Prefer the peeled commit for annotated tags.
        $tagLines = $remoteTag -split "`n"
        $remoteSha = ($tagLines[-1] -split '\s+')[0]
        if ($remoteSha -ne $release.sha) { throw "Remote $tagRef points to a different commit" }
        if ($release.bumped -eq 'true') {
            Invoke-Git fetch origin main | Out-Null
            & git merge-base --is-ancestor $release.sha FETCH_HEAD
            if ($LASTEXITCODE -ne 0) { throw 'The tagged version commit is not on main' }
        }
        Write-Host "Reusing $($release.tag) at $($release.sha)"
        return
    }
    $localTag = Invoke-Git tag --list $release.tag
    if ($localTag) {
        if ((Invoke-Git rev-parse "$tagRef^{commit}") -ne $release.sha) {
            throw "Local $tagRef points to a different commit"
        }
    } else {
        Invoke-Git tag $release.tag $release.sha | Out-Null
    }
    if ($release.bumped -eq 'true') {
        $remoteMain = ((Invoke-Git ls-remote origin refs/heads/main) -split '\s+')[0]
        if ($remoteMain -ne $release.base_sha) {
            throw 'main advanced while preparing the release. Start a new run from current main.'
        }
        # No force push: branch advancement and tag creation either both succeed or neither does.
        Invoke-Git push --atomic origin "$($release.sha):refs/heads/main" $tagRef | Out-Null
    } else {
        Invoke-Git push origin $tagRef | Out-Null
    }
    return
}

if (Invoke-Git status --porcelain --untracked-files=no) { throw 'Release requires a clean tracked working tree' }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$baseSha = Invoke-Git rev-parse HEAD
$content = [IO.File]::ReadAllText((Join-Path $repoRoot 'mod_info.lua'))
$currentVersion = Get-ModVersion $content
$culture = [Globalization.CultureInfo]::InvariantCulture
$currentNumber = [decimal]::Parse($currentVersion, $culture)

if ($Bump) {
    if (-not $Version) { $Version = ($currentNumber + [decimal]0.01).ToString('0.00', $culture) }
    if ($Version -notmatch '^[0-9]+\.[0-9]{2}$' -or [decimal]::Parse($Version, $culture) -le $currentNumber) {
        throw "Requested version must be X.YY and greater than $currentVersion"
    }
    $content = [regex]::Replace($content, '(?m)^([ \t]*version[ \t]*=[ \t]*)[0-9]+\.[0-9]{2}',
        [Text.RegularExpressions.MatchEvaluator]{ param($match) $match.Groups[1].Value + $Version })
    [IO.File]::WriteAllText((Join-Path $repoRoot 'mod_info.lua'), $content, [Text.UTF8Encoding]::new($false))
    Invoke-Git add -- mod_info.lua | Out-Null
} else {
    if ($Version) { throw 'An explicit version requires bump to be enabled' }
    $Version = $currentVersion
    if ($Before -and $Before -notmatch '^0+$') {
        $previousVersion = Get-ModVersion (Invoke-Git show "${Before}:mod_info.lua")
        if ($previousVersion -eq $Version) {
            Write-Result @{ should_release = 'false' }
            Write-Host 'mod_info.lua changed without a version bump; no release needed.'
            return
        }
        if ([decimal]::Parse($previousVersion, $culture) -ge $currentNumber) {
            throw 'A pushed release version must increase'
        }
    }
}

$tag = "V$Version"
$tagRef = "refs/tags/$tag"
if (Invoke-Git tag --list $tag) {
    # A rerun starts at the original event SHA. Reuse its already-published version
    # commit only if the entire proposed tree matches, never move an old release tag.
    $expectedTree = Invoke-Git write-tree
    if ((Invoke-Git rev-parse "$tagRef^{tree}") -ne $expectedTree) {
        throw "$tag already exists with different content; choose a new version"
    }
    $sha = Invoke-Git rev-parse "$tagRef^{commit}"
} else {
    if ($Bump) {
        Invoke-Git -c user.name=github-actions[bot] -c user.email=41898282+github-actions[bot]@users.noreply.github.com `
            commit -m "Release $tag" -- mod_info.lua | Out-Null
    }
    $sha = Invoke-Git rev-parse HEAD
}

$prefix = 'QUIET-Community-Edition/'
$archivePath = Join-Path $OutputDirectory 'QUIET-Community-Edition.zip'
Invoke-Git archive --format=zip "--prefix=$prefix" "--output=$archivePath" $sha | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    $entry = $archive.GetEntry("${prefix}mod_info.lua")
    if (-not $entry) { throw 'ZIP does not contain QUIET-Community-Edition/mod_info.lua' }
    $reader = [IO.StreamReader]::new($entry.Open())
    try { $archivedVersion = Get-ModVersion $reader.ReadToEnd() } finally { $reader.Dispose() }
    if ($archivedVersion -ne $Version) { throw 'ZIP version does not match the release tag' }
    foreach ($item in $archive.Entries) {
        if (-not $item.FullName.StartsWith($prefix) -or
            $item.FullName -match '^QUIET-Community-Edition/\.(git|github|vscode)(/|$)') {
            throw "Unexpected ZIP entry: $($item.FullName)"
        }
    }
} finally { $archive.Dispose() }

$bodyPath = Join-Path $OutputDirectory 'release-notes.md'
$changelog = "changelog/$tag.md"
if (Invoke-Git ls-tree --name-only $sha -- $changelog) {
    Invoke-Git show "${sha}:$changelog" | Set-Content -LiteralPath $bodyPath -Encoding utf8NoBOM
} else {
    "# $tag`n`nQUIET Community Edition $Version.`n`nBuilt from commit $sha." |
        Set-Content -LiteralPath $bodyPath -Encoding utf8NoBOM
}
Write-Result @{
    should_release = 'true'
    version = $Version
    tag = $tag
    sha = $sha
    base_sha = $baseSha
    bumped = $Bump.IsPresent.ToString().ToLowerInvariant()
    archive_path = $archivePath
    archive_hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
    release_body = $bodyPath
}
Write-Host "Verified $tag from $sha -> $archivePath"
