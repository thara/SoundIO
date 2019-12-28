.PHONY: lint build demo help

.DEFAULT_GOAL := build

lint:  ## Run lint
	@swiftlint autocorrect -- && swiftlint

build:  ## Build all
	@swift build -Xlinker -L/usr/local/lib

demo:  ## Run demo
	@swift run -Xlinker -L/usr/local/lib SoundIODemo

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
