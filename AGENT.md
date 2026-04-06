# Whisper Dictation - Project Scope

## Overview
A macOS menu bar application for high-performance, local speech-to-text dictation. It uses `whisper.cpp` for transcription on Apple Silicon and provides a native, translucent HUD for real-time feedback.

## Features

### Core Functionality
- **Global Hotkey**: `Cmd+Shift+D` to toggle recording session.
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
├── Sources/WhisperDictation/
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
- **Hotkey**: `Cmd+Shift+D` reliably starts and stops recording.
- **Transcription**: `whisper.cpp` generates text from local audio chunks.
- **HUD Visibility**: Using `NSTextField` inside `NSVisualEffectView` ensures text is visible in both Light and Dark modes.
- **Automation**: Successfully pastes text into target apps (Notes, Slack, Xcode, etc.).
- **Cleanup**: Temporary audio files are removed after the final transcription.

### Recently Fixed 🛠️
- **Modal Rendering**: Replaced the complex `NSTextView` stack with a simplified `NSTextField` to fix frame initialization and text invisibility.
- **Build Errors**: Fixed the `NSPanel` member error by applying the corner radius to the `NSVisualEffectView` layer.
- **Lifecycle**: Added `RecordingPanel.hide()` to the finalization flow so the HUD disappears after transcription.

### Known Issues / Backlog ⚠️
- **Focus Preservation**: If the HUD is clicked, the target application may lose focus, occasionally causing the paste event to fail.
- **Concurrency**: Minor `MainActor` isolation warnings in `AppDelegate` handled via `DispatchQueue.main.async`.

---

## Technical Details

### UI Architecture (`RecordingPanel`)
- **Panel**: `NSPanel` with `.nonactivatingPanel` to avoid stealing focus from the active text field.
- **Appearance**: Uses `HUDWindow` material for a native "Siri-like" blurred background.
- **Rounding**: `visualEffect.layer?.cornerRadius = 18.0` provides the modern macOS aesthetic.

### Transcription Flow
User presses Cmd+Shift+D
↓
RecordingPanel.show() -> Displays "Listening..."
↓
AudioRecorder.startRecording()
↓
[Every 2s] Chunk created -> Transcribed -> RecordingPanel.updateText()
↓
User presses Cmd+Shift+D again
↓
Final Transcription pass -> Paster.paste() -> RecordingPanel.hide()


---

## Commands

### Build & Install
```bash
make release    # Build to .build/
make install    # Move to /Applications/
Development Run
Bash
WHISPER_MODEL_PATH=/path/to/model.bin \
  .build/Whisper\ Dictation.app/Contents/MacOS/whisper-dictation