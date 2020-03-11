import CSoundIO

public class InStream {

    public typealias ReadCallback = (_ instream: InStream, _ frameCountMin: Int32, _ frameCountMax: Int32) -> Void

    class Callbacks {
        var onRead: ReadCallback?
    }

    private let internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoInStream>

    private var callbacks = Callbacks()
    // The flag is set by the callback function to prevent the internal pointer destroyed after the callback
    private var temporary: Bool = false

    init(internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoInStream>) {
        self.internalPointer = internalPointer
    }

    public init(from device: Device) throws {
        self.internalPointer = try soundio_instream_create(device.internalPointer).ensureAllocatedMemory()
    }

    deinit {
        if temporary {
            temporary = false
        } else {
            soundio_instream_destroy(internalPointer)
        }
    }
}

// MARK: - Accessor
extension InStream {

    public var bytesPerFrame: Int32 {
        internalPointer.pointee.bytes_per_frame
    }

    public var bytesPerSample: Int32 {
        internalPointer.pointee.bytes_per_sample
    }

    public var format: Format {
        get {
            Format(rawValue: internalPointer.pointee.format)
        }
        set {
            internalPointer.pointee.format = newValue.rawValue
        }
    }

    public var sampleRate: Int32 {
        get {
            self.internalPointer.pointee.sample_rate
        }
        set {
            internalPointer.pointee.sample_rate = newValue
        }
    }

    public var layout: ChannelLayout {
        get {
            ChannelLayout(internalPointer: &internalPointer.pointee.layout)
        }
        set {
            internalPointer.pointee.layout = newValue.internalPointer.pointee
        }
    }

    public var softwareLatency: Double {
        get {
            internalPointer.pointee.software_latency
        }
        set {
            internalPointer.pointee.software_latency = newValue
        }
    }
}

// MARK: - Read operation
extension InStream {
    public func open() throws {
        try soundio_instream_open(internalPointer).ensureSuccess()
    }

    public func start() throws {
        try soundio_instream_start(internalPointer).ensureSuccess()
    }

    public func readCallback(_ callback: @escaping ReadCallback) {
        self.callbacks.onRead = callback

        self.internalPointer.pointee.userdata = Unmanaged<InStream.Callbacks>.passRetained(self.callbacks).toOpaque()
        self.internalPointer.pointee.read_callback = {(instream, frameCountMin, frameCountMax) in
            guard let pointer = instream else { return }

            let out = InStream(internalPointer: pointer)
            out.temporary = true

            let callbacks = Unmanaged<InStream.Callbacks>.fromOpaque(pointer.pointee.userdata).takeUnretainedValue()
            callbacks.onRead?(out, frameCountMin, frameCountMax)
        }
    }
}

// MARK: - Operations in callback
extension InStream {

    public func beginRead(areas: inout UnsafeMutablePointer<SoundIoChannelArea>?, frameCount: inout Int32) throws {
        try soundio_instream_begin_read(internalPointer, &areas, &frameCount).ensureSuccess()
    }

    public func endRead() throws {
        try soundio_instream_end_read(internalPointer).ensureSuccess()
    }

    public func read(frameCount: Int32, _ task: (ChannelAreaList?, Int32) throws -> Void) throws {
        var areas: ChannelAreaList?
        var framesLeft = frameCount

        while 0 < framesLeft {
            var actualFrameCount = framesLeft
            try beginRead(areas: &areas, frameCount: &actualFrameCount)

            if actualFrameCount == 0 {
                break
            }

            try task(areas, actualFrameCount)
            try endRead()

            framesLeft -= frameCount
        }
    }
}
