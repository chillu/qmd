# MCP Connector for TypingMind
# Isolated Docker service that bridges TypingMind to your MCP servers
# This keeps the TypingMind connector code isolated from your host machine

FROM node:20-alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Create app directory
WORKDIR /app

# Install the MCP connector globally
RUN npm install -g @typingmind/mcp@latest

# Create entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default MCP connector port
EXPOSE 50880

# Run the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
