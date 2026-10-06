# linux-meeting-recorder

Record your own side of online meetings on Linux — screen, your microphone and the
meeting audio — **without a bot joining the call**. It notices when Teams, Zoom or a
browser meeting starts using your microphone, offers a few seconds to skip or pick a
screen, and records until that meeting ends.

Built for KDE Plasma 6 on Wayland with PipeWire. Other desktops work with reduced
features (see [Requirements](#requirements)).

## Features

- **Automatic start** — a notification appears when a meeting grabs the mic:
  *Skip*, or pick which screen to record. Doing nothing records the screen the
  meeting window is on.
- **Automatic stop** — recording follows that meeting's own audio stream and stops
  about 5 seconds after it closes.
- **Back-to-back meetings** — jump straight into the next meeting and the first
  recording is saved while a new one starts immediately (with a *Skip (delete)*
  button in case you didn't want it).
- **Change screens mid-meeting** — from the tray menu or `meeting-recorder screen next`.
  Audio is recorded continuously, so the audio file never has a gap; video pieces
  are joined into one file afterwards.
- **Notes with timestamps** — a small always-on-top window; each note is stamped with
  the moment you *started typing* it and its offset into the recording, so it lines
  up with what was said.
- **Tray icon** — grey dot when idle, red dot while recording. Left or right click opens
  the menu (Start; or Notes, Stop, Screen, Open folder while recording).
- **One folder per recording** with `<name>.mp4` (video + audio), `<name>.m4a`
  (audio only — handy for transcription services) and `<name>.json` (title,
  duration, screens, notes).
- **Your own actions** — add buttons to the "Meeting saved" notification (upload,
  transcribe, copy somewhere) or run a command after every recording.
- Mic tests and accidental starts shorter than a minute are deleted automatically.

## Requirements

- Linux with **PipeWire** (`pipewire-pulse`) and **systemd** (user services)
- [gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/about/)
- `ffmpeg` / `ffprobe`
- Python 3.11+ and **PyQt6** (tray icon and notes window)
- `notify-send` (libnotify) with a notification server that supports actions
- **KDE Plasma 6 (KWin)** for picking the screen the meeting window is on and for the
  meeting title — uses `qdbus6`. Elsewhere it falls back to `fallback_screen` and a
  generic title.

Arch / CachyOS:

```sh
sudo pacman -S gpu-screen-recorder ffmpeg python-pyqt6 libnotify
```

## Install

```sh
git clone https://github.com/JamesStuder/linux-meeting-recorder
cd linux-meeting-recorder
./install.sh
```

This copies the two programs to `~/.local/bin`, installs and starts two user services
(`meeting-recorder` and `meeting-recorder-tray`) and creates
`~/.config/meeting-recorder/config.toml` from `config.example.toml` if you don't have
one yet. Remove it again with `./uninstall.sh` (recordings and config are kept).

## Use

Join a meeting — that's it. Or control it yourself:

| Command | What it does |
|---|---|
| `meeting-recorder start` | Start recording now, no meeting needed (stops only when you stop it) |
| `meeting-recorder stop` | Stop the current recording |
| `meeting-recorder screen next` | Record the next screen from now on (or give a name, e.g. `DP-1`) |
| `meeting-recorder notes` | Open the notes window |

These are easy to bind to keyboard shortcuts or Stream Deck keys.

A finished recording looks like this:

```
~/Videos/Meetings/2026-09-28_0946 Weekly sync/
├── 2026-09-28_0946 Weekly sync.mp4
├── 2026-09-28_0946 Weekly sync.m4a
└── 2026-09-28_0946 Weekly sync.json
```

```json
{
  "title": "Weekly sync",
  "app": "Teams",
  "start": "2026-09-28T09:46:21",
  "duration": 846,
  "screens": ["eDP-1"],
  "notes": [
    {"at": "00:12:34", "seconds": 754, "time": "09:58:52", "text": "Follow up on the export"}
  ]
}
```

## Configure

Everything lives in `~/.config/meeting-recorder/config.toml`; see
[`config.example.toml`](config.example.toml) for all options. Restart the service after
changes: `systemctl --user restart meeting-recorder`.

Example — add an upload button to the "Meeting saved" notification:

```toml
[[actions]]
label = "Upload"
command = "rclone copy {folder} remote:meetings"
```

Placeholders: `{folder}`, `{audio}`, `{video}`, `{json}`, `{title}`.

## How it works

- PipeWire is polled every second for microphone streams belonging to a meeting app
  (`[apps]` in the config). Every call opens its own stream, which is what lets the
  recorder tell one meeting from the next.
- A one-shot KWin script finds the meeting window's screen and title.
- Audio: one `ffmpeg` process mixes the meeting's output with your mic into a
  continuous file (wall-clock timestamps, so video can be aligned exactly).
- Video: `gpu-screen-recorder` per screen, hardware encoded. Changing screens starts a
  new piece before the old one stops, so nothing is lost in between.
- When the meeting ends, a separate `systemd-run` job writes the `.m4a` and `.json`
  first, then joins the video (a straight copy for one screen; scaled onto
  `join_size` and re-encoded when several screens were used). If the recorder is
  restarted mid-meeting, the next start finishes the interrupted recording.

Logs: `journalctl --user -u meeting-recorder` and `<output_dir>/.recorder.log`.

## Privacy

Recordings stay on your machine. Your microphone is recorded directly, so you are
recorded even while muted in the meeting app. Make sure recording meetings is allowed
where you are and that the other participants agree.

## License

MIT
