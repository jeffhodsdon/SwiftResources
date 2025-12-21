# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Bazel rules for SwiftResources."""

load("@rules_swift//swift:swift.bzl", "swift_library")
load(":providers.bzl", "ResourceModuleInfo")

def _swift_resources_generate_impl(ctx):
    """Implementation of swift_resources_generate rule."""
    output = ctx.outputs.out

    # Build arguments
    args = ctx.actions.args()
    args.add("generate")

    # Add font directories
    font_dirs = {}
    for f in ctx.files.fonts:
        font_dirs[f.dirname] = True
    for d in font_dirs.keys():
        args.add("--fonts", d)

    # Add image directories
    image_dirs = {}
    for f in ctx.files.images:
        image_dirs[f.dirname] = True
    for d in image_dirs.keys():
        args.add("--images", d)

    # Add file directories
    file_dirs = {}
    for f in ctx.files.files:
        file_dirs[f.dirname] = True
    for d in file_dirs.keys():
        args.add("--files", d)

    args.add("--output", output)
    args.add("--module-name", ctx.attr.module_name)
    args.add("--access-level", ctx.attr.access_level)

    if ctx.attr.bundle:
        args.add("--bundle", ctx.attr.bundle)

    if not ctx.attr.register_fonts:
        args.add("--no-register-fonts")

    # Run the generator
    ctx.actions.run(
        inputs = ctx.files.fonts + ctx.files.images + ctx.files.files,
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
        "out": attr.output(
            mandatory = True,
            doc = "Output Swift file",
        ),
        "_generator": attr.label(
            default = "@swift_resources//:sr",
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
        module_name = "Resources",
        access_level = "internal",
        bundle = None,
        register_fonts = True,
        deps = [],
        visibility = None,
        tags = [],
        testonly = False):
    """High-level macro that generates Swift code, compiles it, and bundles resources.

    Args:
        name: Target name.
        fonts: List of font files (.ttf, .otf).
        images: List of image files.
        files: List of arbitrary files.
        module_name: Name of the generated enum namespace.
        access_level: Access level (public or internal).
        bundle: Bundle expression. Default: auto-detect via BundleFinder.
        register_fonts: Whether to generate registerFonts() function.
        deps: Additional Swift dependencies.
        visibility: Target visibility.
        tags: Target tags.
        testonly: Whether this is a test-only target.
    """
    gen_name = name + "_gen"
    gen_out = name + ".swift"

    # Generate Swift code
    swift_resources_generate(
        name = gen_name,
        fonts = fonts,
        images = images,
        files = files,
        module_name = module_name,
        access_level = access_level,
        bundle = bundle,
        register_fonts = register_fonts,
        out = gen_out,
        tags = tags,
        testonly = testonly,
    )

    # Compile Swift library
    all_resources = fonts + images + files

    swift_library(
        name = name,
        srcs = [":" + gen_name],
        module_name = module_name,
        deps = deps,
        data = all_resources,
        visibility = visibility,
        tags = tags,
        testonly = testonly,
    )
