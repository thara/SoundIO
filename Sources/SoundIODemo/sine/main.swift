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
    outstream.writeCallback { (outstream, _, frameCountMax) in
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
