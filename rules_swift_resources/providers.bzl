# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Providers for SwiftResources."""

SwiftResourceInfo = provider(
    doc = "Exposes resource module info for tooling integration.",
    fields = {
        "module_name": "Name of the resource module.",
        "resources": "Depset of resource files (fonts, images, files).",
        "generated_source": "The generated Swift source file.",
    },
)
