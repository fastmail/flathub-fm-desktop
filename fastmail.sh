#!/usr/bin/env bash

export TMPDIR="$XDG_RUNTIME_DIR/app/${FLATPAK_ID:-com.fastmail.Fastmail}"

declare -a FLAGS=()

if [[ -f "$(dirname "${BASH_SOURCE[0]}")/fastmail.conf" ]]; then
    CONF_FILE="$(dirname "${BASH_SOURCE[0]}")/fastmail.conf"
elif [[ -n "$XDG_CONFIG_HOME" && -f "$XDG_CONFIG_HOME/fastmail.conf" ]]; then
    CONF_FILE="$XDG_CONFIG_HOME/fastmail.conf"
elif [[ -f "$HOME/.config/fastmail.conf" ]]; then
    CONF_FILE="$HOME/.config/fastmail.conf"
fi

if [[ -n "$CONF_FILE" ]]; then
    echo "Reading config file: $CONF_FILE"
    # Read flags from config file, allow for comments
    while read -r -a line_flags; do
        FLAGS+=("${line_flags[@]}")
    done < <(grep -v '^\s*#' "$CONF_FILE")
fi

if [[ $XDG_SESSION_TYPE == "wayland" && -z "$DISPLAY" ]]; then
    if [[ -c /dev/nvidia0 ]]; then
        echo "Using NVIDIA on Wayland, disabling gpu sandbox"
        FLAGS+=(--disable-gpu-sandbox)
    fi

    WAYLAND_SOCKET=${WAYLAND_DISPLAY:-"wayland-0"}
    if [[ "${WAYLAND_SOCKET:0:1}" != "/" ]]; then
        WAYLAND_SOCKET="$XDG_RUNTIME_DIR/$WAYLAND_SOCKET"
    fi

    echo "Running on native Wayland"
    FLAGS+=(--enable-wayland-ime)
    FLAGS+=(--wayland-text-input-version=3)
else
    echo "Running on X11"
fi

echo "Passing the following arguments to Electron:" "${FLAGS[@]}" "$@"
zypak-wrapper.sh "/app/fastmail/production" "${FLAGS[@]}" "$@"
