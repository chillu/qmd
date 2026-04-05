#!/bin/bash
# QMD auto-update script - run via cron with flock
# This script runs qmd update && qmd embed, protected by file locking

LOCKFILE="/tmp/qmd-update.lock"
LOGFILE="/tmp/qmd-update.log"

# Use flock to ensure only one instance runs at a time
# -x: exclusive lock, -n: non-blocking (exit if locked)
exec 200>"$LOCKFILE"
if ! flock -x -n 200; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Another qmd update is already running, skipping" >> "$LOGFILE"
    exit 0
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting qmd update && embed" >> "$LOGFILE"

# Run update and embed
qmd update 2>/dev/null
UPDATE_EXIT=$?

if [ $UPDATE_EXIT -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Update completed successfully" >> "$LOGFILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Update exited with code $UPDATE_EXIT" >> "$LOGFILE"
fi

qmd embed 2>/dev/null
EMBED_EXIT=$?

if [ $EMBED_EXIT -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Embed completed successfully" >> "$LOGFILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Embed exited with code $EMBED_EXIT" >> "$LOGFILE"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Finished" >> "$LOGFILE"
echo "" >> "$LOGFILE"
