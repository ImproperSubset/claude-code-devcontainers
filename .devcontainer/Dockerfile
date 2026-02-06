FROM node:22-bookworm

ARG TZ
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ="$TZ"

ARG CLAUDE_CODE_VERSION=latest

# Install development tools, compilers, and utilities
# Groups: Core utils, Network tools, Build tools, Editors, AI CLI deps, Security
# BuildKit cache mounts for faster rebuilds (5-10x speedup)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  apt-get update && apt-get install -y --no-install-recommends \
  # Core utilities
  less \
  curl \
  wget \
  ca-certificates \
  gnupg2 \
  software-properties-common \
  apt-transport-https \
  lsb-release \
  # Version control
  git \
  git-lfs \
  gh \
  # Shell and terminal tools
  zsh \
  fzf \
  man-db \
  # Process and system tools
  procps \
  htop \
  btop \
  tree \
  sudo \
  # Network tools
  dnsutils \
  net-tools \
  iputils-ping \
  telnet \
  netcat-openbsd \
  iptables \
  ipset \
  iproute2 \
  aggregate \
  # Archive and compression
  unzip \
  zip \
  bzip2 \
  xz-utils \
  # Text processing and data
  jq \
  yq \
  sed \
  gawk \
  # Fast search tools (modern replacements)
  ripgrep \
  fd-find \
  bat \
  duf \
  # Build essentials (for native npm modules)
  build-essential \
  gcc \
  g++ \
  make \
  cmake \
  pkg-config \
  # Python (for node-gyp and AI CLIs)
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  # Text editors
  nano \
  vim \
  tmux \
  # OpenSSL and crypto
  openssl \
  libssl-dev \
  # Additional development libraries
  libz-dev \
  libffi-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libncurses5-dev \
  libncursesw5-dev \
  liblzma-dev \
  # Locales for proper encoding
  locales \
  # Browser automation (Chromium for Chrome DevTools MCP)
  chromium \
  # Chromium dependencies
  fonts-liberation \
  libatk-bridge2.0-0 \
  libatk1.0-0 \
  libatspi2.0-0 \
  libcups2 \
  libdbus-1-3 \
  libdrm2 \
  libgbm1 \
  libgtk-3-0 \
  libnspr4 \
  libnss3 \
  libxcomposite1 \
  libxdamage1 \
  libxfixes3 \
  libxkbcommon0 \
  libxrandr2 \
  xdg-utils \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create python symlink for convenience (PEP 394 compliant)
# This allows 'python' command to work in addition to 'python3'
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Set up locale (prevents encoding issues with Claude/Codex/Gemini)
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
  locale-gen
ENV LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

# Ensure default node user has access to /usr/local/share
RUN chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash history and configure PATH for npm global packages
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory \
  && echo 'export PATH=$PATH:/home/node/.npm-global/bin:/home/node/.local/bin' >> /home/node/.bashrc \
  && chown node:node /home/node/.bashrc

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create config directories and set permissions
# Note: Workspace directory is created and mounted by VS Code automatically
RUN mkdir -p /home/node/.config/gh /home/node/.claude /home/node/.codex /home/node/.gemini /home/node/.npm-global/lib /home/node/.aws /home/node/.wrangler /home/node/.vercel /home/node/.local/bin && \
  chown -R node:node /home/node/.config /home/node/.claude /home/node/.codex /home/node/.gemini /home/node/.npm-global /home/node/.aws /home/node/.wrangler /home/node/.vercel /home/node/.local

# Default working directory (VS Code will override this with actual workspace mount)
WORKDIR /workspaces

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Pinned versions for modern CLI tools (update manually)
ARG EZA_VERSION=0.23.4
ARG DUST_VERSION=1.2.4
ARG PROCS_VERSION=0.14.10

# Install modern CLI tools from GitHub releases (pinned versions)
RUN RUST_ARCH=$([ "$(dpkg --print-architecture)" = "amd64" ] && echo "x86_64" || echo "aarch64") && \
  # eza (modern ls)
  wget "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${RUST_ARCH}-unknown-linux-gnu.tar.gz" && \
  tar xzf eza_*-unknown-linux-gnu.tar.gz -C /usr/local/bin/ && \
  rm eza_*-unknown-linux-gnu.tar.gz && \
  # dust (modern du)
  wget "https://github.com/bootandy/dust/releases/download/v${DUST_VERSION}/dust-v${DUST_VERSION}-${RUST_ARCH}-unknown-linux-musl.tar.gz" && \
  tar xzf dust-*.tar.gz --strip-components=1 -C /usr/local/bin/ dust-v${DUST_VERSION}-${RUST_ARCH}-unknown-linux-musl/dust && \
  rm dust-*.tar.gz && \
  # procs (modern ps)
  wget "https://github.com/dalance/procs/releases/download/v${PROCS_VERSION}/procs-v${PROCS_VERSION}-${RUST_ARCH}-linux.zip" && \
  unzip procs-*.zip -d /usr/local/bin/ && \
  rm procs-*.zip

# Install AWS CLI v2 to system path (not ~/.local which is volume-mounted)
RUN cd /tmp && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin && \
    rm -rf awscliv2.zip aws

# Pinned versions for system tools (update manually)
ARG ZOXIDE_VERSION=0.9.9
ARG UV_VERSION=0.10.0
ARG BUN_VERSION=1.3.8

# Install zoxide (smart cd) to system path — direct binary, no curl|sh
RUN RUST_ARCH=$([ "$(dpkg --print-architecture)" = "amd64" ] && echo "x86_64" || echo "aarch64") && \
    wget "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-${RUST_ARCH}-unknown-linux-musl.tar.gz" && \
    tar xzf zoxide-*.tar.gz -C /usr/local/bin/ zoxide && \
    rm zoxide-*.tar.gz

# Install uv (fast Python package manager) to system path — pinned version
RUN curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" | env XDG_BIN_HOME=/usr/local/bin sh

# Install bun (fast JavaScript runtime) to system path — direct binary, no curl|sh
RUN ARCH=$([ "$(dpkg --print-architecture)" = "amd64" ] && echo "x64" || echo "aarch64") && \
    curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-${ARCH}.zip" -o /tmp/bun.zip && \
    unzip /tmp/bun.zip -d /tmp/bun && \
    mv /tmp/bun/bun-linux-${ARCH}/bun /usr/local/bin/bun && \
    chmod +x /usr/local/bin/bun && \
    rm -rf /tmp/bun /tmp/bun.zip

# Set up non-root user
USER node

# Install global packages
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=$PATH:/home/node/.npm-global/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Set the default editor and visual
ENV EDITOR=nano
ENV VISUAL=nano

# Powerlevel10k theme and oh-my-zsh with plugins
ARG ZSH_IN_DOCKER_VERSION=1.2.1
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -p sudo \
  -p zsh-autosuggestions \
  -p zsh-syntax-highlighting \
  -a "DISABLE_AUTO_UPDATE=true" \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -a "export PATH=\$PATH:/home/node/.npm-global/bin:/home/node/.local/bin" \
  -x

# Powerlevel10k config — matches host theme for consistency
COPY --chown=node:node p10k.zsh /home/node/.p10k.zsh

# Shell customizations — must be AFTER oh-my-zsh source to avoid being overwritten
RUN cat >> /home/node/.zshrc <<'ZSHEOF'

# ---- p10k theme ----
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ---- eza (better ls) ----
alias ls='eza --icons --group-directories-first'
alias ll='eza -alh --icons --group-directories-first --git'
alias la='eza -a --icons --group-directories-first'
alias lt='eza --tree --icons --level=2'

# ---- bat (better cat) ----
alias cat='batcat --paging=never'
alias catt='batcat'
alias bat='batcat'
export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
alias -g -- -h='-h 2>&1 | batcat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | batcat --language=help --style=plain'

# ---- ripgrep (better grep) ----
alias fd=fdfind
alias rg='rg --smart-case'
alias grep='rg'

# ---- zoxide (better cd) ----
eval "$(zoxide init zsh)"
alias cd='z'

# ---- modern replacements ----
alias du='dust'
alias df='duf'
alias ps='procs'
alias top='btop'

# ---- directory nav ----
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ---- safety nets ----
alias cp='cp -v'
alias mv='mv -v'
alias rm='rm -I'

# ---- fzf integration ----
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else batcat -n --color=always --line-range :500 {}; fi"
export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
_fzf_comprun() {
  local command=$1
  shift
  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'" "$@" ;;
    ssh)          fzf --preview 'dig {}' "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

alias reload='source ~/.zshrc'
ZSHEOF

# npm CLI packages (Claude Code, Codex, Gemini, Wrangler, Vercel) installed via postCreateCommand
# This ensures packages install AFTER npm-global volume mounts, preventing version conflicts
# See devcontainer.json postCreateCommand for installation details

# System tools (aws, zoxide, uv, bun) installed as root to /usr/local/bin above
# to avoid volume shadowing — ~/.local and ~/.bun are mounted as shared volumes

# Add .local/bin to PATH for user-installed tools
ENV PATH="/home/node/.local/bin:$PATH"

# Python 3.14 installation moved to init-python.sh (runs via postCreateCommand)
# This ensures installation happens AFTER volume mounts, so it persists correctly
# System Python 3.11 remains available for node-gyp compatibility

# bun global packages stored in ~/.bun (volume-mounted), binary at /usr/local/bin
ENV BUN_INSTALL="/home/node/.bun"
ENV PATH="$BUN_INSTALL/bin:$PATH"

# Configure git to ignore Claude's local settings (Anthropic best practice)
# This prevents accidentally committing sensitive configuration like API keys
RUN git config --global core.excludesfile ~/.gitignore_global && \
  echo ".claude/settings.local.json" > /home/node/.gitignore_global && \
  chown node:node /home/node/.gitignore_global

# Switch to root for final setup (scripts, sudoers, templates)
USER root

# Create directory for Claude Code and Codex defaults
RUN mkdir -p /usr/local/share/claude-defaults /usr/local/share/claude-defaults/hooks /usr/local/share/codex-defaults

# Copy all scripts and templates in one layer (changes most frequently)
COPY init-firewall.sh /usr/local/bin/
COPY init-claude-config.sh /usr/local/bin/
COPY init-claude-hooks.sh /usr/local/bin/
COPY init-codex-config.sh /usr/local/bin/
COPY init-opencode-config.sh /usr/local/bin/
COPY init-python.sh /usr/local/bin/
COPY --chown=node:node settings.json.template /usr/local/share/claude-defaults/settings.json
COPY --chown=node:node mcp.json.template /usr/local/share/claude-defaults/mcp.json
COPY --chmod=755 session-start.sh.template /usr/local/share/claude-defaults/hooks/session-start.sh
COPY --chown=node:node config.toml.template /usr/local/share/codex-defaults/config.toml

# Set permissions and configure sudoers for all init scripts
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  chmod +x /usr/local/bin/init-claude-config.sh && \
  chmod +x /usr/local/bin/init-claude-hooks.sh && \
  chmod +x /usr/local/bin/init-codex-config.sh && \
  chmod +x /usr/local/bin/init-opencode-config.sh && \
  chmod +x /usr/local/bin/init-python.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-claude-config.sh" > /etc/sudoers.d/node-claude-config && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-claude-hooks.sh" > /etc/sudoers.d/node-claude-hooks && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-codex-config.sh" > /etc/sudoers.d/node-codex-config && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-opencode-config.sh" > /etc/sudoers.d/node-opencode-config && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-python.sh" > /etc/sudoers.d/node-python && \
  chmod 0440 /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-claude-config && \
  chmod 0440 /etc/sudoers.d/node-claude-hooks && \
  chmod 0440 /etc/sudoers.d/node-codex-config && \
  chmod 0440 /etc/sudoers.d/node-opencode-config && \
  chmod 0440 /etc/sudoers.d/node-python

# Switch back to node user for runtime
USER node
