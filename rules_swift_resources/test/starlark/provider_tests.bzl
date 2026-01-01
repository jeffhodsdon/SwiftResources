# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Analysis tests for SwiftResourceInfo provider."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//rules_swift_resources:providers.bzl", "SwiftResourceInfo")

# =============================================================================
# Test: SwiftResourceInfo has generated_source populated
# =============================================================================

def _generated_source_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    # Check SwiftResourceInfo is present
    asserts.true(env, SwiftResourceInfo in target, "Target should have SwiftResourceInfo")

    info = target[SwiftResourceInfo]

    # Check generated_source is populated
    asserts.true(
        env,
        info.generated_source != None,
        "SwiftResourceInfo.generated_source should not be None",
    )

    # Check it's a .swift file
    asserts.true(
        env,
        info.generated_source.path.endswith(".swift"),
        "generated_source should be a .swift file",
    )

    # Check module_name is set
    asserts.equals(env, "CompiledResources", info.module_name)

    return analysistest.end(env)

generated_source_test = analysistest.make(_generated_source_test_impl)

# =============================================================================
# Test suite setup
# =============================================================================

def provider_test_suite(name):
    """Create the test suite for SwiftResourceInfo provider tests.

    Args:
        name: The name of the test suite
    """
    generated_source_test(
        name = "generated_source_test",
        target_under_test = "//rules_swift_resources/test/integration:compiled_resources",
    )

    native.test_suite(
        name = name,
        tests = [
            ":generated_source_test",
        ],
    )
