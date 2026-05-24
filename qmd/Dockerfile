# QMD MCP Server
# Port 8181: Obsidian vault with OpenAI embeddings
#
# OPTIMIZED BUILD with BuildKit cache mounts:
# - apt-get packages cached across builds
# - bun install cached (downloads + compiled native modules)
# - Source changes only trigger rebuild, not re-install
#
# Enable BuildKit: export DOCKER_BUILDKIT=1
# Or in docker-compose.yml: build.dockerfile.buildkit: true

# =============================================================================
# Stage 1: Dependencies (cached until package.json changes)
# =============================================================================
FROM oven/bun:1-debian AS deps

# Install nodejs and node-gyp for compiling native modules like better-sqlite3
RUN apt-get update && apt-get install -y \
    curl \
    python3 \
    make \
    g++ \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /deps

# Copy package files first for layer caching
COPY package.json bun.lock* ./

# Install dependencies with BuildKit cache mount
# This persists bun's cache across builds (downloaded packages + compiled artifacts)
RUN --mount=type=cache,target=/root/.bun/install/cache \
    bun install

# =============================================================================
# Stage 2: Application
# =============================================================================
FROM oven/bun:1-debian AS app

# Install system dependencies with apt cache mount
# Packages are cached, only re-fetched if apt cache expired
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y \
    git \
    curl \
    python3 \
    make \
    g++ \
    sqlite3 \
    libsqlite3-dev \
    netcat-openbsd \
    cron \
    util-linux \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy installed node_modules from deps stage
COPY --from=deps /deps/node_modules ./node_modules

# Copy source code from build context
# Docker detects changes here - only rebuilds when source actually changes
COPY . .

# Patch: Fix MCP server to bind to 0.0.0.0 instead of localhost for Docker
RUN sed -i 's/"localhost"/"0.0.0.0"/g' /app/src/mcp/server.ts

# Build the project (TypeScript compilation only - fast!)
RUN bun run build

# =============================================================================
# Stage 3: Runtime configuration
# =============================================================================

# Create cache directory
RUN mkdir -p /root/.cache/qmd

# Copy scripts
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY auto-update.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/auto-update.sh

# Create log file for cron
RUN touch /tmp/qmd-update.log

# Add crontab for auto-update every minute
RUN echo "* * * * * /usr/local/bin/auto-update.sh" > /etc/cron.d/qmd-update && \
    chmod 0644 /etc/cron.d/qmd-update && \
    crontab /etc/cron.d/qmd-update

# Set environment variables
ENV NODE_ENV=production
ENV QMD_LLM_PROVIDER=openai-compatible
ENV QMD_OPENAI_BASE_URL=https://api.openai.com/v1
ENV QMD_EMBED_MODEL=text-embedding-3-small
ENV QMD_GENERATE_MODEL=gpt-4o-mini
ENV PATH="/app/bin:$PATH"

# Expose MCP server port
EXPOSE 8181

# Use entrypoint to initialize collections before starting MCP server
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
