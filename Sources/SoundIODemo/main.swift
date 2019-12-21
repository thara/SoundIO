import CSoundIO

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
    var err: CInt = 0

    while 0 < framesLeft {
        var frameCount = framesLeft

        err = soundio_outstream_begin_write(outstream, &areas, &frameCount)
        if 0 < err {
            fatalError(soundioError(err))
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

        err = soundio_outstream_end_write(outstream)
        if 0 < err {
            fatalError(soundioError(err))
        }

        framesLeft -= frameCount
    }
}

func main() {
    guard let soundio: UnsafeMutablePointer<SoundIo> = soundio_create() else {
        fatalError("out of memory")
    }

    var err: CInt = soundio_connect(soundio)
    if 0 < err {
        fatalError("error connecting: \(soundioError(err))")
    }

    soundio_flush_events(soundio)

    let defaultOutDeviceIndex: CInt = soundio_default_output_device_index(soundio)
    if defaultOutDeviceIndex < 0 {
        fatalError("no output device found")
    }

    guard let device: UnsafeMutablePointer<SoundIoDevice> = soundio_get_output_device(soundio, defaultOutDeviceIndex) else {
        fatalError("out of memory")
    }

    let deviceName = String(cString: device.pointee.name)
    print("Output device: \(deviceName)")

    guard let outstream: UnsafeMutablePointer<SoundIoOutStream> = soundio_outstream_create(device) else {
        fatalError("out of memory")
    }
    outstream.pointee.format = SoundIoFormatFloat32LE;
    outstream.pointee.write_callback = writeCallback;

    err = soundio_outstream_open(outstream)
    if 0 < err {
        fatalError("unable to open device: \(soundioError(err))")
    }

    if 0 < outstream.pointee.layout_error {
        fatalError("unable to set channel layout: \(soundioError(outstream.pointee.layout_error))")
    }

    err = soundio_outstream_start(outstream)
    if 0 < err {
        fatalError("unable to start device: \(soundioError(err))")
    }

    while true {
        soundio_wait_events(soundio)
    }

    soundio_outstream_destroy(outstream)
    soundio_device_unref(device)
    soundio_destroy(soundio)
}

main()
