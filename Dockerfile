# Use Python 3.11 as base image

FROM python:3.11-slim

# Install system dependencies including Chrome, shells, and editors

RUN apt-get update && \

    apt-get install -y \

    curl \

    gnupg \

    wget \

    bash \

    zsh \

    nano \

    git \

    fonts-powerline \  # Needed for ZSH themes

    && mkdir -p /etc/apt/keyrings \

    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \

    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \

    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg \

    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list \

    && apt-get update \

    && apt-get install -y \

    nodejs \

    google-chrome-stable \

    && apt-get clean \

    && rm -rf /var/lib/apt/lists/*

# Install oh-my-zsh with the "mikeh" theme

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \

    git clone https://github.com/MikeTheShadow/zsh-mikeh.git ~/.oh-my-zsh/custom/themes/mikeh

# Create .zshrc with mikeh theme

RUN echo '\n\

# Load oh-my-zsh\n\

export ZSH="$HOME/.oh-my-zsh"\n\

\n\

# Set mikeh theme\n\

ZSH_THEME="mikeh"\n\

\n\

# Add plugins if needed\n\

plugins=(git)\n\

\n\

# Source oh-my-zsh\n\

source $ZSH/oh-my-zsh.sh\n\

\n\

# Aliases\n\

alias ll="ls -la"\n\

' > /root/.zshrc

# Install uv and create virtual environment

RUN pip install uv && uv venv

# Install mcpo-control-panel and Playwright dependencies

RUN uv pip install mcpo-control-panel && \

    npx playwright install chrome && \

    npx playwright install-deps

# Set working directory

WORKDIR /app

# Expose ports

EXPOSE 8083 8000

# Set environment variables with defaults

ENV MCPO_MANAGER_HOST=0.0.0.0

ENV MCPO_MANAGER_PORT=8083

ENV MCPO_MANAGER_DATA_DIR=/data

ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

ENV SHELL=/usr/bin/zsh

# Create data directory and set permissions

RUN mkdir -p /data && \

    mkdir -p /ms-playwright && \

    chmod -R 777 /data && \

    chmod -R 777 /ms-playwright

# Add a non-root user with zsh config

RUN useradd -m -s /usr/bin/zsh appuser && \

    chown -R appuser:appuser /app /data /ms-playwright && \

    cp /root/.zshrc /home/appuser/ && \

    chown appuser:appuser /home/appuser/.zshrc

USER appuser

# Set ZSH as default shell for RUN commands

SHELL ["/usr/bin/zsh", "-c"]

# Command to run the application

CMD ["sh", "-c", "uv run python -m mcpo_control_panel --host ${MCPO_MANAGER_HOST} --port ${MCPO_MANAGER_PORT} --config-dir ${MCPO_MANAGER_DATA_DIR}"]
