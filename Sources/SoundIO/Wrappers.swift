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

    public func getOutputDevice(at index: DeviceIndex) throws -> SoundIODevice {
        guard let device = soundio_get_output_device(self.internalPointer, index) else {
            throw SoundIOError(message: "invalid parameter value")
        }
        return SoundIODevice(internalPointer: device)
    }

    public func withInternalPointer(
        _ unsafeTask: (_ pointer: UnsafeMutablePointer<CSoundIO.SoundIo>) throws -> Void) throws {
        try unsafeTask(self.internalPointer)
    }
}

public class SoundIODevice {
    private let internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoDevice>

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
