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
        let secondsPerFrame = 1.0 / Float(outstream.sampleRate)
        var writer = OutStreamWriter(frameCount: frameCountMax)
        do {
            try writer.write(to: outstream) { (areas, frameCount) in
                let pitch: Float = 440.0
                let radiansPerSecond = pitch * 2.0 * .pi

                for frame in 0..<frameCount {
                    let sample = sin((secondsOffset + Float(frame) * secondsPerFrame) * radiansPerSecond)
                    if frame == 100 {
                        print("\(secondsOffset) \(frame) \(secondsPerFrame) \(radiansPerSecond) \(sample)")
                    }
                    for area in areas {
                        area.write(sample, stepBy: frame)
                    }
                }
                secondsOffset = (secondsOffset + secondsPerFrame * Float(frameCount)).truncatingRemainder(dividingBy: 1)
            }
        } catch let error {
            fatalError("\(error)")
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

