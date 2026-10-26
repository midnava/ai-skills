$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceRoot = Join-Path $projectRoot '.ai-skills'
$manifestPath = Join-Path $projectRoot '.ai-skills-sync.json'

if (-not (Test-Path -LiteralPath $sourceRoot)) {
    throw "Не найден submodule: $sourceRoot"
}

# Здесь будут пары: целевой файл -> исходный файл
$plan = @{}

foreach ($pack in Get-ChildItem -LiteralPath $sourceRoot -Directory) {
    # Agents: good-ai/agents/review.agent.md
    #      -> .github/agents/good-ai-review.agent.md
    $agentsDir = Join-Path $pack.FullName 'agents'
    if (Test-Path -LiteralPath $agentsDir) {
        foreach ($file in Get-ChildItem -LiteralPath $agentsDir -File -Recurse -Filter '*.agent.md') {
            $relativeTarget = ".github\agents\$($pack.Name)-$($file.Name)"
            $plan[$relativeTarget] = $file.FullName
        }
    }

    # Instructions: rti/instructions/java.instructions.md
    #            -> .github/instructions/rti-java.instructions.md
    $instructionsDir = Join-Path $pack.FullName 'instructions'
    if (Test-Path -LiteralPath $instructionsDir) {
        foreach ($file in Get-ChildItem -LiteralPath $instructionsDir -File -Recurse -Filter '*.instructions.md') {
            $relativeTarget = ".github\instructions\$($pack.Name)-$($file.Name)"
            $plan[$relativeTarget] = $file.FullName
        }
    }

    # Skills сохраняют свои папки и вспомогательные файлы.
    $skillsDir = Join-Path $pack.FullName 'skills'
    if (Test-Path -LiteralPath $skillsDir) {
        foreach ($skill in Get-ChildItem -LiteralPath $skillsDir -Directory) {
            $skillTarget = ".github\skills\$($pack.Name)-$($skill.Name)"

            foreach ($file in Get-ChildItem -LiteralPath $skill.FullName -File -Recurse) {
                $insideSkill = $file.FullName.Substring($skill.FullName.Length).TrimStart('\')
                $relativeTarget = Join-Path $skillTarget $insideSkill
                $plan[$relativeTarget] = $file.FullName
            }
        }
    }
}

# Манифест позволяет удалить только ранее собранные файлы,
# которых больше нет в ai-skills.
$oldFiles = @()
if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $oldFiles = @($manifest.files)
}

$oldSet = @{}
foreach ($file in $oldFiles) {
    $oldSet[$file] = $true
}

# Не перезаписывать файлы проекта, которыми скрипт раньше не управлял.
foreach ($relativeTarget in $plan.Keys) {
    $target = Join-Path $projectRoot $relativeTarget
    if ((Test-Path -LiteralPath $target) -and -not $oldSet.ContainsKey($relativeTarget)) {
        throw "Файл уже существует; скрипт не будет его перезаписывать: $target"
    }
}

# Удалить устаревшие файлы из предыдущей синхронизации.
foreach ($relativeTarget in $oldFiles) {
    if (-not $plan.ContainsKey($relativeTarget)) {
        $target = Join-Path $projectRoot $relativeTarget
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Force
        }
    }
}

# Скопировать текущие файлы.
foreach ($relativeTarget in $plan.Keys) {
    $target = Join-Path $projectRoot $relativeTarget
    $targetDir = Split-Path -Parent $target

    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    Copy-Item -LiteralPath $plan[$relativeTarget] -Destination $target -Force
}

# Запомнить только файлы, которыми управляет скрипт.
[ordered]@{
    files = @($plan.Keys | Sort-Object)
} | ConvertTo-Json -Depth 3 |
    Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Host "Синхронизировано файлов: $($plan.Count)"