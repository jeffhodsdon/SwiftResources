# SwiftResources Makefile

.PHONY: test test-swift test-bazel build clean

test: test-swift test-bazel

test-swift:
	swift test

test-bazel:
	bazel test //swift_resources/test:all_tests

build:
	swift build

clean:
	swift package clean
	bazel clean
