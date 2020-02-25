import CSoundIO

public struct Backend: Equatable {
    let rawValue: SoundIoBackend

    public static let none = Backend(rawValue: CSoundIO.SoundIoBackendNone)

    public static let jack = Backend(rawValue: CSoundIO.SoundIoBackendJack)
    public static let pulseAudio = Backend(rawValue: CSoundIO.SoundIoBackendPulseAudio)
    public static let alsa = Backend(rawValue: CSoundIO.SoundIoBackendAlsa)
    public static let coreAudio = Backend(rawValue: CSoundIO.SoundIoBackendCoreAudio)
    public static let wasapi = Backend(rawValue: CSoundIO.SoundIoBackendWasapi)
    public static let dummy = Backend(rawValue: CSoundIO.SoundIoBackendDummy)
}

public struct Format: Equatable {
    let rawValue: SoundIoFormat

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
