FROM node:lts

# System utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    curl \
    git \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Trivy - vulnerability scanner
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# GitHub CLI - for forking, PRs, repo operations
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

COPY scan.sh /usr/local/bin/scan.sh
COPY contribute.sh /usr/local/bin/contribute.sh
RUN chmod +x /usr/local/bin/scan.sh /usr/local/bin/contribute.sh

ENTRYPOINT ["bash"]
