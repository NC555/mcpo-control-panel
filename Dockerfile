# Use Python 3.11 as base image
FROM python:3.11-slim

# Install system dependencies including Chrome for Playwright
RUN apt-get update && \
    apt-get install -y \
    curl \
    gnupg \
    wget \
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

# Create data directory
RUN mkdir -p /data && \
    mkdir -p /ms-playwright && \
    chmod -R 777 /data && \
    chmod -R 777 /ms-playwright

# Add a non-root user and switch to it
RUN useradd -m appuser && \
    chown -R appuser:appuser /app /data /ms-playwright
USER appuser

# Command to run the application
CMD ["sh", "-c", "uv run python -m mcpo_control_panel --host ${MCPO_MANAGER_HOST} --port ${MCPO_MANAGER_PORT} --config-dir ${MCPO_MANAGER_DATA_DIR}"]
