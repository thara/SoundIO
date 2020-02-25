import CSoundIO

public class OutStream {

    public typealias WriteCallback = (_ outstream: OutStream, _ frameCountMin: Int32, _ frameCountMax: Int32) -> Void
    public typealias UnderflowCallback = (_ outstream: OutStream) -> Void

    class Callbacks {
        var onWrite: WriteCallback?
        var onUnderflow: UnderflowCallback?
    }

    private let internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoOutStream>
    private var callbacks = Callbacks()

    // The flag is set by the callback function to prevent the internal pointer destroyed after the callback
    private var temporary: Bool = false

    deinit {
        if temporary {
            temporary = false
        } else {
            soundio_outstream_destroy(internalPointer)
        }
    }

    init(internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoOutStream>) {
        self.internalPointer = internalPointer
    }

    public init(to device: Device) throws {
        self.internalPointer = try soundio_outstream_create(device.internalPointer).ensureAllocatedMemory()
        self.internalPointer.pointee.userdata = Unmanaged<OutStream.Callbacks>.passRetained(self.callbacks).toOpaque()
    }

    public var format: Format {
        get {
            return Format(rawValue: internalPointer.pointee.format)
        }
        set {
            internalPointer.pointee.format = newValue.rawValue
        }
    }

    public func writeCallback(_ callback: @escaping WriteCallback) {
        self.callbacks.onWrite = callback

        self.internalPointer.pointee.write_callback = {(outstream, frameCountMin, frameCountMax) in
            guard let pointer = outstream else { return }

            let out = OutStream(internalPointer: pointer)
            out.temporary = true

            let callbacks = Unmanaged<OutStream.Callbacks>.fromOpaque(pointer.pointee.userdata).takeUnretainedValue()
            callbacks.onWrite?(out, frameCountMin, frameCountMax)
        }
    }

    public func underflowCallback(_ callback: @escaping UnderflowCallback) {
        self.callbacks.onUnderflow = callback

        self.internalPointer.pointee.underflow_callback = {(outstream) in
            guard let pointer = outstream else { return }

            let out = OutStream(internalPointer: pointer)
            out.temporary = true

            let callbacks = Unmanaged<OutStream.Callbacks>.fromOpaque(pointer.pointee.userdata).takeUnretainedValue()
            callbacks.onUnderflow?(out)
        }
    }

    public func open() throws {
        try soundio_outstream_open(internalPointer).ensureSuccess()
        try internalPointer.pointee.layout_error.ensureSuccess()
    }

    public func start() throws {
        try soundio_outstream_start(internalPointer).ensureSuccess()
    }

    public func withInternalPointer<T>(
        _ unsafeTask: (_ pointer: UnsafeMutablePointer<CSoundIO.SoundIoOutStream>) throws -> T) throws -> T {
        return try unsafeTask(self.internalPointer)
    }

    public var bytesPerFrame: Int32 {
        return internalPointer.pointee.bytes_per_frame
    }

    public var layout: ChannelLayout {
        get {
            return ChannelLayout(internalPointer: &self.internalPointer.pointee.layout)
        }
        set {
            internalPointer.pointee.layout = newValue.internalPointer.pointee
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

    public var softwareLatency: Double {
        get {
            internalPointer.pointee.software_latency
        }
        set {
            internalPointer.pointee.software_latency = newValue
        }
    }

    public func beginWrite(areas: inout UnsafeMutablePointer<SoundIoChannelArea>?, frameCount: inout Int32) throws {
        try soundio_outstream_begin_write(internalPointer, &areas, &frameCount).ensureSuccess()
    }

    public func endWrite() throws {
        try soundio_outstream_end_write(internalPointer).ensureSuccess()
    }

    public func write(frameCount: Int32, _ task: (ChannelAreaList?, Int32) throws -> Void) throws {
        var areas: ChannelAreaList?
        var framesLeft = frameCount

        while 0 < framesLeft {
            var actualFrameCount = framesLeft
            try beginWrite(areas: &areas, frameCount: &actualFrameCount)

            if actualFrameCount == 0 {
                break
            }

            try task(areas, actualFrameCount)
            try endWrite()

            framesLeft -= frameCount
        }
    }
}
