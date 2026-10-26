$ErrorActionPreference = 'Stop'

# This script lives in the .ai-skills submodule; its parent is the consuming project.
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceRoot = Join-Path $projectRoot '.ai-skills'

if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    throw "The ai-skills submodule was not found at '$sourceRoot'. Mount it at .ai-skills."
}

$plan = @{}
$packs = Get-ChildItem -LiteralPath $sourceRoot -Directory | Where-Object {
    (Test-Path -LiteralPath (Join-Path $_.FullName 'agents') -PathType Container) -or
    (Test-Path -LiteralPath (Join-Path $_.FullName 'instructions') -PathType Container) -or
    (Test-Path -LiteralPath (Join-Path $_.FullName 'skills') -PathType Container) -or
    (Test-Path -LiteralPath (Join-Path $_.FullName 'prompts') -PathType Container)
}

foreach ($pack in $packs) {
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
        foreach ($file in Get-ChildItem -LiteralPath $instructionsDir -File -Recurse -Filter '*.md') {
            $inside = $file.FullName.Substring($instructionsDir.Length).TrimStart([char[]]@('\', '/'))
            $flatName = $inside -replace '[\\/]', '-'
            $relativeTarget = ".github\instructions\$($pack.Name)-$flatName"
            if ($plan.ContainsKey($relativeTarget)) {
                throw "Two source files map to '$relativeTarget'. Rename one of them."
            }
            $plan[$relativeTarget] = $file.FullName
        }
    }

    $promptsDir = Join-Path $pack.FullName 'prompts'
    if (Test-Path -LiteralPath $promptsDir -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $promptsDir -File -Recurse -Filter '*.md') {
            $inside = $file.FullName.Substring($promptsDir.Length).TrimStart([char[]]@('\', '/'))
            $flatName = $inside -replace '[\\/]', '-'
            $relativeTarget = ".github\prompts\$($pack.Name)-$flatName"
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

# Without a manifest, the pack prefix is the ownership boundary. Only files
# and skill folders with a current pack prefix are replaced; unrelated files stay.
foreach ($pack in $packs) {
    $prefix = "$($pack.Name)-"
    foreach ($relativeDir in @('.github\agents', '.github\instructions', '.github\prompts')) {
        $destination = Join-Path $projectRoot $relativeDir
        if (Test-Path -LiteralPath $destination -PathType Container) {
            Get-ChildItem -LiteralPath $destination -File -Force |
                Where-Object { $_.Name.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) } |
                Remove-Item -Force
        }
    }

    $skillsDestination = Join-Path $projectRoot '.github\skills'
    if (Test-Path -LiteralPath $skillsDestination -PathType Container) {
        Get-ChildItem -LiteralPath $skillsDestination -Directory -Force |
            Where-Object { $_.Name.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) } |
            Remove-Item -Recurse -Force
    }
}

foreach ($relativeTarget in $plan.Keys) {
    $target = Join-Path $projectRoot $relativeTarget
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $plan[$relativeTarget] -Destination $target -Force
}

Write-Host "Synchronized $($plan.Count) files from .ai-skills."
