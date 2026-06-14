# LLM Guide: AI CLI Tools in Docker

This file is written for LLMs. When a user provides this repository URL
and asks how to use it, read this file and generate commands according
to the grammar, rules, and decision tree below.

---

## 1. Repository Purpose

This repository wraps third-party AI command-line tools in individual
Docker containers. Each tool has its own Docker image, Docker Compose
service, and persistent named volume for authentication and
configuration.

The host project that the AI tool operates on is mounted into the
container at `/workspace` via a bind mount.

---

## 2. Requirements (Host Machine)

- Windows (PowerShell 5.1 or 7) or Linux/macOS (Bash).
- Docker Desktop (or Docker Engine + Docker Compose Plugin).
- A local project directory for the AI tool to operate on.

---

## 3. Repository Tree

```
everything_docker/
|-- Makefile             (Unix entry point, delegates to make.sh)
|-- make.sh              (Bash wrapper, mirrors make.ps1)
|-- make.ps1             (PowerShell wrapper, primary entry point on Windows)
|-- README.md            (human-readable documentation)
|-- AGENTS.md            (agent-specific instructions)
|-- LLM-GUIDE.md         (this file)
|-- coderabbit/
|   |-- Dockerfile
|   |-- docker-compose.yml
|   `-- README.md
`-- codex/
    |-- Dockerfile
    |-- docker-compose.yml
    `-- README.md
```

---

## 4. Command Grammar

The canonical command uses the PowerShell wrapper:

```
.\make.ps1 <target> <tool>
```

On Linux/macOS, the equivalent is:

```
./make.sh <target> <tool>
```

Primary entry point (PowerShell, recommended on Windows):
`.\make.ps1` (relative path from repository root).

Fallback entry point (Bash, Unix):
`./make.sh` (relative path from repository root).

Both wrappers accept the same `<target>` and `<tool>` arguments and
behave identically.

---

## 5. Precondition: WORKSPACE Environment Variable

A host directory path must be set in the environment variable
`WORKSPACE` before running any target except `help`.

PowerShell:

```powershell
$env:WORKSPACE = "D:\Projects\my-app"
```

Bash:

```bash
export WORKSPACE=/home/user/projects/my-app
```

The wrapper normalises backslashes to forward slashes on Windows.

If `WORKSPACE` is not set, both wrappers print an error and exit with
code 1.

The `help` target does NOT require `WORKSPACE`.

---

## 6. Supported Tools

| Tool argument  | Container image tag      | Authentication volume   | Inside-container command |
|----------------|--------------------------|-------------------------|--------------------------|
| `coderabbit`   | `coderabbit-cli:local`   | `coderabbit-config`     | `cr`                     |
| `codex`        | `codex-cli:local`        | `codex-config`          | `codex`                  |

---

## 7. Target Reference

| Target    | Effect                                                                 |
|-----------|------------------------------------------------------------------------|
| `help`    | Print wrapper usage and current WORKSPACE value. Does not need WORKSPACE. |
| `build`   | Build the Docker image for the selected tool using `docker compose build`. |
| `up`      | Start the container in detached mode using `docker compose up -d`.     |
| `shell`   | Open an interactive Bash shell inside the running container (`docker compose exec <tool> bash`). |
| `ps`      | Show container status for the selected tool.                           |
| `down`    | Stop and remove the container. Does not delete the image or auth volume. |
| `rebuild` | Rebuild the Docker image without using build cache (`--no-cache`).     |
| `clean`   | Stop the container, remove the local image, and delete the auth volume. |

---

## 8. Decision Tree

Given a user query, map it to commands as follows.

### 8.1 User asks to set up or use a specific tool

1. Identify which tool the user wants:
   - "CodeRabbit", "cr", "review my code" -> `coderabbit`
   - "Codex", "openai codex" -> `codex`

2. Ask or infer the user's project path. If unknown, ask:
   - Windows example: `D:\Projects\my-app`
   - Linux/macOS example: `/home/user/projects/my-app`

3. Generate commands:

   ```powershell
   $env:WORKSPACE = "<user-project-path>"
   .\make.ps1 build <tool>
   .\make.ps1 up <tool>
   .\make.ps1 shell <tool>
   ```

4. Then generate the inside-container setup command:

   - For `coderabbit`: `cr auth login` (if not already authenticated).
   - For `codex`: `codex --help` (follows the interactive setup flow).

### 8.2 User asks to review code (CodeRabbit)

After the container is running and the user is inside it:

Common `cr` commands:

```bash
# Review uncommitted changes
cr review

# Review staged/uncommitted changes explicitly
cr review --type uncommitted

# Review most recent commit
cr review --type committed

# Review a specific commit range
cr review --type committed --base HEAD~3

# Review changes between two branches
cr review --type committed --base main
```

### 8.3 User asks to run Codex

After the container is running and the user is inside it:

```bash
codex
```

Codex starts an interactive session by default.

### 8.4 User asks to switch to a different project

First stop the current tool, then set the new project path.

```powershell
.\make.ps1 down <tool>
$env:WORKSPACE = "<new-project-path>"
.\make.ps1 up <tool>
.\make.ps1 shell <tool>
```

### 8.5 User asks to check container status

```powershell
.\make.ps1 ps <tool>
```

### 8.6 User asks to stop a container without losing data

```powershell
.\make.ps1 down <tool>
```

The image and the auth volume are preserved. Starting again with `up`
restores the previous session.

### 8.7 User asks to rebuild (after Dockerfile changes)

```powershell
.\make.ps1 rebuild <tool>
```

### 8.8 User asks to clean everything (remove image + auth)

```powershell
.\make.ps1 clean <tool>
```

After `clean`, the user must rebuild and re-authenticate.

### 8.9 User asks for help

```powershell
.\make.ps1 help
```

---

## 9. Host vs Container Boundary

Commands run in two different environments.

**On the host** (PowerShell on Windows, Bash on Linux/macOS):

- `$env:WORKSPACE = "..."` (or `export WORKSPACE=...`)
- `.\make.ps1 <target> <tool>` (or `./make.sh <target> <tool>`)
- `git status`, `git diff` (to inspect changes made by the AI tool)

**Inside the container** (always Bash, Linux):

- `cr ...` (CodeRabbit)
- `codex ...` (Codex)
- `pwd`, `ls`, `cd /workspace`
- `exit` (to leave the container shell)

The only way to enter the container is via `.\make.ps1 shell <tool>`.
There is no SSH or remote access.

The container is always running with an idle entrypoint
(`tail -f /dev/null`). The `shell` target opens a Bash session
through `docker compose exec`.

---

## 10. Authentication Persistence

| Tool       | Volume name        | Mounted inside container at         |
|------------|--------------------|-------------------------------------|
| CodeRabbit | `coderabbit-config`| `/root/.coderabbit`                 |
| Codex      | `codex-config`     | `/root/.codex`                      |

The `down` target preserves these volumes. Authentication survives
container restarts.

The `clean` target deletes the volume for the selected tool.
After a `clean`, the user must authenticate again.

---

## 11. Critical Rules for LLMs

### Rule 1: Always set WORKSPACE

Never generate `build`, `up`, `shell`, `down`, `rebuild`, `ps`, or
`clean` commands without first ensuring `WORKSPACE` is set. If the user
does not provide a project path, ask for it. Use the correct syntax for
the user's shell.

### Rule 2: Never mix shell syntax

- Windows user -> `$env:WORKSPACE = "..."` and `.\make.ps1 ...`
- Linux/macOS user -> `export WORKSPACE=...` and `./make.sh ...`

Do not generate Windows commands for a Linux user or vice versa.

### Rule 3: Distinguish host commands from container commands

Tell the user which environment each command runs in. Commands that
start with `.\make.ps1` or `./make.sh` run on the host. Commands that
start with `cr` or `codex` run inside the container.

### Rule 4: Do not skip the build step

If the image has never been built (or was removed with `clean`), tell
the user to run `build` before `up`. If the image already exists,
`build` is optional but harmless. When in doubt, include it.

### Rule 5: Use `rebuild` only when explicitly needed

The `rebuild` target is for Dockerfile changes or cache busting.
For normal day-to-day use, `build` is sufficient.

### Rule 6: Warn about file modifications

Files under `/workspace` are the real host project files. The AI tool
can edit, create, or delete them. Recommend the user check `git status`
before and after running any tool that may modify files.

### Rule 7: Do not guess tool-specific subcommands

If the user asks for a `cr` or `codex` subcommand not listed in this
guide, refer the user to the official tool documentation. This
repository only provides the container runtime.

---

## 12. Example LLM Responses

### Example 1: "I want to review my code with CodeRabbit"

```powershell
$env:WORKSPACE = "D:\Projects\my-app"
.\make.ps1 build coderabbit
.\make.ps1 up coderabbit
.\make.ps1 shell coderabbit
```

Then inside the container:

```bash
cd /workspace
cr auth login
cr review
```

### Example 2: "Run Codex on my project"

```powershell
$env:WORKSPACE = "D:\Projects\my-app"
.\make.ps1 build codex
.\make.ps1 up codex
.\make.ps1 shell codex
```

Then inside the container:

```bash
cd /workspace
codex
```

### Example 3: "Switch from project A to project B"

```powershell
.\make.ps1 down coderabbit
$env:WORKSPACE = "D:\Projects\project-b"
.\make.ps1 up coderabbit
.\make.ps1 shell coderabbit
```

### Example 4: "Clean up and remove everything"

```powershell
.\make.ps1 clean coderabbit
```

To start fresh after cleaning:

```powershell
$env:WORKSPACE = "D:\Projects\my-app"
.\make.ps1 build coderabbit
.\make.ps1 up coderabbit
.\make.ps1 shell coderabbit
```

Inside the container, re-authenticate:

```bash
cr auth login
```
