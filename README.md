# Whisper Dictation

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

## TODO:
  - [ ] package this biach properly for release

## Usage

**Cmd+Shift+D** to start/stop recording. Text auto-pastes on stop.

## Model

```bash
WHISPER_MODEL_PATH=/path/to/model.bin .build/Whisper\ Dictation.app/Contents/MacOS/whisper-dictation
```