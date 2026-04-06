#!/bin/bash
set -e

export QMD_OPENAI=1
export OPENAI_BASE_URL=${OPENAI_BASE_URL:-https://api.openai.com/v1}
export PATH="/app/bin:$PATH"

echo "[QMD] Initializing vault collections..."

# Wait a moment for any filesystem mounts to settle
sleep 1

# Function to parse config.json and add collections
add_collections_from_config() {
    local config_path="${QMD_CONFIG_PATH:-/config.json}"
    
    if [ ! -f "$config_path" ]; then
        echo "[QMD] Warning: No config.json found at $config_path"
        echo "[QMD] Create config.json to auto-initialize collections."
        echo "[QMD] Copy config.example.json to your vault's parent directory and customize it."
        return 0
    fi
    
    echo "[QMD] Loading collections from $config_path..."
    
    # Use Python to parse JSON (already available in the image)
    python3 << PYTHON_SCRIPT
import json
import sys
import subprocess
import os

config_path = "$config_path"

try:
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    collections = config.get('collections', {})
    
    if not collections:
        print('[QMD] No collections defined in config.json')
        sys.exit(0)
    
    for name, info in collections.items():
        path = info.get('path', '')
        description = info.get('description', '')
        
        if not path:
            print(f'[QMD] Skipping collection {name}: no path specified')
            continue
            
        full_path = f'/vault/{path}'
        
        # Check if directory exists
        if not os.path.isdir(full_path):
            print(f'[QMD] Skipping collection {name}: {full_path} does not exist')
            continue
        
        print(f'[QMD] Adding collection: {name} -> {full_path}')
        
        # Add collection
        result = subprocess.run(
            ['qmd', 'collection', 'add', full_path, '--name', name],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            if 'already exists' in result.stderr.lower():
                print(f'[QMD] Collection {name} already exists')
            else:
                print(f'[QMD] Warning: Failed to add collection {name}: {result.stderr.strip()}')
        else:
            print(f'[QMD] Collection {name} added successfully')
        
        # Add context description if provided
        if description:
            print(f'[QMD] Adding context for {name}: {description}')
            ctx_result = subprocess.run(
                ['qmd', 'context', 'add', f'qmd://{name}', description],
                capture_output=True,
                text=True
            )
            if ctx_result.returncode != 0:
                print(f'[QMD] Warning: Failed to add context for {name}: {ctx_result.stderr.strip()}')
    
except json.JSONDecodeError as e:
    print(f'[QMD] Error: Invalid JSON in {config_path}: {e}')
    sys.exit(1)
except FileNotFoundError:
    print(f'[QMD] Config file not found: {config_path}')
    sys.exit(1)
except Exception as e:
    print(f'[QMD] Error processing config: {e}')
    sys.exit(1)
PYTHON_SCRIPT
}

# Add collections from config
add_collections_from_config

# Run embed to index the collections
echo "[QMD] Running embed to index collections..."
qmd embed 2>/dev/null || echo "[QMD] Embed completed or nothing new to index"

# Start cron daemon for auto-update
echo "[QMD] Starting cron daemon for auto-update..."
service cron start

echo "[QMD] Starting MCP server on port 8181..."
exec qmd mcp --http --port 8181 "$@"
