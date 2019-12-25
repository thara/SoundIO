import CSoundIO

public typealias DeviceIndex = Int32

public class SoundIO {
    private let internalPointer: UnsafeMutablePointer<CSoundIO.SoundIo>

    deinit {
        soundio_destroy(internalPointer)
    }

    public init() throws {
        self.internalPointer = try soundio_create().ensureAllocatedMemory()
    }

    public func connect() throws {
        try soundio_connect(self.internalPointer).ensureSuccess()
    }

    public func flushEvents() {
        soundio_flush_events(self.internalPointer)
    }

    public func waitEvents() {
        soundio_wait_events(self.internalPointer)
    }

    public func defaultOutputDeviceIndex() throws -> DeviceIndex {
        let index = soundio_default_output_device_index(self.internalPointer)
        guard 0 <= index else {
            throw SoundIOError(message: "No output device found")
        }
        return DeviceIndex(index)
    }

    public func getOutputDevice(at index: DeviceIndex) throws -> Device {
        guard let device = soundio_get_output_device(self.internalPointer, index) else {
            throw SoundIOError(message: "invalid parameter value")
        }
        return Device(internalPointer: device)
    }

    public func withInternalPointer(
        _ unsafeTask: (_ pointer: UnsafeMutablePointer<CSoundIO.SoundIo>) throws -> Void) throws {
        try unsafeTask(self.internalPointer)
    }
}

public class Device {
    fileprivate let internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoDevice>

    deinit {
        soundio_device_unref(internalPointer)
    }

    init(internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoDevice>) {
        self.internalPointer = internalPointer
    }

    public var name: String {
        return String(cString: self.internalPointer.pointee.name)
    }

    public func withInternalPointer<T>(
        _ unsafeTask: (_ pointer: UnsafeMutablePointer<CSoundIO.SoundIoDevice>) throws -> T) throws -> T {
        return try unsafeTask(self.internalPointer)
    }
}

public class OutStream {

    public typealias WriteCallback = (_ outstream: OutStream, _ frameCountMin: Int32, _ frameCountMax: Int32) -> Void

    class Callbacks {
        var onWrite: WriteCallback?
    }

    private let internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoOutStream>
    private var callbacks = Callbacks()

    // The flag is set by the callback function to prevent the internal pointer destroyed after the callback
    fileprivate var temporary: Bool = false

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
        return ChannelLayout(owner: self.internalPointer)
    }

    public var sampleRate: UInt {
        return UInt(self.internalPointer.pointee.sample_rate)
    }
}

public struct ChannelLayout {
    fileprivate let owner: UnsafeMutablePointer<CSoundIO.SoundIoOutStream>

    public var name: String {
        return String(cString: owner.pointee.layout.name)
    }

    public var channelCount: UInt {
        return UInt(owner.pointee.layout.channel_count)
    }
}

public struct Format {
    fileprivate let rawValue: SoundIoFormat

    public static let invalid = Format(rawValue: CSoundIO.SoundIoFormatInvalid)
    public static let s8 = Format(rawValue: CSoundIO.SoundIoFormatS8)
    public static let u8 = Format(rawValue: CSoundIO.SoundIoFormatU8)
    public static let s16LE = Format(rawValue: CSoundIO.SoundIoFormatS16LE)
    public static let s16BE = Format(rawValue: CSoundIO.SoundIoFormatS16BE)
    public static let u16LE = Format(rawValue: CSoundIO.SoundIoFormatU16LE)
    public static let u16BE = Format(rawValue: CSoundIO.SoundIoFormatU16BE)
    public static let s24LE = Format(rawValue: CSoundIO.SoundIoFormatS24LE)
    public static let s24BE = Format(rawValue: CSoundIO.SoundIoFormatS24BE)
    public static let u24LE = Format(rawValue: CSoundIO.SoundIoFormatU24LE)
    public static let u24BE = Format(rawValue: CSoundIO.SoundIoFormatU24BE)
    public static let s32LE = Format(rawValue: CSoundIO.SoundIoFormatS32LE)
    public static let s32BE = Format(rawValue: CSoundIO.SoundIoFormatS32BE)
    public static let u32LE = Format(rawValue: CSoundIO.SoundIoFormatU32LE)
    public static let u32BE = Format(rawValue: CSoundIO.SoundIoFormatU32BE)
    public static let float32LE = Format(rawValue: CSoundIO.SoundIoFormatFloat32LE)
    public static let float32BE = Format(rawValue: CSoundIO.SoundIoFormatFloat32BE)
    public static let float64LE = Format(rawValue: CSoundIO.SoundIoFormatFloat64LE)
    public static let float64BE = Format(rawValue: CSoundIO.SoundIoFormatFloat64BE)
}
