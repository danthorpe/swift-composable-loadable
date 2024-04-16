CONFIG = debug
PLATFORM_IOS = iOS Simulator,id=$(call udid_for,iOS 17.2,iPhone \d\+ Pro [^M])
PLATFORM_MACOS = macOS
PLATFORM_MAC_CATALYST = macOS,variant=Mac Catalyst
PLATFORM_TVOS = tvOS Simulator,id=$(call udid_for,tvOS 17.2,TV)
PLATFORM_VISIONOS = visionOS Simulator,id=$(call udid_for,visionOS 1.0,Vision)
PLATFORM_WATCHOS = watchOS Simulator,id=$(call udid_for,watchOS 10.2,Watch)

default: test-all

test-all:
	swift test

docs:
	mkdir -p $(output)/$(tag)/$(target)
	swift package \
	--allow-writing-to-directory $(output)/$(tag)/$(target) \
	generate-documentation --target $(target) \
	--output-path $(output)/$(tag)/$(target) \
	--transform-for-static-hosting \
	--hosting-base-path /$(basepath)/$(tag)/$(target) \
	&& echo "✅ Documentation generated for $(target) @ $(tag) release." \
	|| echo "⚠️ Documentation skipped for $(target) @ $(tag)."
