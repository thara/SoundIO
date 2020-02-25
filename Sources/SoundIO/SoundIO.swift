import CSoundIO

public typealias DeviceIndex = Int32

public class SoundIO {
    let internalPointer: UnsafeMutablePointer<CSoundIO.SoundIo>

    private var temporary: Bool = false
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

    public func createRingBuffer(capacity: Int32) throws -> RingBuffer {
        guard let p = soundio_ring_buffer_create(self.internalPointer, capacity) else {
            throw SoundIOError(message: "memory could not be allocated")
        }
        return RingBuffer(internalPointer: p)
    }

    public func withInternalPointer(
        _ unsafeTask: (_ pointer: UnsafeMutablePointer<CSoundIO.SoundIo>) throws -> Void) throws {
        try unsafeTask(self.internalPointer)
    }
}
