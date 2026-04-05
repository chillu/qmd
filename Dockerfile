# Dual MCP Server Container
# - QMD (port 8181): Obsidian vault with OpenAI embeddings
# - MCPVault (port 8182): Obsidian vault access

FROM oven/bun:1-debian

# Install required dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    python3 \
    make \
    g++ \
    sqlite3 \
    libsqlite3-dev \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone the chillu/qmd fork with OpenAI embeddings support
RUN git clone --branch feat/openai-embeddings-clean --depth 1 https://github.com/chillu/qmd.git .

# Install dependencies using Bun
RUN bun install

# Build the project
RUN bun run build

# Create a directory for mcpvault HTTP server and vault
RUN mkdir -p /app/mcpvault /vault /root/.cache/qmd

# Copy mcpvault HTTP server files
COPY mcpvault-http.ts /app/mcpvault/
COPY mcpvault-package.json /app/mcpvault/package.json

# Install mcpvault and its dependencies locally
WORKDIR /app/mcpvault
RUN bun install

# Return to main app directory
WORKDIR /app

# Set environment variables
ENV NODE_ENV=production
ENV QMD_OPENAI=1
ENV OPENAI_BASE_URL=https://api.openai.com/v1

# Expose MCP server ports
EXPOSE 8181 8182

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Default to interactive shell
CMD ["bash"]
