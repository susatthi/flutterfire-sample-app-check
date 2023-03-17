FVM := $(shell which fvm)
FLUTTER := $(FVM) flutter

.PHONY: setup
setup:
	dart pub global activate fvm
	fvm install

.PHONY: get-dependencies
get-dependencies:
	$(FLUTTER) pub get

.PHONY: clean
clean:
	$(FLUTTER) clean

.PHONY: analyze
analyze:
	$(FLUTTER) analyze

.PHONY: format
format:
	$(FLUTTER) format lib/

.PHONY: format-dry-exit-if-changed
format-dry-exit-if-changed:
	$(FLUTTER) format --dry-run --set-exit-if-changed lib/

.PHONY: build-runner
build-runner:
	$(FLUTTER) packages pub run build_runner build --delete-conflicting-outputs

### Web Relase Commands

.PHONY: build-web
build-web:
	make get-dependencies
	$(FLUTTER) build web \
		--web-renderer html \
		--release

.PHONY: deploy-web
deploy-web:
	make build-web
	firebase deploy --only hosting

### Android Relase Commands

.PHONY: build-android
build-android:
	$(FLUTTER) build appbundle \
		--release

### iOS Relase Commands

.PHONY: build-ios
build-ios:
	$(FLUTTER) build ipa \
		--export-options-plist=ios/ExportOptions_dev.plist \
		--release
