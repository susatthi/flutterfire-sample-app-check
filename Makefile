FVM := $(shell which fvm)
FLUTTER := $(FVM) flutter
DART := $(FVM) dart

.PHONY: setup
setup:
	dart pub global activate fvm
	fvm install

.PHONY: pub-get
pub-get:
	$(FLUTTER) pub get

.PHONY: pub-upgrade
pub-upgrade:
	$(FLUTTER) pub upgrade

.PHONY: pod-install
pod-install:
	cd ios && pod install && cd ..

.PHONY: clean
clean:
	$(FLUTTER) clean
	rm -rf ios/Pods ios/Podfile.lock

.PHONY: clean-build
clean-build:
	make clean
	make pub-get
	make pod-install

.PHONY: analyze
analyze:
	$(FLUTTER) analyze

.PHONY: format
format:
	@find lib -name "*.dart" \
		-not -name "*.g.dart" \
		-not -name "*.freezed.dart" \
		-not -name "*.gr.dart" \
		-not -name "*.gen.dart" \
		-not -path "*/generated/*" \
		| xargs $(DART) format lib/

.PHONY: build-runner-build
build-runner-build:
	$(DART) run build_runner build --delete-conflicting-outputs

.PHONY: build-runner-watch
build-runner-watch:
	$(DART) run build_runner clean
	$(DART) run build_runner watch --delete-conflicting-outputs

### Android Release Commands

.PHONY: build-android
build-android:
	$(FLUTTER) build appbundle \
		--release

### iOS Release Commands

.PHONY: build-ios
build-ios:
	$(FLUTTER) build ipa \
		--release
