# QMD MCP Server
# Port 8181: Obsidian vault with OpenAI embeddings

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

# Create cache directory
RUN mkdir -p /root/.cache/qmd

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set environment variables
ENV NODE_ENV=production
ENV QMD_OPENAI=1
ENV OPENAI_BASE_URL=https://api.openai.com/v1
ENV PATH="/app/bin:$PATH"

# Expose MCP server port
EXPOSE 8181

# Use entrypoint to initialize collections before starting MCP server
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
