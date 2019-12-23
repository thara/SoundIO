// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SoundIO",
    products: [
        .library(
            name: "SoundIO",
            targets: ["SoundIO"]),
        .executable(
            name: "SoundIODemo",
            targets: ["SoundIODemo"]),
    ],
    targets: [
        .systemLibrary(
            name: "CSoundIO",
            // pkgConfig: "soundio",
            // pkgConfig: "libsoundio",
            providers: [.brew(["soundio"])]
        ),
        .target(
            name: "SoundIO",
            dependencies: ["CSoundIO"]),
        .target(
            name: "SoundIODemo",
            dependencies: ["SoundIO", "CSoundIO"]),
    ]
)
