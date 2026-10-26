$ErrorActionPreference = 'Stop'

# This script is expected to run from <project>/.ai-skills.
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSubmodule = [IO.Path]::GetFullPath((Join-Path $projectRoot '.ai-skills'))
$actualSubmodule = [IO.Path]::GetFullPath($PSScriptRoot)
if (-not $actualSubmodule.Equals($expectedSubmodule, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Run this script from the .ai-skills submodule. Current path: '$actualSubmodule'"
}

& git -C $projectRoot submodule update --init --recursive --remote -- .ai-skills
if ($LASTEXITCODE -ne 0) {
    throw 'Could not update the .ai-skills submodule.'
}

& (Join-Path $PSScriptRoot 'sync-ai.ps1')
