# Use Python 3.11 as base image
FROM python:3.11-slim

# Install Node.js 22.x
RUN apt-get update && apt-get install -y curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# Install Puppeteer dependencies and Chromium
RUN apt-get update && apt-get install -y \
    nodejs \
    chromium \
    glib2.0-dev \
    libglib2.0-0 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    libatspi2.0-0 \
    fonts-liberation \
    libappindicator3-1 \
    fonts-noto-color-emoji \
    xdg-utils \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Puppeteer environment variables with the working configuration
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PUPPETEER_LAUNCH_OPTIONS={"headless":"new","args":["--no-sandbox","--disable-setuid-sandbox","--disable-dev-shm-usage","--disable-gpu","--no-zygote"]}

# Install uv
RUN pip install uv
RUN uv venv

# Install mcpo-control-panel using uv
RUN uv pip install mcpo-control-panel==0.1.5

# Set working directory
WORKDIR /app

# Expose the port (default is 8083, can be overridden by MCPO_MANAGER_PORT)
EXPOSE 8083
EXPOSE 8000

# Set environment variables with defaults
ENV MCPO_MANAGER_HOST=0.0.0.0 \
    MCPO_MANAGER_PORT=8083 \
    MCPO_MANAGER_DATA_DIR=/data

# Create data directory
RUN mkdir -p /data

# Command to run the application
CMD ["uv", "run", "python", "-m", "mcpo_control_panel", "--host", "0.0.0.0", "--port", "8083", "--config-dir", "/data"]
