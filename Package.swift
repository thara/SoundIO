// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SoundIO",
    products: [
        .library(
            name: "SoundIO",
            targets: ["SoundIO"]),
        .executable(
            name: "soundiodemo-sine",
            targets: ["SoundIODemo-Sine"]),
        .executable(
            name: "soundiodemo-listdevices",
            targets: ["SoundIODemo-ListDevices"]),
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
            name: "SoundIODemo-Sine",
            dependencies: ["SoundIO", "CSoundIO"],
            path: "Sources/SoundIODemo/sine/"),
        .target(
            name: "SoundIODemo-ListDevices",
            dependencies: ["SoundIO", "CSoundIO"],
            path: "Sources/SoundIODemo/list_devices/"),
    ]
)
