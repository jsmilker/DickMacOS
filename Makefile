.PHONY: release clean install

release:
	@./build.sh

clean:
	rm -rf .build
	rm -rf "/Applications/Whisper Dictation.app"

install: release
	rm -rf "/Applications/Whisper Dictation.app"
	cp -R ".build/Whisper Dictation.app" "/Applications/Whisper Dictation.app"

run:
	.build/Whisper\ Dictation.app/Contents/MacOS/whisper-dictation