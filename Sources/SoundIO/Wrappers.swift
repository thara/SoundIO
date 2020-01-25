import CSoundIO

public typealias DeviceIndex = Int32
public typealias ChannelId = CSoundIO.SoundIoChannelId

public class SoundIO {
    private let internalPointer: UnsafeMutablePointer<CSoundIO.SoundIo>

    fileprivate var temporary: Bool = false
    private var callbacks = Callbacks()

    public typealias DevicesChangeCallback = (_ soundio: SoundIO) -> Void

    class Callbacks {
        var onDevicesChange: DevicesChangeCallback?
    }

    deinit {
        if temporary {
            temporary = false
        } else {
            soundio_destroy(internalPointer)
        }
    }

    public init() throws {
        self.internalPointer = try soundio_create().ensureAllocatedMemory()
    }

    init(internalPointer: UnsafeMutablePointer<CSoundIO.SoundIo>) {
        self.internalPointer = internalPointer
    }

    public func connect() throws {
        try soundio_connect(self.internalPointer).ensureSuccess()
    }

    public func connect(to backend: Backend) throws {
        try soundio_connect_backend(self.internalPointer, backend.rawValue).ensureSuccess()
    }

    public func flushEvents() {
        soundio_flush_events(self.internalPointer)
    }

    public func waitEvents() {
        soundio_wait_events(self.internalPointer)
    }

    public func inputDeviceCount() throws -> Int32 {
        let result = soundio_input_device_count(self.internalPointer)
        if result == -1 {
            throw SoundIOError(message: "flushEvents must be called before calling inputDeviceCount")
        }
        return result
    }

    public func outputDeviceCount() throws -> Int32 {
        let result = soundio_output_device_count(self.internalPointer)
        if result == -1 {
            throw SoundIOError(message: "flushEvents must be called before calling outputDeviceCount")
        }
        return result
    }

    public func defaultInputDeviceIndex() throws -> DeviceIndex {
        let index = soundio_default_input_device_index(self.internalPointer)
        guard 0 <= index else {
            throw SoundIOError(message: "No input device found")
        }
        return DeviceIndex(index)
    }

    public func defaultOutputDeviceIndex() throws -> DeviceIndex {
        let index = soundio_default_output_device_index(self.internalPointer)
        guard 0 <= index else {
            throw SoundIOError(message: "No output device found")
        }
        return DeviceIndex(index)
    }

    public func getInputDevice(at index: DeviceIndex) throws -> Device {
        guard let device = soundio_get_input_device(self.internalPointer, index) else {
            throw SoundIOError(message: "invalid parameter value")
        }
        return Device(internalPointer: device)
    }

    public func getOutputDevice(at index: DeviceIndex) throws -> Device {
        guard let device = soundio_get_output_device(self.internalPointer, index) else {
            throw SoundIOError(message: "invalid parameter value")
        }
        return Device(internalPointer: device)
    }

    public func onDevicesChange(_ callback: @escaping DevicesChangeCallback) {
        self.callbacks.onDevicesChange = callback

        self.internalPointer.pointee.userdata = Unmanaged<Callbacks>.passRetained(self.callbacks).toOpaque()
        self.internalPointer.pointee.on_devices_change = {soundio in
            guard let pointer = soundio else { return }

            let out = SoundIO(internalPointer: pointer)
            out.temporary = true

            let callbacks = Unmanaged<Callbacks>.fromOpaque(pointer.pointee.userdata).takeUnretainedValue()
            callbacks.onDevicesChange?(out)
        }
    }

    public func withInternalPointer(
        _ unsafeTask: (_ pointer: UnsafeMutablePointer<CSoundIO.SoundIo>) throws -> Void) throws {
        try unsafeTask(self.internalPointer)
    }
}

public struct Backend: Equatable {
    fileprivate let rawValue: SoundIoBackend

    public static let none = Backend(rawValue: CSoundIO.SoundIoBackendNone)

    public static let jack = Backend(rawValue: CSoundIO.SoundIoBackendJack)
    public static let pulseAudio = Backend(rawValue: CSoundIO.SoundIoBackendPulseAudio)
    public static let alsa = Backend(rawValue: CSoundIO.SoundIoBackendAlsa)
    public static let coreAudio = Backend(rawValue: CSoundIO.SoundIoBackendCoreAudio)
    public static let wasapi = Backend(rawValue: CSoundIO.SoundIoBackendWasapi)
    public static let dummy = Backend(rawValue: CSoundIO.SoundIoBackendDummy)
}

public class Device {
    fileprivate let internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoDevice>

    deinit {
        soundio_device_unref(internalPointer)
    }

    init(internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoDevice>) {
        self.internalPointer = internalPointer
    }

    public var id: String {
        return String(cString: self.internalPointer.pointee.id)
    }

    public var name: String {
        return String(cString: self.internalPointer.pointee.name)
    }

    public var raw: Bool {
        return self.internalPointer.pointee.is_raw
    }

    public var layoutCount: Int {
        return Int(self.internalPointer.pointee.layout_count)
    }

    public var currentLayout: ChannelLayout {
        let pointer = withUnsafeMutablePointer(to: &self.internalPointer.pointee.current_layout) {
            UnsafeMutablePointer($0)
        }
        return ChannelLayout(internalPointer: pointer)
    }

    public var layouts: [ChannelLayout] {
        let buffer = UnsafeBufferPointer(start: internalPointer.pointee.layouts, count: layoutCount)

        return [ChannelLayout](unsafeUninitializedCapacity: layoutCount) { array, count in
            for (i, var value) in buffer.enumerated() {
                let p = UnsafeMutablePointer<SoundIoChannelLayout>.allocate(capacity: MemoryLayout<SoundIoChannelLayout>.alignment)
                p.initialize(from: &value, count: 1)
                array[i] = ChannelLayout(internalPointer: p)
            }
            count = layoutCount
        }
    }

    public var sampleRateCount: Int {
        return Int(internalPointer.pointee.sample_rate_count)
    }

    public lazy var sampleRates: [SampleRateRange] = {
        let buffer = UnsafeBufferPointer(start: internalPointer.pointee.sample_rates, count: sampleRateCount)
        return Array(buffer.map { (max: $0.max, min: $0.min) })
    }()

    public var sampleRateCurrent: Int {
        return Int(internalPointer.pointee.sample_rate_current)
    }

    public var formatCount: Int {
        return Int(internalPointer.pointee.format_count)
    }

    public lazy var formats: [Format] = {
        let buffer = UnsafeBufferPointer(start: internalPointer.pointee.formats, count: formatCount)
        return Array(buffer.map { Format(rawValue: $0) })
    }()

    public var currentFormat: Format {
        return Format(rawValue: internalPointer.pointee.current_format)
    }

    public var softwareLatencyMin: Double {
        return internalPointer.pointee.software_latency_min
    }

    public var softwareLatencyMax: Double {
        return internalPointer.pointee.software_latency_max
    }

    public var softwareLatencyCurrent: Double {
        return internalPointer.pointee.software_latency_current
    }

    public func probeError() -> SoundIOError? {
        let error = self.internalPointer.pointee.probe_error
        if 0 < error {
            return SoundIOError(errorCode: error)
        }
        return nil
    }

    public func withInternalPointer<T>(
        _ unsafeTask: (_ pointer: UnsafeMutablePointer<CSoundIO.SoundIoDevice>) throws -> T) throws -> T {
        return try unsafeTask(self.internalPointer)
    }
}

public typealias SampleRateRange = (max: Int32, min: Int32)

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

public typealias ChannelAreaList = UnsafeMutablePointer<SoundIoChannelArea>?

extension ChannelAreaList {
    public func iterate(over channelCount: UInt) -> UnsafeBufferPointer<SoundIoChannelArea> {
        return UnsafeBufferPointer(start: self, count: Int(channelCount))
    }
}

public typealias ChannelArea = SoundIoChannelArea

extension ChannelArea {
    public func write<T: BinaryFloatingPoint>(_ value: T, stepBy frame: Int32) {
        writeAny(value: value, stepBy: frame)
    }

    public func write<T: BinaryInteger>(_ value: T, stepBy frame: Int32) {
        writeAny(value: value, stepBy: frame)
    }

    private func writeAny<T>(value: T, stepBy frame: Int32) {
        let buffer = self.ptr + Int(self.step * frame)
        buffer.withMemoryRebound(to: T.self, capacity: 1) {
            $0.pointee = value
        }
    }
}

public struct ChannelLayout {
    fileprivate let internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoChannelLayout>

    public var name: String? {
        guard let pointer = internalPointer.pointee.name else {
            print("NULL")
            return nil
        }
        return String(cString: pointer)
    }

    public var channelCount: UInt {
        return UInt(internalPointer.pointee.channel_count)
    }

    public var channels: [ChannelId] {
        return withUnsafeBytes(of: &internalPointer.pointee.channels) { raw in
            let ptr = raw.baseAddress!.assumingMemoryBound(to: SoundIoChannelId.self)
            let buffer = UnsafeBufferPointer(start: ptr, count: Int(SOUNDIO_MAX_CHANNELS))
            return Array(buffer)
        }
    }
}

public func getChannelName(for channelId: ChannelId) -> String {
    return String(cString: soundio_get_channel_name(channelId))
}

public struct Format: Equatable {
    fileprivate let rawValue: SoundIoFormat

    public static let invalid = Format(rawValue: CSoundIO.SoundIoFormatInvalid)
    public static let signed8bit = Format(rawValue: CSoundIO.SoundIoFormatS8)
    public static let unsigned8bit = Format(rawValue: CSoundIO.SoundIoFormatU8)
    public static let signed16bitLittleEndian = Format(rawValue: CSoundIO.SoundIoFormatS16LE)
    public static let signed16bitBigEndian = Format(rawValue: CSoundIO.SoundIoFormatS16BE)
    public static let unsigned16bitLittleEndian = Format(rawValue: CSoundIO.SoundIoFormatU16LE)
    public static let unsigned16bitBigEndian = Format(rawValue: CSoundIO.SoundIoFormatU16BE)
    public static let signed24bitLittleEndian = Format(rawValue: CSoundIO.SoundIoFormatS24LE)
    public static let signed24bitBigEndian = Format(rawValue: CSoundIO.SoundIoFormatS24BE)
    public static let unsigned24bitLittleEndian = Format(rawValue: CSoundIO.SoundIoFormatU24LE)
    public static let unsigned24bitBigEndian = Format(rawValue: CSoundIO.SoundIoFormatU24BE)
    public static let signed32bitLittleEndian = Format(rawValue: CSoundIO.SoundIoFormatS32LE)
    public static let signed32bitBigEndian = Format(rawValue: CSoundIO.SoundIoFormatS32BE)
    public static let unsigned32bitLittleEndian = Format(rawValue: CSoundIO.SoundIoFormatU32LE)
    public static let unsigned32bitBigEndian = Format(rawValue: CSoundIO.SoundIoFormatU32BE)
    public static let float32bitLittleEndian = Format(rawValue: CSoundIO.SoundIoFormatFloat32LE)
    public static let float32bitBigEndian = Format(rawValue: CSoundIO.SoundIoFormatFloat32BE)
    public static let float64bitLittleEndian = Format(rawValue: CSoundIO.SoundIoFormatFloat64LE)
    public static let float64bitBigEndian = Format(rawValue: CSoundIO.SoundIoFormatFloat64BE)

    public func toString() -> String {
        return String(cString: soundio_format_string(rawValue))
    }
}
