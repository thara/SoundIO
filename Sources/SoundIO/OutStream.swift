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

    init(internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoOutStream>) {
        self.internalPointer = internalPointer
    }

    public init(to device: Device) throws {
        self.internalPointer = try soundio_outstream_create(device.internalPointer).ensureAllocatedMemory()
        self.internalPointer.pointee.userdata = Unmanaged<OutStream.Callbacks>.passRetained(self.callbacks).toOpaque()
    }

    deinit {
        if temporary {
            temporary = false
        } else {
            soundio_outstream_destroy(internalPointer)
        }
    }
}

// MARK: - Accessor
extension OutStream {

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
}

// MARK: - Write operation
extension OutStream {

    public func open() throws {
        try soundio_outstream_open(internalPointer).ensureSuccess()
        try internalPointer.pointee.layout_error.ensureSuccess()
    }

    public func start() throws {
        try soundio_outstream_start(internalPointer).ensureSuccess()
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
}

// MARK: - Operations in callback
extension OutStream {

    public func beginWriting(theNumberOf frameCount: inout Int32) throws -> ChannelAreaList? {
        var areas: ChannelAreaList?

        try soundio_outstream_begin_write(internalPointer, &areas, &frameCount).ensureSuccess()

        return areas
    }

    public func endWrite() throws {
        try soundio_outstream_end_write(internalPointer).ensureSuccess()
    }
}

// MARK: - Misc
extension OutStream {

    public func withInternalPointer<T>(
        _ unsafeTask: (_ pointer: UnsafeMutablePointer<CSoundIO.SoundIoOutStream>) throws -> T) throws -> T {
        return try unsafeTask(self.internalPointer)
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
}
