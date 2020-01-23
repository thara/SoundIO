.PHONY: lint build demo-sine demo-listdevices help

.DEFAULT_GOAL := build

lint:  ## Run lint
	@swiftlint autocorrect -- && swiftlint

build:  ## Build all
	@swift build -v -Xlinker -L/usr/local/lib

demo-sine:  ## Run sine demo
	@swift run -v -Xlinker -L/usr/local/lib soundiodemo-sine

demo-listdevices:  ## Run listing devices demo
	@swift run -Xlinker -L/usr/local/lib soundiodemo-listdevices $(OPT)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
