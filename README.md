# AI CLI Tools in Docker

This repository provides Docker-based environments for running third-party AI command-line tools against local projects without installing those tools directly on the host machine.

The current tool environments are:

| Tool | Folder | Command inside container |
| --- | --- | --- |
| CodeRabbit CLI | `coderabbit/` | `cr` |
| OpenAI Codex CLI | `codex/` | `codex` |

The documentation is PowerShell-first because this repository is intended to be convenient on native Windows with Docker Desktop.

## What This Repository Does

The repository builds a separate Docker image for each supported AI CLI. When a container starts, your selected project directory is mounted into the container at `/workspace`.

The AI CLI runs from inside the container and operates on `/workspace`. Any file changes made by the CLI are changes to the real project directory on your host machine.

Authentication and tool-specific configuration are stored in named Docker volumes, so login state survives container restarts and image rebuilds.

## Requirements

- Windows PowerShell or PowerShell 7
- Docker Desktop
- Docker Compose support through `docker compose`
- A local project directory that the AI CLI should operate on

Verify Docker is available:

```powershell
docker --version
docker compose version
```

## Repository Layout

```text
everything_docker/
|-- Makefile
|-- make.sh
|-- make.ps1
|-- README.md
|-- coderabbit/
|   |-- Dockerfile
|   |-- docker-compose.yml
|   `-- README.md
`-- codex/
    |-- Dockerfile
    |-- docker-compose.yml
    `-- README.md
```

Important files:

| File | Purpose |
| --- | --- |
| `make.ps1` | PowerShell command wrapper for building, starting, entering, and cleaning containers. |
| `coderabbit/docker-compose.yml` | Docker Compose service definition for CodeRabbit. |
| `codex/docker-compose.yml` | Docker Compose service definition for Codex. |
| `coderabbit/Dockerfile` | Docker image definition for CodeRabbit CLI. |
| `codex/Dockerfile` | Docker image definition for Codex CLI. |

## Core Concept

There are three important locations:

| Location | Description |
| --- | --- |
| Host project path | The real project directory on your machine. |
| `/workspace` | The same project directory mounted inside the container. |
| Docker volume | Persistent storage for CLI login and configuration. |

Example:

```powershell
$env:WORKSPACE = "D:\Projects\my-app"
```

Inside the container, that project is available as:

```text
/workspace
```

## Quick Start

Run these commands from the repository root.

Set the project directory that the CLI should operate on:

```powershell
$env:WORKSPACE = "D:\Projects\my-app"
```

Build the selected tool image:

```powershell
.\make.ps1 build coderabbit
```

Start the container in the background:

```powershell
.\make.ps1 up coderabbit
```

Open a shell inside the container:

```powershell
.\make.ps1 shell coderabbit
```

Inside the container, authenticate and run the tool:

```bash
cr auth login
cr review
```

To use Codex instead of CodeRabbit, replace `coderabbit` with `codex`:

```powershell
.\make.ps1 build codex
.\make.ps1 up codex
.\make.ps1 shell codex
```

Inside the Codex container:

```bash
codex
```

## Command Reference

The PowerShell wrapper uses this format:

```powershell
.\make.ps1 <target> <tool>
```

Supported tools:

| Tool | Description |
| --- | --- |
| `coderabbit` | Runs the CodeRabbit CLI environment. |
| `codex` | Runs the OpenAI Codex CLI environment. |

Supported targets:

| Target | Description |
| --- | --- |
| `help` | Show wrapper usage and current `WORKSPACE` value. |
| `build` | Build the Docker image for the selected tool. |
| `up` | Start the selected tool container in detached mode. |
| `shell` | Open an interactive Bash shell inside the running container. |
| `ps` | Show container status for the selected tool. |
| `down` | Stop and remove the selected tool container. |
| `rebuild` | Rebuild the Docker image without using build cache. |
| `clean` | Stop the container, remove the local image, and delete the auth/config volume. |

Examples:

```powershell
.\make.ps1 help
.\make.ps1 build coderabbit
.\make.ps1 up coderabbit
.\make.ps1 shell coderabbit
.\make.ps1 ps coderabbit
.\make.ps1 down coderabbit
.\make.ps1 clean coderabbit
```

## Standard Workflow

Use this workflow for normal day-to-day usage.

1. Set `WORKSPACE` to the project you want to work on.
2. Build the image if it has not been built yet.
3. Start the container.
4. Enter the container shell.
5. Run the CLI from inside `/workspace`.
6. Stop the container when finished.

Commands:

```powershell
$env:WORKSPACE = "D:\Projects\my-app"
.\make.ps1 build coderabbit
.\make.ps1 up coderabbit
.\make.ps1 shell coderabbit
```

Inside the container:

```bash
pwd
ls
cr review
exit
```

Back on the host:

```powershell
.\make.ps1 down coderabbit
```

## Switching Projects

To run the same tool against a different project, update `WORKSPACE` and restart the container.

```powershell
.\make.ps1 down coderabbit
$env:WORKSPACE = "D:\Projects\another-app"
.\make.ps1 up coderabbit
.\make.ps1 shell coderabbit
```

The container will mount the new project path at `/workspace`.

## Authentication and Persistence

Each tool has its own persistent Docker volume.

| Tool | Docker volume | Mounted path |
| --- | --- | --- |
| CodeRabbit | `coderabbit-config` | `/root/.coderabbit` |
| Codex | `codex-config` | `/root/.codex` |

The `down` target does not delete these volumes. Login state remains available the next time the container starts.

The `clean` target deletes the volume for the selected tool. Use it when you want to remove stored login state and tool configuration.

```powershell
.\make.ps1 clean coderabbit
```

## Safety Model

This setup avoids installing third-party AI CLIs directly on the host. CLI binaries, package dependencies, and tool configuration live in Docker images and volumes instead of your host user profile.

This is not a read-only sandbox. The mounted project directory is writable from inside the container. If the AI CLI edits, creates, or deletes files under `/workspace`, it is editing, creating, or deleting files in the real host project.

Use source control before running tools that may modify files.

Recommended preparation:

```powershell
git status
```

Review changes after running a tool:

```powershell
git status
git diff
```

## Tool-Specific Documentation

Use these references for tool-specific commands and lifecycle notes:

| Tool | Documentation |
| --- | --- |
| CodeRabbit | [`coderabbit/README.md`](./coderabbit/README.md) |
| Codex | [`codex/README.md`](./codex/README.md) |

## Troubleshooting

### `WORKSPACE not set`

Set the environment variable before running any target except `help`.

```powershell
$env:WORKSPACE = "D:\Projects\my-app"
```

### Container starts but project files are missing

Confirm that `WORKSPACE` points to the correct host directory.

```powershell
$env:WORKSPACE
Test-Path $env:WORKSPACE
```

Then restart the container:

```powershell
.\make.ps1 down coderabbit
.\make.ps1 up coderabbit
```

### Docker cannot mount the path

Use a normal absolute Windows path for `WORKSPACE`. The wrapper converts backslashes to forward slashes before calling Docker Compose.

```powershell
$env:WORKSPACE = "D:\Projects\my-app"
```

### Login state is broken or stale

Remove the selected tool environment and authenticate again.

```powershell
.\make.ps1 clean coderabbit
.\make.ps1 build coderabbit
.\make.ps1 up coderabbit
.\make.ps1 shell coderabbit
```

Inside the container:

```bash
cr auth login
```

### Rebuild after Dockerfile changes

Use `rebuild` when the Dockerfile changes or when the image needs to be recreated from scratch.

```powershell
.\make.ps1 rebuild coderabbit
```
