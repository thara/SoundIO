import CSoundIO

public class OutStream {

    public typealias WriteCallback = (_ outstream: OutStream, _ frameCountMin: Int32, _ frameCountMax: Int32) -> Void

    class Callbacks {
        var onWrite: WriteCallback?
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

        self.internalPointer.pointee.userdata = Unmanaged<OutStream.Callbacks>.passRetained(self.callbacks).toOpaque()
        self.internalPointer.pointee.write_callback = {(outstream, frameCountMin, frameCountMax) in
            guard let pointer = outstream else { return }

            let out = OutStream(internalPointer: pointer)
            out.temporary = true

            let callbacks = Unmanaged<OutStream.Callbacks>.fromOpaque(pointer.pointee.userdata).takeUnretainedValue()
            callbacks.onWrite?(out, frameCountMin, frameCountMax)
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

    public var layout: ChannelLayout {
        let pointer = withUnsafeMutablePointer(to: &self.internalPointer.pointee.layout) {
            UnsafeMutablePointer($0)
        }
        return ChannelLayout(internalPointer: pointer)
    }

    public var sampleRate: UInt {
        return UInt(self.internalPointer.pointee.sample_rate)
    }

    public func beginWrite(areas: inout UnsafeMutablePointer<SoundIoChannelArea>?, frameCount: inout Int32) throws {
        try soundio_outstream_begin_write(internalPointer, &areas, &frameCount).ensureSuccess()
    }

    public func endWrite() throws {
        try soundio_outstream_end_write(internalPointer).ensureSuccess()
    }

    public func write(frameCount: Int32, _ task: (ChannelAreaList, Int32) throws -> Void) throws {
        var areas: ChannelAreaList = nil
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
