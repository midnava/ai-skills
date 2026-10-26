# ai-skills

A central repository for reusable agents, instructions, prompts, and skills. Add this repository to a consuming project as the `.ai-skills` submodule. Its update script collects the pack files into the project’s standard `.github` directories.

## Pack structure

Each top-level directory is a separate pack. For example:

```text
ai-skills/
  good-ai/
    agents/*.agent.md
    instructions/*.instructions.md
    prompts/*.prompt.md
    skills/<skill-name>/SKILL.md
    skills/<skill-name>/scripts/...
  rti/
    agents/*.agent.md
    instructions/*.instructions.md
    prompts/*.prompt.md
    skills/<skill-name>/SKILL.md
```

The `prompts` and `skills` directories are optional. A skill can include `SKILL.md` and supporting files such as scripts, templates, and other resources.

## Add the submodule to a project

Run these commands from the consuming project’s root:

```powershell
git submodule add -b main https://github.com/midnava/ai-skills.git .ai-skills
powershell -NoProfile -ExecutionPolicy Bypass -File .\.ai-skills\ai-update.ps1
git add .gitmodules .ai-skills .github
git commit -m "Add shared AI files"
```

Do not mount this repository at `.github`: the submodule would occupy the entire destination directory. `.ai-skills` holds the source; the collected files go into `.github`.

## Clone a project

Clone the project with its submodule, then run synchronization:

```powershell
git clone --recurse-submodules <PROJECT-URL>
cd <PROJECT-DIRECTORY>
powershell -NoProfile -ExecutionPolicy Bypass -File .\.ai-skills\ai-update.ps1
```

For an existing clone, the same script initializes the submodule if needed, updates it, and collects the files.

## Update the shared files

After publishing changes to `ai-skills`, update the submodule and synchronize its files from the consuming project root:

```powershell
git submodule update --init --recursive --remote -- .ai-skills
powershell -NoProfile -ExecutionPolicy Bypass -File .\.ai-skills\sync-ai.ps1
git status
git add .ai-skills .github
git commit -m "Update shared AI files"
```

The first command fetches the latest submodule commit. The second copies agents, instructions, prompts, and skills into `.github`.

Alternatively, run the wrapper, which performs both commands above:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.ai-skills\ai-update.ps1
```

The project commit records the new submodule revision and generated files, so other developers receive the same version.
## File mapping

| Source | Destination in the project |
| --- | --- |
| `<pack>/agents/*.agent.md` | `.github/agents/<pack>-<name>.agent.md` |
| `<pack>/instructions/*.md` | `.github/instructions/<pack>-<name>.md` |
| `<pack>/prompts/*.prompt.md` | `.github/prompts/<pack>-<name>.prompt.md` |
| `<pack>/skills/<skill>/...` | `.github/skills/<pack>-<skill>/...` |

Nested directories under `agents`, `instructions`, and `prompts` are flattened into filenames using hyphens. Files and resources inside skills keep their directory structure.

## What synchronization replaces

The sync script replaces only generated files whose names start with a current pack prefix, such as `good-ai-` or `rti-`. Other files in `.github` are left alone. No manifest is used. If you remove an entire pack from `ai-skills`, manually delete that pack’s previously generated files from `.github`.

Files under `<pack>/scripts` are not copied separately. If a skill needs supporting scripts, keep them inside that skill’s directory.
