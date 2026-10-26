# ai-skills

A central repository for reusable agents, instructions, prompts, and skills. Add it to a consuming project as the `.ai-skills` submodule. Use Git to update the submodule, then run `sync-ai.ps1` to collect pack files into the project’s `.github` directory.

## Pack structure

Each top-level directory is a separate pack. For example:

```text
ai-skills/
  good-ai/
    agents/*.agent.md
    instructions/*.md
    prompts/*.prompt.md
    skills/<skill-name>/SKILL.md
    skills/<skill-name>/scripts/...
  rti/
    agents/*.agent.md
    instructions/*.md
    prompts/*.prompt.md
    skills/<skill-name>/SKILL.md
```

The `prompts` and `skills` directories are optional. A skill can include `SKILL.md` and supporting scripts, templates, or other resources.

## Add the submodule

Run these commands from the consuming project’s root:

```powershell
git submodule add -b main https://github.com/midnava/ai-skills.git .ai-skills
powershell -NoProfile -ExecutionPolicy Bypass -File .\.ai-skills\sync-ai.ps1
git add .gitmodules .ai-skills .github
git commit -m "Add shared AI files"
```

Do not mount this repository at `.github`: the submodule would occupy that entire directory. `.ai-skills` is the source; collected files go into `.github`.

## Clone a project

```powershell
git clone --recurse-submodules <PROJECT-URL>
cd <PROJECT-DIRECTORY>
powershell -NoProfile -ExecutionPolicy Bypass -File .\.ai-skills\sync-ai.ps1
```

For an existing clone, initialize the submodule before running the sync script:

```powershell
git submodule update --init --recursive .ai-skills
powershell -NoProfile -ExecutionPolicy Bypass -File .\.ai-skills\sync-ai.ps1
```

## Update shared files

After publishing changes to `ai-skills`, run this from the consuming project root:

```powershell
git submodule update --init --recursive --remote -- .ai-skills
powershell -NoProfile -ExecutionPolicy Bypass -File .\.ai-skills\sync-ai.ps1
git status
git add .ai-skills .github
git commit -m "Update shared AI files"
```

The first command fetches the latest submodule commit. The sync script copies agents, instructions, prompts, and skills into `.github`. The project commit records both the new submodule revision and generated files, so other developers receive the same version.

## File mapping

| Source | Destination in the project |
| --- | --- |
| `<pack>/agents/*.agent.md` | `.github/agents/<pack>-<name>.agent.md` |
| `<pack>/instructions/*.md` | `.github/instructions/<pack>-<name>.md` |
| `<pack>/prompts/*.prompt.md` | `.github/prompts/<pack>-<name>.prompt.md` |
| `<pack>/skills/<skill>/...` | `.github/skills/<pack>-<skill>/...` |

Nested directories under `agents`, `instructions`, and `prompts` are flattened into filenames using hyphens. Files and resources inside skills keep their directory structure.

## What synchronization replaces

The sync script replaces files and skill folders with a current pack prefix, such as `good-ai-` or `rti-`. Other files in `.github` are left alone. No manifest is used. If you remove an entire pack from `ai-skills`, manually remove that pack’s previously generated files from `.github`.

Files under `<pack>/scripts` are not copied separately. Put scripts needed by a skill inside that skill’s directory.
