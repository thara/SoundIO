import CSoundIO
import SoundIO

func soundioError(_ errorCode: Int32) -> String {
    return String(cString: soundio_strerror(errorCode))
}

var secondsOffset: Float = 0.0

func writeCallback(outstream: UnsafeMutablePointer<SoundIoOutStream>?, frameCountMin: Int32, frameCountMax: Int32) {
    guard let o = outstream else { return }

    let layout: SoundIoChannelLayout = o.pointee.layout
    let secondsPerFrame = 1.0 / Float(o.pointee.sample_rate)
    var areas: UnsafeMutablePointer<SoundIoChannelArea>? = nil
    var framesLeft = frameCountMax

    while 0 < framesLeft {
        var frameCount = framesLeft

        do {
            try soundio_outstream_begin_write(outstream, &areas, &frameCount).ensureSuccess()
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
            for channel in 0..<layout.channel_count {
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
            try soundio_outstream_end_write(outstream).ensureSuccess()
        } catch let error {
            fatalError("\(error)")
        }

        framesLeft -= frameCount
    }
}

func main() throws {
    let soundio = try SoundIO()
    try soundio.connect()
    soundio.flushEvents()

    let outputDeviceIndex = try soundio.defaultOutputDeviceIndex()
    let device = try soundio.getOutputDevice(at: outputDeviceIndex)
    let deviceName = String(cString: device.pointee.name)
    print("Output device: \(deviceName)")

    let outstream = try soundio_outstream_create(device).ensureAllocatedMemory()
    outstream.pointee.format = SoundIoFormatFloat32LE;
    outstream.pointee.write_callback = writeCallback;

    try soundio_outstream_open(outstream).ensureSuccess()
    try outstream.pointee.layout_error.ensureSuccess()
    try soundio_outstream_start(outstream).ensureSuccess()

    while true {
        soundio.waitEvents()
        // try soundio.withInternalPointer {
        //     soundio_wait_events($0)
        // }
    }

    soundio_outstream_destroy(outstream)
    soundio_device_unref(device)
}

do {
    try main()
} catch let error as SoundIOError {
    print("Error: \(error)")
    exit(EXIT_FAILURE)
}

