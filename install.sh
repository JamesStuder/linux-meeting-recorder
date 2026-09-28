#!/usr/bin/env bash
# Install meeting-recorder for the current user (no root needed).
set -euo pipefail
cd "$(dirname "$0")"

missing=()
for cmd in gpu-screen-recorder ffmpeg ffprobe pactl notify-send systemd-run journalctl; do
    command -v "$cmd" >/dev/null || missing+=("$cmd")
done
python3 -c 'import PyQt6.QtWidgets' 2>/dev/null || missing+=("PyQt6 (python-pyqt6)")
command -v qdbus6 >/dev/null || command -v qdbus >/dev/null || echo "note: qdbus6 not found — the meeting window's screen can't be detected (KDE Plasma only)"
if ((${#missing[@]})); then
    echo "Missing dependencies: ${missing[*]}" >&2
    exit 1
fi

install -Dm755 bin/meeting-recorder      "$HOME/.local/bin/meeting-recorder"
install -Dm755 bin/meeting-recorder-tray "$HOME/.local/bin/meeting-recorder-tray"
install -Dm644 systemd/meeting-recorder.service      "$HOME/.config/systemd/user/meeting-recorder.service"
install -Dm644 systemd/meeting-recorder-tray.service "$HOME/.config/systemd/user/meeting-recorder-tray.service"
if [ ! -e "$HOME/.config/meeting-recorder/config.toml" ]; then
    install -Dm644 config.example.toml "$HOME/.config/meeting-recorder/config.toml"
fi

systemctl --user daemon-reload
systemctl --user enable --now meeting-recorder.service meeting-recorder-tray.service
echo "Installed. Recordings go to the folder set in ~/.config/meeting-recorder/config.toml."
