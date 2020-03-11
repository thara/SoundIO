# SoundIO

![Github Status](https://github.com/thara/SoundIO/workflows/Swift/badge.svg)

A Swift wrapper for [libsoundio](https://github.com/andrewrk/libsoundio), a cross-platform real-time audio input and output library.

## Requirements

- libsoundio

## Installation

```swift
    dependencies: [
        .package(url: "https://github.com/thara/SoundIO.git", from: "0.3.2"),
    ]
```

## Example

The following emits a sine wave over the default device using the best backend.   
It means as same as [libsoundio's synopsis](https://github.com/andrewrk/libsoundio#synopsis).

```swift
import Foundation
import SoundIO

var secondsOffset: Float = 0.0

func main() throws {
    let soundio = try SoundIO()
    try soundio.connect()
    soundio.flushEvents()

    let outputDeviceIndex = try soundio.defaultOutputDeviceIndex()
    let device = try soundio.getOutputDevice(at: outputDeviceIndex)
    print("Output device: \(device.name)")

    let outstream = try OutStream(to: device)
    outstream.format = .float32bitLittleEndian
    outstream.writeCallback { (outstream, frameCountMin, frameCountMax) in
        let layout = outstream.layout
        let secondsPerFrame = 1.0 / Float(outstream.sampleRate)

        try! outstream.write(frameCount: frameCountMax) { (areas, frameCount) in
            let pitch: Float = 440.0
            let radiansPerSecond = pitch * 2.0 * .pi
            for frame in 0..<frameCount {
                let sample = sin((secondsOffset + Float(frame) * secondsPerFrame) * radiansPerSecond)
                for area in areas.iterate(over: layout.channelCount) {
                    area.write(sample, stepBy: frame)
                }
            }
            secondsOffset = (secondsOffset + secondsPerFrame * Float(frameCount)).truncatingRemainder(dividingBy: 1)
        }
    }

    try outstream.open()
    try outstream.start()

    while true {
        soundio.waitEvents()
    }
}

do {
    try main()
} catch let error as SoundIOError {
    print("Error: \(error)")
    exit(EXIT_FAILURE)
}
```

This code is located in `Sources/SoundIODemo/main.swift`.
You can run it by using `make demo`.

### Notes

You haven't need to call any `**_destroy` functions because the wrapper calls each of `**_destroy` functions in `deinit` and destroyed out of scopes properly.

## TODO

- [ ] Add documentation
- [ ] Support error callbacks in `OutStream`
- [ ] Add examples
- [ ] Test other platforms except macOS

## Author

*Tomochika Hara* - [thara](https://github.com/thara)

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details

## Acknowledgments

- [libsoundio](https://github.com/andrewrk/libsoundio)
- [rsoundio](https://github.com/klingtnet/rsoundio)
  - This has gaven me an idea to keep callback functions in stream's userdata.
