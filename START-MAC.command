#!/bin/bash
# macOS: double-click this file in Finder to start Portable Qwen.
# If double-click doesn't work, open Terminal, type "bash " (with a space),
# drag this file into the Terminal window and press Enter.
#   Add "chat" at the end to chat inside Terminal, "cpu" to disable the GPU.
cd "$(dirname "$0")" || exit 1
bash "./engine/launch.sh" "$@"
echo
read -r -p "Press Enter to close this window..." _
