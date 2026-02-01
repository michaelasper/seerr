SCHEME ?= Seerr
PROJECT ?= Seerr.xcodeproj
DESTINATION ?= platform=iOS Simulator,name=iPhone 17 Pro
CONFIGURATION ?= Debug
ENV_FILE ?= Seerr/Resources/.env.local

.PHONY: build test ui-test clean

define LOAD_ENV
if [ -f $(ENV_FILE) ]; then \
	echo "Loading $(ENV_FILE)"; \
	set -a; \
	. $(ENV_FILE); \
	set +a; \
fi;
endef

build:
	@bash -lc '$(LOAD_ENV) xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '"'"'$(DESTINATION)'"'"' build'

test:
	@bash -lc '$(LOAD_ENV) xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '"'"'$(DESTINATION)'"'"' test'

ui-test:
	@bash -lc '$(LOAD_ENV) xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '"'"'$(DESTINATION)'"'"' test -only-testing:SeerrUITests'

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
