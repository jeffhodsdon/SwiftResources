// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import ArgumentParser

@main
struct SR: ParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "sr",
        abstract: "SwiftResources — generate type-safe resource accessors",
        version: "0.1.0",
        subcommands: [GenerateCommand.self],
        defaultSubcommand: GenerateCommand.self
    )
}
