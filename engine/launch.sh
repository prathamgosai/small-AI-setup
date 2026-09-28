#!/bin/bash
# Portable Qwen launcher for macOS and Linux.
# Called by START-MAC.command and START-LINUX.sh - you normally don't run this directly.
#
# Usage:  launch.sh [chat] [cpu]
#   (no args)  start the web chat in your browser
#   chat       chat inside this terminal instead of the browser
#   cpu        don't use the graphics card (use if the GPU mode crashes)
#   fast       turn off "thinking" - quicker answers, a bit less smart
#
# Optional environment variables:
#   QWEN_CTX=16384    context length (default 16384; bigger = more RAM)
#   QWEN_PORT=8080    first port to try for the web chat

set -u

ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$ENGINE_DIR")"
MODELS="$ROOT/models"
VERSION="$(cat "$ENGINE_DIR/VERSION.txt" 2>/dev/null | tr -d '\r\n ')"
[ -n "$VERSION" ] || VERSION="unknown"

MODE="web"
FORCE_CPU=0
NO_THINK=0
for a in "$@"; do
  case "$a" in
    chat|cli|terminal) MODE="chat" ;;
    cpu) FORCE_CPU=1 ;;
    fast|nothink) NO_THINK=1 ;;
  esac
done

CTX="${QWEN_CTX:-16384}"
PORT="${QWEN_PORT:-8080}"

die() { echo; echo "ERROR: $*"; echo; exit 1; }

# ---------- pick the model ----------
MODEL=""
for f in "$MODELS"/*.gguf; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in mmproj*) continue ;; esac
  MODEL="$f"; break
done
[ -n "$MODEL" ] || die "No model (.gguf) found in $MODELS"

# Optional system prompt (the AI's role/instructions). Delete or rename the file
# to get a plain general-purpose assistant.
SYSPROMPT="$ROOT/prompts/system-prompt.txt"
[ -f "$SYSPROMPT" ] || SYSPROMPT=""

MMPROJ=""
for f in "$MODELS"/mmproj*.gguf; do
  [ -f "$f" ] && { MMPROJ="$f"; break; }
done

# ---------- pick the engine build for this OS/CPU ----------
OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
  Darwin)
    CACHE="$HOME/Library/Caches/portable-qwen"
    case "$ARCH" in
      arm64) BUILDS="macos-arm64" ;;
      *)     BUILDS="macos-x64" ;;
    esac
    ;;
  Linux)
    CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/portable-qwen"
    case "$ARCH" in
      x86_64|amd64)  BUILDS="linux-x64-vulkan linux-x64-cpu"
                     [ "$FORCE_CPU" = 1 ] && BUILDS="linux-x64-cpu" ;;
      aarch64|arm64) BUILDS="linux-arm64" ;;
      *) die "Unsupported CPU type: $ARCH (supported: x86_64, arm64)" ;;
    esac
    ;;
  *) die "Unsupported OS: $OS. On Windows, double-click START-WINDOWS.bat instead." ;;
esac

# The engine is stored as .tar.gz on the USB drive (keeps Unix permissions and
# symlinks intact on any filesystem). Unpack once into a local cache folder.
prepare_build() {
  local name="$1"
  local archive="$ENGINE_DIR/unix/$name.tar.gz"
  local dest="$CACHE/$VERSION/$name"
  [ -f "$archive" ] || return 1
  if [ ! -f "$dest/.ready" ]; then
    echo "First run on this computer: unpacking engine ($name)..." >&2
    rm -rf "$dest" && mkdir -p "$dest" || return 1
    tar -xzf "$archive" -C "$dest" --strip-components=1 || return 1
    chmod +x "$dest"/llama-* 2>/dev/null
    if [ "$OS" = "Darwin" ]; then
      xattr -dr com.apple.quarantine "$dest" 2>/dev/null
    fi
    touch "$dest/.ready"
  fi
  echo "$dest"
}

ORIG_LD_PATH="${LD_LIBRARY_PATH:-}"
ORIG_DYLD_PATH="${DYLD_LIBRARY_PATH:-}"

try_build() {
  local dir="$1" extra="${2:-}"
  if [ "$OS" = "Linux" ]; then
    export LD_LIBRARY_PATH="$dir${extra:+:$extra}${ORIG_LD_PATH:+:$ORIG_LD_PATH}"
  else
    export DYLD_LIBRARY_PATH="$dir${ORIG_DYLD_PATH:+:$ORIG_DYLD_PATH}"
  fi
  "$dir/llama-server" --version >/dev/null 2>&1
}

BIN=""
LAST_ERR=""
for b in $BUILDS; do
  dir="$(prepare_build "$b")" || continue
  if try_build "$dir"; then BIN="$dir"; break; fi
  # Some minimal Linux installs lack libgomp (OpenMP runtime); use the bundled copy.
  if [ "$OS" = "Linux" ]; then
    case "$b" in linux-arm64) libs="linux-arm64" ;; *) libs="linux-x64" ;; esac
    fb="$dir/fallback-libs"
    if [ -d "$ENGINE_DIR/unix/libs/$libs" ]; then
      mkdir -p "$fb" && cp -f "$ENGINE_DIR/unix/libs/$libs/"* "$fb/" 2>/dev/null
      if try_build "$dir" "$fb"; then BIN="$dir"; break; fi
    fi
  fi
  LAST_ERR="$("$dir/llama-server" --version 2>&1 | tail -3)"
  echo "Engine build '$b' does not run on this system, trying the next one..." >&2
done
[ -n "$BIN" ] || die "Could not start the AI engine on this computer.
$LAST_ERR
Linux needs glibc 2.34 or newer (Ubuntu 22.04 / Debian 12 / Fedora 35 or newer)
and OpenSSL 3 (package libssl3)."

EXTRA=()
[ "$FORCE_CPU" = 1 ] && EXTRA+=(-ngl 0)
[ "$NO_THINK" = 1 ] && EXTRA+=(--reasoning off)

echo
echo "=============================================================="
echo " Portable Qwen"
echo " Model : $(basename "$MODEL")"
[ -n "$MMPROJ" ] && echo " Vision: enabled ($(basename "$MMPROJ"))"
[ -n "$SYSPROMPT" ] && echo " Role  : prompts/system-prompt.txt"
echo " Engine: llama.cpp $VERSION ($(basename "$BIN"))"
echo "=============================================================="
echo " Loading the model from USB can take 1-4 minutes."
echo " Keep this window open. Close it (or press Ctrl+C) to stop."
echo "=============================================================="
echo

# ---------- terminal chat ----------
if [ "$MODE" = "chat" ]; then
  SYSARG=()
  [ -n "$SYSPROMPT" ] && SYSARG=(-sysf "$SYSPROMPT")
  exec "$BIN/llama-cli" -m "$MODEL" -c "$CTX" --jinja ${SYSARG[@]+"${SYSARG[@]}"} ${EXTRA[@]+"${EXTRA[@]}"}
fi

# ---------- web chat ----------
port_busy() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }
URL="http://127.0.0.1:$PORT"

open_browser() {
  if [ "$OS" = "Darwin" ]; then open "$URL"
  elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL" >/dev/null 2>&1
  else echo "Open this address in your browser: $URL"
  fi
}

# Already running (or still loading) from another window? Just open the chat.
if command -v curl >/dev/null 2>&1 && port_busy "$PORT"; then
  code="$(curl -s -o /dev/null -w '%{http_code}' "$URL/health" 2>/dev/null)"
  if [ "$code" = "200" ]; then
    echo "The AI is already running. Opening the chat: $URL"
    open_browser; exit 0
  elif [ "$code" = "503" ]; then
    echo "The AI is already starting in another window. The chat opens when it is ready."
    for _ in $(seq 1 600); do sleep 1; curl -sf "$URL/health" >/dev/null 2>&1 && break; done
    open_browser; exit 0
  fi
fi

# Keep the same port if possible: chat history is saved per address (port).
tries=0
while port_busy "$PORT"; do
  PORT=$((PORT + 1)); tries=$((tries + 1))
  [ $tries -lt 20 ] || die "No free port found near ${QWEN_PORT:-8080}."
done
if [ "$PORT" != "${QWEN_PORT:-8080}" ]; then
  echo "WARNING: port ${QWEN_PORT:-8080} is used by another program, using port $PORT."
  echo "         Chats saved under port ${QWEN_PORT:-8080} won't show here."
  echo
fi
URL="http://127.0.0.1:$PORT"

# Wait for the server to become ready, then open the browser.
start_waiter() {
  (
    for _ in $(seq 1 600); do
      sleep 1
      if command -v curl >/dev/null 2>&1; then
        curl -sf "$URL/health" >/dev/null 2>&1 && { echo; echo ">>> Ready - chat at $URL"; echo; open_browser; exit 0; }
      elif port_busy "$PORT"; then
        sleep 5; echo; echo ">>> Ready - chat at $URL"; echo; open_browser; exit 0
      fi
    done
  ) &
  WAITER=$!
}
WAITER=""
trap '[ -n "$WAITER" ] && kill $WAITER 2>/dev/null' EXIT

ARGS=(-m "$MODEL" -c "$CTX" --host 127.0.0.1 --port "$PORT" --jinja)
[ -n "$MMPROJ" ] && ARGS+=(--mmproj "$MMPROJ")
# The web chat gets the system prompt as its default "System Message" setting.
if [ -n "$SYSPROMPT" ]; then
  mkdir -p "$CACHE"
  UICFG="$CACHE/webui-config.json"
  {
    printf '{"systemMessage": "'
    tr -d '\r' < "$SYSPROMPT" | awk 'BEGIN{ORS=""} {gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); gsub(/\t/,"\\t"); if (NR>1) print "\\n"; print}'
    printf '"}\n'
  } > "$UICFG" && ARGS+=(--webui-config-file "$UICFG")
fi

start_waiter
GPUARG=()
try=0
while :; do
  "$BIN/llama-server" "${ARGS[@]}" ${EXTRA[@]+"${EXTRA[@]}"} ${GPUARG[@]+"${GPUARG[@]}"}
  rc=$?
  # 0 = normal stop; 130/143 = Ctrl+C or window closed: don't restart.
  if [ $rc -eq 0 ] || [ $rc -eq 130 ] || [ $rc -eq 143 ]; then break; fi
  try=$((try + 1))
  if [ $try -gt 3 ]; then
    echo; echo "The AI engine keeps stopping. Try:  bash START-LINUX.sh cpu  (or START-MAC.command cpu)"
    break
  fi
  # From the 2nd failure on, don't use the graphics card.
  [ "$FORCE_CPU" = 0 ] && [ $try -ge 2 ] && GPUARG=(-ngl 0)
  echo
  echo "=============================================================="
  echo " The AI engine stopped unexpectedly. Restarting ($try of 3)..."
  echo " When it says \"listening\", click Retry in the browser."
  echo "=============================================================="
  echo
  kill $WAITER 2>/dev/null
  sleep 3
done
