# DickMacOS - Project Scope

## Overview
A macOS menu bar application for high-performance, local speech-to-text dictation. It uses `whisper.cpp` for transcription on Apple Silicon and provides a native, translucent HUD for real-time feedback.

**Version**: 0.0.1  
**Company**: jsmilker

## Features

### Core Functionality
- **Global Hotkey**: `Ctrl+Shift+D` to toggle recording session.
- **Menu Bar Icon**: Dynamic microphone icon indicating idle vs. recording status.
- **Modern HUD Modal**: A rounded, blurred floating panel (`NSVisualEffectView`) showing live transcription text.
- **Chunk-based Transcription**: Processes audio every 2 seconds to provide live updates as you speak.
- **Auto-paste**: Simulates `Cmd+V` via `CGEvent` to insert text directly into the active application.
- **Clipboard**: The final transcribed text is automatically stored in the system clipboard.

### Audio Processing
- **Format**: 16kHz, mono, 16-bit PCM (Required for Whisper).
- **Management**: Creates 2-second chunks during recording; concatenates all chunks for a final high-accuracy pass upon release.
- **Cleanup**: Automatically deletes temporary `.wav` files after processing.

---

## Project Structure
murmurkey-mac-master/
├── Sources/DickMacOS/
│   ├── main.swift              # App entry point
│   ├── AppDelegate.swift       # Lifecycle & Main Logic
│   ├── AudioRecorder.swift     # AVAudioRecorder & Chunk management
│   ├── Transcriber.swift       # whisper-cli wrapper
│   ├── ModelManager.swift      # Automatic model downloading
│   ├── KeyMonitor.swift        # Global hotkey (NSEvent monitor)
│   ├── RecordingPanel.swift    # HUD UI (NSPanel + VisualEffectView)
│   ├── Paster.swift            # Keyboard simulation logic
│   └── Logger.swift            # Persistent logging to ~/Library/Logs


---

## Current State

### Working ✅
- **App Core**: Launches as an accessory app (no Dock icon).
- **Hotkey**: `Ctrl+Shift+D` reliably starts and stops recording.
- **Transcription**: `whisper.cpp` generates text from local audio chunks.
- **HUD Visibility**: Using `NSTextField` inside `NSVisualEffectView` ensures text is visible in both Light and Dark modes.
- **Automation**: Successfully pastes text into target apps (Notes, Slack, Xcode, etc.).
- **Cleanup**: Temporary audio files are removed after the final transcription.


## Technical Details

### UI Architecture (`RecordingPanel`)
- **Panel**: `NSPanel` with `.nonactivatingPanel` to avoid stealing focus from the active text field.
- **Appearance**: Uses `HUDWindow` material for a native "Siri-like" blurred background.

### Transcription Flow
- User presses Ctrl+Shift+D

- RecordingPanel.show() -> Displays "Listening..."

- AudioRecorder.startRecording()

- [Every 2s] Chunk created -> Transcribed -> RecordingPanel.updateText()

- User presses Ctrl+Shift+D again

- Final Transcription pass -> Paster.paste() -> RecordingPanel.hide()


---

## Commands

### Build & Install
```bash
make clean
make install
```

### Run
Run local `.build`
```bash
make run
```

### Release
Build distribution packages (ZIP + DMG)
```bash
make dist
```

Outputs:
- `dickmacos-0.0.1.zip`
- `dickmacos-0.0.1.dmg`