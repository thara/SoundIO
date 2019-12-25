import CSoundIO
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
    outstream.format = .float32LE
    outstream.writeCallback { (outstream, frameCountMin, frameCountMax) in
        let layout = outstream.layout
        let secondsPerFrame = 1.0 / Float(outstream.sampleRate)
        var areas: UnsafeMutablePointer<SoundIoChannelArea>? = nil
        var framesLeft = frameCountMax

        while 0 < framesLeft {
            var frameCount = framesLeft

            do {
                try outstream.withInternalPointer {
                    try soundio_outstream_begin_write($0, &areas, &frameCount).ensureSuccess()
                }
            } catch let error {
                fatalError("\(error)")
            }

            if frameCount == 0 {
                break
            }

            let pitch: Float = 440.0
            let radiansPerSecond = pitch * 2.0 * .pi

            for frame in 0..<frameCount {
                let sample = sin((secondsOffset + Float(frame) * secondsPerFrame) * radiansPerSecond)
                if frame == 100 {
                    print("\(secondsOffset) \(frame) \(secondsPerFrame) \(radiansPerSecond) \(sample)")
                }
                for channel in 0..<layout.channelCount {
                    if let a = areas?[Int(channel)] {
                        let p: UnsafeMutablePointer<Int8> = a.ptr + Int(a.step * frame)
                        p.withMemoryRebound(to: Float.self, capacity: 1) {
                            $0.pointee = sample
                        }
                    }
                }
            }
            secondsOffset = (secondsOffset + secondsPerFrame * Float(frameCount)).truncatingRemainder(dividingBy: 1)

            do {
                try outstream.withInternalPointer {
                    try soundio_outstream_end_write($0).ensureSuccess()
                }
            } catch let error {
                fatalError("\(error)")
            }

            framesLeft -= frameCount
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

