# OpenAI Codex CLI in Docker

This directory defines the Docker environment for running the OpenAI Codex CLI against a host project mounted at `/workspace`.

Use the repository-level PowerShell wrapper from the repository root:

```powershell
.\make.ps1 <target> codex
```

## Files

| File | Purpose |
| --- | --- |
| `Dockerfile` | Builds a Node.js-based image and installs `@openai/codex`. |
| `docker-compose.yml` | Defines the `codex` service, project mount, and persistent config volume. |
| `README.md` | Documents the Codex-specific workflow. |

## Setup

Set `WORKSPACE` to the host project that Codex should operate on.

```powershell
$env:WORKSPACE = "D:\Projects\my-app"
```

Build the image:

```powershell
.\make.ps1 build codex
```

Start the container:

```powershell
.\make.ps1 up codex
```

Enter the container:

```powershell
.\make.ps1 shell codex
```

## First Run

Run this inside the container:

```bash
codex --help
```

Follow the authentication and setup flow required by the Codex CLI.

Authentication and configuration are stored in the Docker volume `codex-config`, mounted at `/root/.codex` inside the container.

## Usage

Run Codex inside the container from `/workspace`.

```bash
codex
```

The exact behavior is controlled by the Codex CLI. This repository only provides the containerized runtime environment.

## Lifecycle Commands

Run these from the repository root on the host.

| Action | Command |
| --- | --- |
| Build image | `.\make.ps1 build codex` |
| Start container | `.\make.ps1 up codex` |
| Enter shell | `.\make.ps1 shell codex` |
| Show status | `.\make.ps1 ps codex` |
| Stop container | `.\make.ps1 down codex` |
| Rebuild without cache | `.\make.ps1 rebuild codex` |
| Remove image and auth volume | `.\make.ps1 clean codex` |

## Persistence

The project is mounted from the host into the container:

```text
${WORKSPACE} -> /workspace
```

Codex configuration is stored separately:

```text
codex-config -> /root/.codex
```

Stopping the container with `down` keeps authentication and configuration. Running `clean` removes them.

## Notes

- Run `.\make.ps1 shell codex` before using `codex` commands.
- Changes made under `/workspace` affect the real host project.
- Check `git status` in the host project before and after allowing Codex to modify files.
