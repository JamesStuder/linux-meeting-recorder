#!/usr/bin/env bash
# Remove meeting-recorder (recordings and config are kept).
set -euo pipefail
systemctl --user disable --now meeting-recorder.service meeting-recorder-tray.service 2>/dev/null || true
rm -f "$HOME/.local/bin/meeting-recorder" "$HOME/.local/bin/meeting-recorder-tray" \
      "$HOME/.config/systemd/user/meeting-recorder.service" "$HOME/.config/systemd/user/meeting-recorder-tray.service"
systemctl --user daemon-reload
echo "Removed. Your recordings and ~/.config/meeting-recorder were left in place."
