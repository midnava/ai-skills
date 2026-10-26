$ErrorActionPreference = 'Stop'

# This script lives in the .ai-skills submodule; its parent is the consuming project.
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceRoot = Join-Path $projectRoot '.ai-skills'
$manifestPath = Join-Path $projectRoot '.ai-skills-sync.json'
$allowedPrefixes = @('.github\agents\', '.github\instructions\', '.github\skills\')

if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    throw "The ai-skills submodule was not found at '$sourceRoot'. Mount it at .ai-skills."
}

$plan = @{}

foreach ($pack in Get-ChildItem -LiteralPath $sourceRoot -Directory) {
    $agentsDir = Join-Path $pack.FullName 'agents'
    if (Test-Path -LiteralPath $agentsDir -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $agentsDir -File -Recurse -Filter '*.agent.md') {
            $inside = $file.FullName.Substring($agentsDir.Length).TrimStart([char[]]@('\', '/'))
            $flatName = $inside -replace '[\\/]', '-'
            $relativeTarget = ".github\agents\$($pack.Name)-$flatName"
            if ($plan.ContainsKey($relativeTarget)) {
                throw "Two source files map to '$relativeTarget'. Rename one of them."
            }
            $plan[$relativeTarget] = $file.FullName
        }
    }

    $instructionsDir = Join-Path $pack.FullName 'instructions'
    if (Test-Path -LiteralPath $instructionsDir -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $instructionsDir -File -Recurse -Filter '*.instructions.md') {
            $inside = $file.FullName.Substring($instructionsDir.Length).TrimStart([char[]]@('\', '/'))
            $flatName = $inside -replace '[\\/]', '-'
            $relativeTarget = ".github\instructions\$($pack.Name)-$flatName"
            if ($plan.ContainsKey($relativeTarget)) {
                throw "Two source files map to '$relativeTarget'. Rename one of them."
            }
            $plan[$relativeTarget] = $file.FullName
        }
    }

    $skillsDir = Join-Path $pack.FullName 'skills'
    if (Test-Path -LiteralPath $skillsDir -PathType Container) {
        foreach ($skill in Get-ChildItem -LiteralPath $skillsDir -Directory) {
            if (-not (Test-Path -LiteralPath (Join-Path $skill.FullName 'SKILL.md') -PathType Leaf)) {
                throw "Skill '$($skill.FullName)' has no SKILL.md."
            }

            $skillTarget = ".github\skills\$($pack.Name)-$($skill.Name)"
            foreach ($file in Get-ChildItem -LiteralPath $skill.FullName -File -Recurse -Force) {
                $inside = $file.FullName.Substring($skill.FullName.Length).TrimStart([char[]]@('\', '/'))
                $relativeTarget = Join-Path $skillTarget $inside
                if ($plan.ContainsKey($relativeTarget)) {
                    throw "Two source files map to '$relativeTarget'. Rename one of them."
                }
                $plan[$relativeTarget] = $file.FullName
            }
        }
    }
}

function Resolve-GeneratedTarget([string]$relativePath) {
    if ([IO.Path]::IsPathRooted($relativePath) -or $relativePath -match '(^|[\\/])\.\.([\\/]|$)') {
        throw "Unsafe path in sync manifest: '$relativePath'"
    }

    $fullPath = [IO.Path]::GetFullPath((Join-Path $projectRoot $relativePath))
    foreach ($allowed in $allowedPrefixes) {
        $allowedRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot $allowed.TrimEnd([char[]]@('\', '/'))))
        $allowedRootPrefix = $allowedRoot.TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar
        if ($fullPath.StartsWith($allowedRootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            return $fullPath
        }
    }
    throw "Sync manifest path is outside generated .github folders: '$relativePath'"
}

$oldFiles = @()
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($null -eq $manifest.files) {
        throw "Invalid sync manifest: '$manifestPath' has no files list."
    }
    $oldFiles = @($manifest.files | ForEach-Object { [string]$_ })
}

$oldSet = @{}
foreach ($relativePath in $oldFiles) {
    $oldSet[$relativePath] = $true
    [void](Resolve-GeneratedTarget $relativePath)
}

# Refuse to overwrite files that were not created by an earlier sync.
foreach ($relativePath in $plan.Keys) {
    $target = Resolve-GeneratedTarget $relativePath
    if ((Test-Path -LiteralPath $target) -and -not $oldSet.ContainsKey($relativePath)) {
        throw "Refusing to overwrite an existing project file: '$target'"
    }
}

# Remove stale generated files only; unrelated project files are left alone.
foreach ($relativePath in $oldFiles) {
    if (-not $plan.ContainsKey($relativePath)) {
        $target = Resolve-GeneratedTarget $relativePath
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            Remove-Item -LiteralPath $target -Force
        }
    }
}

foreach ($relativePath in $plan.Keys) {
    $target = Resolve-GeneratedTarget $relativePath
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $plan[$relativePath] -Destination $target -Force
}

[ordered]@{ files = @($plan.Keys | Sort-Object) } |
    ConvertTo-Json -Depth 3 |
    Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Host "Synchronized $($plan.Count) files from .ai-skills."
