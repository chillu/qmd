# MCPVault HTTP Server
# Port 8182: Obsidian vault access

FROM oven/bun:1-debian

# Install required dependencies
RUN apt-get update && apt-get install -y \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json .
RUN bun install

# Copy server file
COPY mcpvault-http.ts .

# Set environment variables
ENV NODE_ENV=production
ENV VAULT_PATH=/vault
ENV MCPVAULT_PORT=8182

# Expose MCP server port
EXPOSE 8182

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8182/health || exit 1

# Start MCPVault HTTP server
CMD ["bun", "run", "mcpvault-http.ts"]
