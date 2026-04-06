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

# Copy whisper-cli and libraries
cp "$WHISPER_PREFIX/bin/whisper-cli" ".build/DickMacOS.app/Contents/MacOS/"
cp "$WHISPER_PREFIX/lib/libwhisper.1.dylib" ".build/DickMacOS.app/Contents/Frameworks/"
cp "$GGML_PREFIX/lib/libggml.0.dylib" ".build/DickMacOS.app/Contents/Frameworks/"
cp "$GGML_PREFIX/lib/libggml-base.0.dylib" ".build/DickMacOS.app/Contents/Frameworks/"

# Fix library paths for whisper-cli
install_name_tool -add_rpath @executable_path/../Frameworks ".build/DickMacOS.app/Contents/MacOS/whisper-cli" 2>/dev/null || true

# Fix ggml library paths for whisper-cli
install_name_tool -change \
    "/opt/homebrew/opt/ggml/lib/libggml.0.dylib" \
    "@executable_path/../Frameworks/libggml.0.dylib" \
    ".build/DickMacOS.app/Contents/MacOS/whisper-cli" 2>/dev/null || true



install_name_tool -change \
    "/opt/homebrew/opt/ggml/lib/libggml-base.0.dylib" \
    "@executable_path/../Frameworks/libggml-base.0.dylib" \
    ".build/DickMacOS.app/Contents/MacOS/whisper-cli" 2>/dev/null || true

# Fix library paths for libwhisper
install_name_tool -change \
    "/opt/homebrew/opt/ggml/lib/libggml.0.dylib" \
    "@executable_path/../Frameworks/libggml.0.dylib" \
    ".build/DickMacOS.app/Contents/Frameworks/libwhisper.1.dylib" 2>/dev/null || true

install_name_tool -change \
    "/opt/homebrew/opt/ggml/lib/libggml-base.0.dylib" \
    "@executable_path/../Frameworks/libggml-base.0.dylib" \
    ".build/DickMacOS.app/Contents/Frameworks/libwhisper.1.dylib" 2>/dev/null || true

# Compile Swift sources
SOURCES=$(find Sources/DickMacOS -name "*.swift")
swiftc $SOURCES \
    -o ".build/DickMacOS.app/Contents/MacOS/whisper-dictation" \
    -framework AppKit \
    -framework AVFoundation \
    -framework Carbon \
    -O -whole-module-optimization

# Code sign with ad-hoc signature
codesign --force --deep --sign - ".build/DickMacOS.app"

echo ""
echo "Build complete!"
echo "Run with:"
echo "  .build/DickMacOS.app/Contents/MacOS/whisper-dictation"
echo ""
echo "Or set custom model path:"
echo "  WHISPER_MODEL_PATH=/path/to/ggml-medium.bin .build/DickMacOS.app/Contents/MacOS/whisper-dictation"
