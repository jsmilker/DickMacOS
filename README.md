# DickMacOS

macOS menu bar dictation using whisper.cpp.

## Quick Start

```bash
brew install whisper-cpp
curl -L -o /opt/homebrew/share/whisper-cpp/models/ggml-medium.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin
make clean
make install

make run
```

## Permissions

- **Accessibility**: System Settings -> Privacy & Security -> Accessibility
- **Microphone**: System Settings -> Privacy & Security -> Microphone

## Usage

**Ctrl+Shift+D** to start/stop recording. Text auto-pastes to clipboard on stop.

## Model

```bash
WHISPER_MODEL_PATH=/path/to/model.bin .build/DickMacOS.app/Contents/MacOS/whisper-dictation
```