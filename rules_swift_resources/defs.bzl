# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Bazel rules for SwiftResources."""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("@rules_swift//swift:swift.bzl", "SwiftInfo", "swift_library")
load(":providers.bzl", "SwiftResourceInfo")

# -----------------------------------------------------------------------------
# swift_resources: top-level rule exposing SwiftResourceInfo for tooling
# -----------------------------------------------------------------------------

def _swift_resources_impl(ctx):
    """Forwards providers from inner swift_library and adds SwiftResourceInfo."""
    resource_files = ctx.files.fonts + ctx.files.images + ctx.files.files + ctx.files.xcassets + ctx.files.strings

    inner = ctx.attr.inner_lib
    return [
        SwiftResourceInfo(
            module_name = ctx.attr.module_name,
            resources = depset(resource_files),
        ),
        inner[SwiftInfo],
        inner[CcInfo],
        inner[DefaultInfo],
    ]

swift_resources = rule(
    implementation = _swift_resources_impl,
    attrs = {
        "files": attr.label_list(allow_files = True),
        "fonts": attr.label_list(allow_files = True),
        "images": attr.label_list(allow_files = True),
        "xcassets": attr.label_list(allow_files = True),
        "strings": attr.label_list(allow_files = True),
        "inner_lib": attr.label(
            mandatory = True,
            providers = [SwiftInfo],
            doc = "The inner swift_library target",
        ),
        "module_name": attr.string(mandatory = True),
    },
    doc = "Swift resources module. Provides SwiftResourceInfo for tooling integration.",
)

def _swift_resources_generate_impl(ctx):
    """Implementation of swift_resources_generate rule."""
    output = ctx.outputs.out

    # Build arguments
    args = ctx.actions.args()
    args.add("generate")

    # Add individual font files
    if ctx.files.fonts:
        args.add("--font-file")
        for f in ctx.files.fonts:
            args.add(f.path)

    # Add individual image files
    if ctx.files.images:
        args.add("--image-file")
        for f in ctx.files.images:
            args.add(f.path)

    # Add individual files
    if ctx.files.files:
        args.add("--file-path")
        for f in ctx.files.files:
            args.add(f.path)

    # Add xcassets directories
    if ctx.files.xcassets:
        args.add("--xcassets")
        for f in ctx.files.xcassets:
            args.add(f.path)

    # Add string files (.xcstrings or .strings)
    if ctx.files.strings:
        args.add("--strings")
        for f in ctx.files.strings:
            args.add(f.path)

    if ctx.attr.development_region:
        args.add("--development-region", ctx.attr.development_region)

    args.add("--output", output)
    args.add("--module-name", ctx.attr.module_name)
    args.add("--access-level", ctx.attr.access_level)

    if ctx.attr.bundle:
        args.add("--bundle", ctx.attr.bundle)

    if not ctx.attr.register_fonts:
        args.add("--no-register-fonts")

    if ctx.attr.force_unwrap:
        args.add("--force-unwrap")

    # Run the generator
    ctx.actions.run(
        inputs = ctx.files.fonts + ctx.files.images + ctx.files.files + ctx.files.xcassets + ctx.files.strings,
        outputs = [output],
        executable = ctx.executable._generator,
        arguments = [args],
        mnemonic = "SwiftResourcesGenerate",
        progress_message = "Generating Swift resources: %s" % output.short_path,
    )

    return [
        DefaultInfo(files = depset([output])),
    ]

swift_resources_generate = rule(
    implementation = _swift_resources_generate_impl,
    attrs = {
        "fonts": attr.label_list(
            allow_files = [".ttf", ".otf"],
            doc = "Font files (.ttf, .otf)",
        ),
        "images": attr.label_list(
            allow_files = [".png", ".jpg", ".jpeg", ".pdf", ".svg", ".heic"],
            doc = "Image files",
        ),
        "files": attr.label_list(
            allow_files = True,
            doc = "Arbitrary files",
        ),
        "xcassets": attr.label_list(
            allow_files = [".xcassets"],
            doc = "Asset catalog directories (.xcassets)",
        ),
        "strings": attr.label_list(
            allow_files = [".xcstrings", ".strings"],
            doc = "String catalogs (.xcstrings) or legacy .strings files",
        ),
        "development_region": attr.string(
            doc = "Source language for .strings files (auto-detected for .xcstrings)",
        ),
        "module_name": attr.string(
            default = "Resources",
            doc = "Name of the generated enum namespace",
        ),
        "access_level": attr.string(
            default = "internal",
            values = ["public", "internal"],
            doc = "Access level for generated code",
        ),
        "bundle": attr.string(
            doc = "Bundle expression (e.g., '.module', '.main'). Default: auto-detect via BundleFinder",
        ),
        "register_fonts": attr.bool(
            default = True,
            doc = "Generate registerFonts() function",
        ),
        "force_unwrap": attr.bool(
            default = False,
            doc = "Generate non-optional accessors with force unwrap",
        ),
        "out": attr.output(
            mandatory = True,
            doc = "Output Swift file",
        ),
        "_generator": attr.label(
            default = "@rules_swift_resources//:sr",
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Generates Swift code for type-safe resource access.",
)

def swift_resources_library(
        name,
        fonts = [],
        images = [],
        files = [],
        xcassets = [],
        strings = [],
        development_region = None,
        module_name = "Resources",
        access_level = "internal",
        bundle = None,
        register_fonts = True,
        force_unwrap = False,
        deps = [],
        visibility = None,
        tags = [],
        testonly = False):
    """Generates a Swift module with type-safe resource accessors.

    Creates four targets:

    - {name}_gen (swift_resources_generate):
        Runs the `sr` CLI to generate Swift code with type-safe accessors
        for fonts, images, colors, files, and strings.

    - {name}_lib (swift_library):
        Compiles the generated Swift code. Private visibility; not intended
        for direct use.

    - {name} (swift_resources):
        The primary target to depend on. Forwards SwiftInfo, CcInfo, and
        DefaultInfo from the inner library. Also provides SwiftResourceInfo
        for tooling integration (e.g., rules_swift_previews).

    - {name}.resources (filegroup):
        All resource files bundled together. Pass to ios_application's
        `resources` attribute for runtime bundling.

    Example:
        swift_resources_library(
            name = "DesignSystemResources",
            fonts = glob(["Fonts/**/*.ttf"]),
            images = glob(["Images/**/*.png"]),
            module_name = "DesignSystem",
        )

        # Depend on the module
        swift_library(
            deps = [":DesignSystemResources"],
        )

        # Bundle resources in app
        ios_application(
            resources = [":DesignSystemResources.resources"],
        )

    Args:
        name: Target name.
        fonts: Font files (.ttf, .otf).
        images: Image files (.png, .jpg, .pdf, .svg, .heic).
        files: Arbitrary files.
        xcassets: Asset catalog directories (.xcassets).
        strings: String catalogs (.xcstrings) or legacy .strings files.
        development_region: Source language for .strings files (auto-detected for .xcstrings).
        module_name: Generated enum namespace (default: "Resources").
        access_level: "public" or "internal" (default: "internal").
        bundle: Bundle expression (e.g., ".module", ".main"). Default: auto-detect.
        register_fonts: Generate registerFonts() function (default: True).
        force_unwrap: Generate non-optional accessors with force unwrap (default: False).
        deps: Additional Swift dependencies.
        visibility: Target visibility.
        tags: Target tags.
        testonly: Test-only target.
    """
    gen_name = name + "_gen"
    gen_out = name + ".swift"

    swift_resources_generate(
        name = gen_name,
        fonts = fonts,
        images = images,
        files = files,
        xcassets = xcassets,
        strings = strings,
        development_region = development_region,
        module_name = module_name,
        access_level = access_level,
        bundle = bundle,
        register_fonts = register_fonts,
        force_unwrap = force_unwrap,
        out = gen_out,
        tags = tags,
        testonly = testonly,
    )

    all_resources = fonts + images + files + xcassets + strings
    inner_name = name + "_lib"

    swift_library(
        name = inner_name,
        srcs = [":" + gen_name],
        module_name = module_name,
        deps = deps,
        data = all_resources,
        visibility = ["//visibility:private"],
        tags = tags,
        testonly = testonly,
    )

    swift_resources(
        name = name,
        files = files,
        fonts = fonts,
        images = images,
        xcassets = xcassets,
        strings = strings,
        inner_lib = ":" + inner_name,
        module_name = module_name,
        visibility = visibility,
    )

    # Filegroup for ios_application resources attribute
    # Use: resources = [":MyResources.resources"]
    if all_resources:
        native.filegroup(
            name = name + ".resources",
            srcs = all_resources,
            visibility = visibility,
            tags = tags,
            testonly = testonly,
        )
