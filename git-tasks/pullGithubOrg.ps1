<#
.SYNOPSIS
    Clones every repository from a given GitHub organization into a local folder.

.DESCRIPTION
    Creates a folder named after the GitHub organization in the current directory,
    changes into it, then clones every repository in that organization using the
    GitHub CLI (gh). Existing repositories are skipped.

.PARAMETER Organization
    The name (login) of the GitHub organization whose repositories should be cloned.

.PARAMETER Protocol
    The protocol used for cloning. Either 'https' (default) or 'ssh'.

.EXAMPLE
    .\pullGithubOrg.ps1 -Organization microsoft

.EXAMPLE
    .\pullGithubOrg.ps1 microsoft -Protocol ssh
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Organization,

    [Parameter(Position = 1)]
    [ValidateSet('https', 'ssh')]
    [string]$Protocol = 'https'
)

$ErrorActionPreference = 'Stop'

# Verify that the GitHub CLI is installed.
$ghCommand = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghCommand) {
    Write-Error "GitHub CLI ('gh') is not installed or not in PATH. Install it from https://cli.github.com/ and run 'gh auth login' before using this script."
    exit 1
}

# Verify that the user is authenticated with gh.
& gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "You are not authenticated with the GitHub CLI. Run 'gh auth login' first."
    exit 1
}

# Verify that git is installed.
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "git is not installed or not in PATH. Install Git before using this script."
    exit 1
}

# Create the organization folder (if it doesn't already exist) and move into it.
$startingLocation = Get-Location
$orgPath = Join-Path -Path $startingLocation -ChildPath $Organization

if (-not (Test-Path -LiteralPath $orgPath)) {
    Write-Host "Creating folder '$orgPath'..."
    New-Item -ItemType Directory -Path $orgPath | Out-Null
} else {
    Write-Host "Folder '$orgPath' already exists. Reusing it."
}

Set-Location -LiteralPath $orgPath

try {
    Write-Host "Fetching repository list for organization '$Organization'..."

    # Use the GitHub CLI to list every repository in the organization.
    # --limit 4000 should be more than enough for most orgs; raise it if needed.
    # --json nameWithOwner returns "owner/repo" which works for both cloning and naming.
    $reposJson = & gh repo list $Organization --limit 4000 --json nameWithOwner,sshUrl,url 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to list repositories for organization '$Organization'. Output: $reposJson"
        exit 1
    }

    $repos = $reposJson | ConvertFrom-Json

    if ($null -eq $repos -or $repos.Count -eq 0) {
        Write-Warning "No repositories were found for organization '$Organization' (or you do not have access to any)."
        return
    }

    Write-Host "Found $($repos.Count) repositories. Beginning clone..."

    $cloned  = 0
    $skipped = 0
    $failed  = 0

    foreach ($repo in $repos) {
        $fullName = $repo.nameWithOwner
        $repoName = $fullName.Split('/')[-1]
        $targetDir = Join-Path -Path $orgPath -ChildPath $repoName

        if (Test-Path -LiteralPath $targetDir) {
            Write-Host "  [skip]  $fullName (folder already exists)"
            $skipped++
            continue
        }

        $cloneUrl = if ($Protocol -eq 'ssh') { $repo.sshUrl } else { $repo.url }

        Write-Host "  [clone] $fullName"
        & git clone $cloneUrl $targetDir
        if ($LASTEXITCODE -eq 0) {
            $cloned++
        } else {
            Write-Warning "  Failed to clone $fullName (exit code $LASTEXITCODE)."
            $failed++
        }
    }

    Write-Host ""
    Write-Host "Done. Cloned: $cloned, Skipped: $skipped, Failed: $failed."
}
finally {
    Set-Location -LiteralPath $startingLocation
}
