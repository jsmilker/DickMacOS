# Whisper Dictation

macOS menu bar dictation using whisper.cpp.

## Quick Start

```bash
brew install whisper-cpp
curl -L -o /opt/homebrew/share/whisper-cpp/models/ggml-small.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin
make release
make install
```

## Permissions

- **Accessibility**: System Settings → Privacy & Security → Accessibility
- **Microphone**: System Settings → Privacy & Security → Microphone

## Usage

**Cmd+Shift+D** to start/stop recording. Text auto-pastes on stop.

## Model

```bash
WHISPER_MODEL_PATH=/path/to/model.bin .build/Whisper\ Dictation.app/Contents/MacOS/whisper-dictation
```