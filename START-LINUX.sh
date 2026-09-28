#!/bin/bash
# Linux: start Portable Qwen. In a terminal run:
#     bash /path/to/USB/START-LINUX.sh          (web chat in your browser)
#     bash /path/to/USB/START-LINUX.sh chat     (chat inside the terminal)
#     bash /path/to/USB/START-LINUX.sh cpu      (don't use the GPU)
cd "$(dirname "$0")" || exit 1
exec bash "./engine/launch.sh" "$@"
