# AGENTS.md - Agent Instructions for AI CLI Tools in Docker

## Repository Purpose

This repository provides Docker-based runtimes for AI CLI tools
(CodeRabbit, OpenAI Codex). Each tool runs in its own container with
the user's project mounted at `/workspace`.

## Command Grammar

```
.\make.ps1 <target> <tool>    (Windows, PowerShell)
./make.sh <target> <tool>     (Linux/macOS, Bash)
```

Always determine the user's platform before generating commands.

## Required Precondition

`WORKSPACE` must be set to the host project path before any target
except `help`.

PowerShell:

```
$env:WORKSPACE = "D:\Projects\my-app"
```

Bash:

```
export WORKSPACE=/home/user/projects/my-app
```

## Supported Tools

| Argument      | Container command |
|---------------|-------------------|
| `coderabbit`  | `cr`              |
| `codex`       | `codex`           |

## Targets

| Target    | What it does                          |
|-----------|---------------------------------------|
| `help`    | Show usage (no WORKSPACE needed)      |
| `build`   | Build the Docker image                |
| `up`      | Start the container (detached)        |
| `shell`   | Open Bash inside the running container|
| `ps`      | Show container status                 |
| `down`    | Stop and remove container             |
| `rebuild` | Rebuild image without cache           |
| `clean`   | Remove container, image, and auth vol |

## Standard Workflow

1. Set `WORKSPACE` to the target project directory.
2. Build the image: `.\make.ps1 build <tool>`
3. Start the container: `.\make.ps1 up <tool>`
4. Enter the shell: `.\make.ps1 shell <tool>`
5. Inside the container, run the CLI from `/workspace`.
6. On the host after finishing: `.\make.ps1 down <tool>`

## Authentication

Each tool has a persistent Docker volume that survives `down`:

- CodeRabbit: `coderabbit-config` -> `/root/.coderabbit`
- Codex: `codex-config` -> `/root/.codex`

Run `.\make.ps1 clean <tool>` to delete the volume and start fresh.

## Safety

The mounted project is writable inside the container. Any file
modifications made by the AI CLI under `/workspace` are real changes
to the host project. Check `git status` before and after running tools
that may modify files.

## Common Errors to Avoid

- Do not generate `build`, `up`, `shell`, `down`, `rebuild`, `ps`, or
  `clean` commands without `WORKSPACE` being set first.
- Do not use `.\make.ps1` for a Linux/macOS user (use `./make.sh`).
- Do not use `./make.sh` for a Windows user (use `.\make.ps1`).
- Do not omit the `build` step unless you know the image already exists.
- Do not generate container commands (`cr`, `codex`) as host commands.
