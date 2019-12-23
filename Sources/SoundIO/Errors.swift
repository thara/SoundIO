import CSoundIO

public struct SoundIOError: Error {
    public let message: String

    internal init(message: String) {
        self.message = message
    }

    internal init(errorCode: CInt) {
        self.message = String(cString: soundio_strerror(errorCode))
    }
}

extension SoundIOError: CustomStringConvertible {
    public var description: String {
        return message
    }
}

//TODO Make internal
public extension CInt {
    @inline(__always)
    func ensureSuccess() throws {
        if 0 < self {
            throw SoundIOError(errorCode: self)
        }
    }
}

//TODO Make internal
public extension Optional {
    @inline(__always)
    func ensureAllocatedMemory() throws -> Wrapped {
        guard let value = self else {
            throw SoundIOError(message: "Ouf of memory: \(Wrapped.self)")
        }
        return value
    }
}
