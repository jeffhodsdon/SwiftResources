# SwiftResources Makefile

.PHONY: test test-swift test-bazel build clean format

test: test-swift test-bazel

test-swift:
	swift test

test-bazel:
	bazel test //rules_swift_resources/test:all_tests

build:
	swift build

clean:
	swift package clean
	bazel clean

format:
	swiftformat ./Sources ./Tests
