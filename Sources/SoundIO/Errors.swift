import CSoundIO

public struct SoundIOError: Error {
    public let message: String

    init(errorCode: CInt) {
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
