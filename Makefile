.PHONY: release clean install dist

VERSION = 0.0.1

release:
	@./build.sh

clean:
	rm -rf .build
	rm -rf "/Applications/DickMacOS.app"
	rm -f dickmacos-*.zip
	rm -f dickmacos-*.dmg

install: release
	rm -rf "/Applications/DickMacOS.app"
	cp -R ".build/DickMacOS.app" "/Applications/DickMacOS.app"

run:
	.build/DickMacOS.app/Contents/MacOS/whisper-dictation

dist: release
	@echo "Creating distribution packages..."
	zip -r dickmacos-$(VERSION).zip ".build/DickMacOS.app"
	hdiutil create -volname "DickMacOS-$(VERSION)" -srcfolder ".build/DickMacOS.app" -ov -format UDZO dickmacos-$(VERSION).dmg
	@echo ""
	@echo "Distribution packages created:"
	@echo "  - dickmacos-$(VERSION).zip"
	@echo "  - dickmacos-$(VERSION).dmg"