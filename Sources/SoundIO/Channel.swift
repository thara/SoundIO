import CSoundIO

public typealias ChannelId = CSoundIO.SoundIoChannelId

public typealias SampleRateRange = (max: Int32, min: Int32)

public typealias ChannelAreaList = UnsafeMutablePointer<SoundIoChannelArea>?
public typealias ChannelArea = SoundIoChannelArea

extension ChannelAreaList {
    public func iterate(over channelCount: UInt) -> UnsafeBufferPointer<SoundIoChannelArea> {
        return UnsafeBufferPointer(start: self, count: Int(channelCount))
    }
}

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
    let internalPointer: UnsafeMutablePointer<CSoundIO.SoundIoChannelLayout>

    public var name: String? {
        guard let pointer = internalPointer.pointee.name else {
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
