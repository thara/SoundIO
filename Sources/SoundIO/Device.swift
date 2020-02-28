import CSoundIO

public class Device {
    let internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoDevice>

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
        return ChannelLayout(internalPointer: &self.internalPointer.pointee.current_layout)
    }

    public var layouts: ChannelLayoutList {
        let buffer = UnsafeBufferPointer(start: internalPointer.pointee.layouts, count: layoutCount)
        return ChannelLayoutList(internalPointer: buffer)
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
