FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl unzip ca-certificates git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN set -ux; \
    curl -fsSL https://cli.coderabbit.ai/install.sh -o /tmp/cr-install.sh; \
    chmod +x /tmp/cr-install.sh; \
    # The installer exits non-zero when it cannot persist PATH to ~/.profile
    # (common in `docker build` where the build shell is non-interactive).
    # The binary is already installed and verified by the installer itself,
    # and we set ENV PATH below, so ignore that specific failure mode.
    /tmp/cr-install.sh; \
    rc=$?; \
    if [ "$rc" -ne 0 ] && [ ! -x /root/.local/bin/coderabbit ]; then \
        echo "CodeRabbit installer failed and binary is missing" >&2; \
        exit "$rc"; \
    fi; \
    rm -f /tmp/cr-install.sh

ENV PATH="/root/.local/bin:$PATH"

WORKDIR /workspace
ENTRYPOINT ["cr"]
