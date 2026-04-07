# DickMacOS - Project Scope

## Overview
A macOS menu bar application for high-performance, local speech-to-text dictation. It uses `whisper.cpp` for transcription on Apple Silicon and provides a native, translucent HUD for real-time feedback.

**Version**: 0.0.1  
**Company**: jsmilker

## Features

### Core Functionality
- **Global Hotkey**: `Option+Shift+D` (configurable) to toggle recording session.
- **Menu Bar Icon**: Dynamic icons (Active.png/Inactive.png) indicating idle vs. recording status.
- **Audio Source Display**: Shows current microphone input in menu bar (e.g., "🎤 FIFINE K678 Microphone").
- **Modern HUD Modal**: A rounded, blurred floating panel (`NSVisualEffectView`) showing live transcription text.
- **Download Progress Panel**: Floating progress bar showing model download status (0-100%).
- **Chunk-based Transcription**: Processes audio every 2 seconds to provide live updates as you speak.
- **Auto-paste**: Simulates `Cmd+V` via `CGEvent` to insert text directly into the active application.
- **Clipboard**: The final transcribed text is automatically stored in the system clipboard.

### Audio Processing
- **Format**: 16kHz, mono, 16-bit PCM (Required for Whisper).
- **Device Detection**: Automatically detects and displays the active audio input device name.
- **Management**: Creates 2-second chunks during recording; concatenates all chunks for a final high-accuracy pass upon release.
- **Cleanup**: Automatically deletes temporary `.wav` files after processing.

### Model Management
- **Brew Model Detection**: Automatically uses existing whisper-cpp model from `/opt/homebrew/share/whisper-cpp/models/ggml-medium.bin`.
- **Auto-Download**: Downloads model from HuggingFace if not found locally.
- **Progress Tracking**: Real-time progress updates during download.

### Permissions
- **First-Launch Prompt**: Requests Accessibility, Microphone, and Apple Events permissions on initial launch.
- **Permission Polling**: Waits for user to grant permissions in System Settings (doesn't quit).
- **Hardened Runtime**: App signed with `--options runtime` and entitlements for persistent permissions.
- **Re-grant Required**: After each rebuild, permissions must be re-granted in System Settings.

---

## Project Structure
```
murmurkey-mac-master/
├── Sources/DickMacOS/
│   ├── main.swift              # App entry point
│   ├── AppDelegate.swift       # Lifecycle & Main Logic
│   ├── AudioRecorder.swift     # AVAudioRecorder & Chunk management
│   ├── Transcriber.swift       # whisper-cli wrapper
│   ├── ModelManager.swift      # Automatic model downloading
│   ├── KeyMonitor.swift        # Global hotkey (NSEvent monitor)
│   ├── RecordingPanel.swift    # HUD UI (NSPanel + VisualEffectView)
│   ├── DownloadPanel.swift     # Model download progress UI
│   ├── PermissionChecker.swift # Permission requests & validation
│   ├── Paster.swift            # Keyboard simulation logic
│   └── Logger.swift            # Persistent logging to ~/Library/Logs
├── res/
│   ├── logo/DickMacOS_Logo.png # Source app icon (used to generate AppIcon.icns)
│   ├── AppIcon.icns            # App icon for bundle
│   └── assets/
│       ├── Active.png          # Menu bar icon (recording)
│       └── Inactive.png        # Menu bar icon (idle)
├── DickMacOS.entitlements      # Hardened runtime entitlements
├── Info.plist
├── build.sh
└── Makefile
```

---

## Current State

### Working ✅
- **App Core**: Launches as an accessory app (no Dock icon).
- **Hotkey**: `Option+Shift+D` reliably starts and stops recording (configurable via menu).
- **Transcription**: `whisper.cpp` generates text from local audio chunks (GPU-accelerated on M-series).
- **HUD Visibility**: Using `NSTextField` inside `NSVisualEffectView` ensures text is visible in both Light and Dark modes.
- **Automation**: Successfully pastes text into target apps (Notes, Slack, Xcode, etc.).
- **Cleanup**: Temporary audio files are removed after the final transcription.
- **Permissions**: Prompts for all permissions on first launch, waits for grant.
- **Model Detection**: Uses brew model if available, downloads if not with progress bar.
- **Custom Icons**: App icon and menu bar icons from res/ folder.
- **Audio Source**: Displays current microphone name in menu bar.
- **Code Signing**: Frameworks signed individually to prevent dylib loading issues.

---

## Technical Details

### UI Architecture (`RecordingPanel`)
- **Panel**: `NSPanel` with `.nonactivatingPanel` to avoid stealing focus from the active text field.
- **Appearance**: Uses `HUDWindow` material for a native "Siri-like" blurred background.

### Permission Flow (`PermissionChecker`)
- Checks all permissions on every launch
- Shows single dialog if any permission missing
- Opens System Settings automatically
- Polls every 1s until all permissions granted
- Proceeds automatically once granted

### Transcription Flow
1. User presses Option+Shift+D
2. RecordingPanel.show() -> Displays "Listening..."
3. AudioRecorder.startRecording() (captures from detected microphone)
4. [Every 2s] Chunk created -> Transcribed -> RecordingPanel.updateText()
5. User presses Option+Shift+D again
6. Final Transcription pass -> Paster.paste() -> RecordingPanel.hide()

### Code Signing Strategy
- Frameworks (libwhisper, libggml) signed first without hardened runtime
- Main executable signed with hardened runtime
- App bundle signed with `--deep` to bundle all signatures
- Prevents Team ID mismatch errors on dylib loading

---

## Commands

### Build & Install
```bash
make clean
make install
```

### Run (Terminal - Recommended)
Running from terminal inherits terminal's permissions (no dialogs needed):
```bash
make run
# Or directly:
/Applications/DickMacOS.app/Contents/MacOS/whisper-dictation
```

### Run (Finder/App)
If launching from Finder, you must manually grant permissions:

1. **Accessibility**: System Settings → Privacy & Security → Accessibility
2. **Microphone**: System Settings → Privacy & Security → Microphone  
3. **Automation**: System Settings → Privacy & Security → Automation

Then relaunch the app.

### Reset Permissions
```bash
tccutil reset All com.jsmilker.dickmacos
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
