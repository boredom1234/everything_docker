# CodeRabbit CLI in Docker

This directory defines the Docker environment for running the CodeRabbit CLI against a host project mounted at `/workspace`.

Use the repository-level PowerShell wrapper from the repository root:

```powershell
.\make.ps1 <target> coderabbit
```

## Files

| File | Purpose |
| --- | --- |
| `Dockerfile` | Builds an Ubuntu-based image and installs the CodeRabbit CLI. |
| `docker-compose.yml` | Defines the `coderabbit` service, project mount, and persistent config volume. |
| `README.md` | Documents the CodeRabbit-specific workflow. |

## Setup

Set `WORKSPACE` to the host project that CodeRabbit should review.

```powershell
$env:WORKSPACE = "D:\Projects\my-app"
```

Build the image:

```powershell
.\make.ps1 build coderabbit
```

Start the container:

```powershell
.\make.ps1 up coderabbit
```

Enter the container:

```powershell
.\make.ps1 shell coderabbit
```

## First Login

Run this inside the container:

```bash
cr auth login
```

Authentication is stored in the Docker volume `coderabbit-config`, mounted at `/root/.coderabbit` inside the container.

## Review Commands

Run CodeRabbit commands inside the container from `/workspace`.

Common examples:

```bash
cr review
cr review --type uncommitted
cr review --type committed
cr review --type committed --base HEAD~1
```

The exact review behavior is controlled by the CodeRabbit CLI. This repository only provides the containerized runtime environment.

## Lifecycle Commands

Run these from the repository root on the host.

| Action | Command |
| --- | --- |
| Build image | `.\make.ps1 build coderabbit` |
| Start container | `.\make.ps1 up coderabbit` |
| Enter shell | `.\make.ps1 shell coderabbit` |
| Show status | `.\make.ps1 ps coderabbit` |
| Stop container | `.\make.ps1 down coderabbit` |
| Rebuild without cache | `.\make.ps1 rebuild coderabbit` |
| Remove image and auth volume | `.\make.ps1 clean coderabbit` |

## Persistence

The project is mounted from the host into the container:

```text
${WORKSPACE} -> /workspace
```

CodeRabbit configuration is stored separately:

```text
coderabbit-config -> /root/.coderabbit
```

Stopping the container with `down` keeps authentication and configuration. Running `clean` removes them.

## Notes

- Run `.\make.ps1 shell coderabbit` before using `cr` commands.
- Changes made under `/workspace` affect the real host project.
- Check `git status` in the host project before and after running reviews that may modify files.
