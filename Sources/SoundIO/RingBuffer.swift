import CSoundIO
import Foundation

public class RingBuffer {
    let internalPointer: OpaquePointer

    init(internalPointer: OpaquePointer) {
        self.internalPointer = internalPointer
    }

    public convenience init(for soundio: SoundIO, capacity: Int32) throws {
        guard let p = soundio_ring_buffer_create(soundio.internalPointer, capacity) else {
            throw SoundIOError(message: "memory could not be allocated for ring buffer")
        }
        self.init(internalPointer: p)
    }

    deinit {
        soundio_ring_buffer_destroy(internalPointer)
    }

    public var capacity: Int32 {
        soundio_ring_buffer_capacity(internalPointer)
    }

    public var freeCount: Int32 {
        soundio_ring_buffer_free_count(internalPointer)
    }

    public var fillCount: Int32 {
        soundio_ring_buffer_fill_count(internalPointer)
    }

    // public func writeBuffer() -> Data? {
    //     guard let p = soundio_ring_buffer_write_ptr(self.internalPointer) else {
    //         return nil
    //     }
    //     return Data(bytesNoCopy: p, count: Int(self.capacity), deallocator: .none)
    // }

    public var writePointer: UnsafeMutablePointer<Int8>? {
        return soundio_ring_buffer_write_ptr(internalPointer)
    }

    public var readPointer: UnsafeMutablePointer<Int8>? {
        return soundio_ring_buffer_read_ptr(internalPointer)
    }

    public func advanceReadPointer(by count: Int32) {
        soundio_ring_buffer_advance_read_ptr(internalPointer, count)
    }

    public func advanceWritePointer(by count: Int32) {
        soundio_ring_buffer_advance_write_ptr(internalPointer, count)
    }
}
