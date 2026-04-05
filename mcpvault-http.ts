#!/usr/bin/env bun
import { createServer } from '@bitbonsai/mcpvault';
import { SSEServerTransport } from '@modelcontextprotocol/sdk/server/sse.js';
import { createServer as createHttpServer } from 'http';
import { resolve } from 'path';

const vaultPath = process.env.VAULT_PATH || '/vault';
const port = parseInt(process.env.MCPVAULT_PORT || '8182', 10);

const resolvedVaultPath = resolve(vaultPath);
console.log('[MCPVault] Starting server...');
console.log(`[MCPVault] Vault path: ${resolvedVaultPath}`);
console.log(`[MCPVault] Port: ${port}`);

try {
  const mcpServer = createServer(resolvedVaultPath, {
    name: 'mcpvault',
    version: '0.11.0'
  });

  // Create HTTP server
  const httpServer = createHttpServer(async (req, res) => {
    // Handle SSE connections at /sse
    if (req.url === '/sse') {
      const transport = new SSEServerTransport('/messages', res);
      await mcpServer.connect(transport);
      return;
    }

    // Handle POST messages at /messages
    if (req.url === '/messages' && req.method === 'POST') {
      // This endpoint handles incoming messages
      // The SSE transport handles the actual routing
      res.writeHead(404).end('Not Found');
      return;
    }

    // Health check endpoint
    if (req.url === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ok', server: 'mcpvault', port }));
      return;
    }

    // Default response
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      name: 'mcpvault',
      version: '0.11.0',
      endpoints: {
        sse: '/sse',
        messages: '/messages',
        health: '/health'
      }
    }));
  });

  httpServer.listen(port, () => {
    console.log(`[MCPVault] ✓ HTTP server running on port ${port}`);
    console.log(`[MCPVault] ✓ SSE endpoint: http://localhost:${port}/sse`);
    console.log(`[MCPVault] ✓ Health check: http://localhost:${port}/health`);
  });

  // Keep the process alive
  await new Promise(() => {});
} catch (error) {
  console.error('[MCPVault] ✗ Failed to start server:', error);
  process.exit(1);
}
