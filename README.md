# DickMacOS

macOS menu bar dictation using whisper.cpp.

## Quick Start

```bash
brew install whisper-cpp
curl -L -o /opt/homebrew/share/whisper-cpp/models/ggml-medium.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin
make clean
make install

# Run from terminal (inherits terminal's permissions - no dialogs needed)
make run
```

> **Note**: Running from terminal is recommended. The app inherits terminal's permissions, avoiding macOS permission dialogs.


## Build

```bash
make release
```

## Publish Release to GH

```bash
make dist

gh auth login

gh release create v1.0.0 \
    dickmacos-1.0.0.dmg \
    dickmacos-1.0.0.zip \
    --title "v1.0.0" \
    --notes "foobar"
```

## Permissions

**Running from terminal**: No setup needed - inherits terminal's permissions.

**Running from Finder**: Manually grant in System Settings:
- **Accessibility**: System Settings → Privacy & Security → Accessibility
- **Microphone**: System Settings → Privacy & Security → Microphone
- **Automation**: System Settings → Privacy & Security → Automation

## Usage

**Option+Shift+D** to start/stop recording. Text auto-pastes to clipboard on stop.

## Model

```bash
WHISPER_MODEL_PATH=/path/to/model.bin .build/DickMacOS.app/Contents/MacOS/whisper-dictation
```