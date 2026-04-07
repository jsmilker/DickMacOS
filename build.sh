
#!/bin/bash
set -e

echo "Building DickMacOS..."

# Clean previous build
rm -rf .build

# Get whisper-cpp prefix
WHISPER_PREFIX=$(brew --prefix whisper-cpp)
GGML_PREFIX=$(brew --prefix ggml)

# Create app bundle structure
mkdir -p ".build/DickMacOS.app/Contents/MacOS"
mkdir -p ".build/DickMacOS.app/Contents/Resources"
mkdir -p ".build/DickMacOS.app/Contents/Frameworks"

# Copy Info.plist
cp Info.plist ".build/DickMacOS.app/Contents/Info.plist"

# Copy app icon
cp "res/AppIcon.icns" ".build/DickMacOS.app/Contents/Resources/AppIcon.icns"

# Copy menu bar icons (to bundle root for NSImage(named:) lookup)
cp "res/assets/Active.png" ".build/DickMacOS.app/Contents/Resources/Active.png"
cp "res/assets/Inactive.png" ".build/DickMacOS.app/Contents/Resources/Inactive.png"

# Copy whisper-cli and libraries
cp "$WHISPER_PREFIX/bin/whisper-cli" ".build/DickMacOS.app/Contents/MacOS/"
cp "$WHISPER_PREFIX/lib/libwhisper.1.dylib" ".build/DickMacOS.app/Contents/Frameworks/"
cp "$GGML_PREFIX/lib/libggml.0.dylib" ".build/DickMacOS.app/Contents/Frameworks/"
cp "$GGML_PREFIX/lib/libggml-base.0.dylib" ".build/DickMacOS.app/Contents/Frameworks/"

# Fix library paths for whisper-cli
install_name_tool -add_rpath @executable_path/../Frameworks ".build/DickMacOS.app/Contents/MacOS/whisper-cli"

# Fix ggml library paths for whisper-cli
install_name_tool -change \
    "/opt/homebrew/opt/ggml/lib/libggml.0.dylib" \
    "@executable_path/../Frameworks/libggml.0.dylib" \
    ".build/DickMacOS.app/Contents/MacOS/whisper-cli"

install_name_tool -change \
    "/opt/homebrew/opt/ggml/lib/libggml-base.0.dylib" \
    "@executable_path/../Frameworks/libggml-base.0.dylib" \
    ".build/DickMacOS.app/Contents/MacOS/whisper-cli"

# Fix library paths for libwhisper
install_name_tool -change \
    "/opt/homebrew/opt/ggml/lib/libggml.0.dylib" \
    "@executable_path/../Frameworks/libggml.0.dylib" \
    ".build/DickMacOS.app/Contents/Frameworks/libwhisper.1.dylib"

install_name_tool -change \
    "/opt/homebrew/opt/ggml/lib/libggml-base.0.dylib" \
    "@executable_path/../Frameworks/libggml-base.0.dylib" \
    ".build/DickMacOS.app/Contents/Frameworks/libwhisper.1.dylib"

# Compile Swift sources
SOURCES=$(find Sources/DickMacOS -name "*.swift")
swiftc $SOURCES \
    -o ".build/DickMacOS.app/Contents/MacOS/whisper-dictation" \
    -framework AppKit \
    -framework AVFoundation \
    -framework Carbon \
    -O -whole-module-optimization

# Code sign frameworks first
codesign --force --sign - ".build/DickMacOS.app/Contents/Frameworks/libggml.0.dylib"
codesign --force --sign - ".build/DickMacOS.app/Contents/Frameworks/libggml-base.0.dylib"
codesign --force --sign - ".build/DickMacOS.app/Contents/Frameworks/libwhisper.1.dylib"

# Sign whisper-cli
codesign --force --sign - ".build/DickMacOS.app/Contents/MacOS/whisper-cli"

# Sign main executable with hardened runtime and entitlements
codesign --force --sign - --options runtime --entitlements DickMacOS.entitlements ".build/DickMacOS.app/Contents/MacOS/whisper-dictation"

# Sign app bundle deep (covers all contents)
codesign --force --deep --sign - ".build/DickMacOS.app"

echo ""
echo "Build complete!"
echo "Run with:"
echo "  .build/DickMacOS.app/Contents/MacOS/whisper-dictation"
echo ""
echo "Or set custom model path:"
echo "  WHISPER_MODEL_PATH=/path/to/ggml-medium.bin .build/DickMacOS.app/Contents/MacOS/whisper-dictation"
