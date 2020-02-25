import CSoundIO

public typealias ChannelId = CSoundIO.SoundIoChannelId

public typealias SampleRateRange = (max: Int32, min: Int32)

public typealias ChannelAreaList = UnsafeMutablePointer<SoundIoChannelArea>
public typealias ChannelArea = SoundIoChannelArea

public struct ChannelLayoutList {
    let internalPointer: UnsafeBufferPointer<SoundIoChannelLayout>

    public var count: Int32 {
        return Int32(internalPointer.count)
    }

    public subscript(i: Int) -> ChannelLayout {
        return ChannelLayout(internalPointer: internalPointer.baseAddress! + i)
    }
}

extension ChannelAreaList {
    public func iterate(over channelCount: UInt) -> UnsafeBufferPointer<SoundIoChannelArea> {
        return UnsafeBufferPointer(start: self, count: Int(channelCount))
    }
}

extension ChannelArea {
    public func write<T: BinaryFloatingPoint>(_ value: T, stepBy frame: Int32 = 1) {
        writeAny(value: value, stepBy: frame)
    }

    public func write<T: BinaryInteger>(_ value: T, stepBy frame: Int32 = 1) {
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
    let internalPointer: UnsafePointer<CSoundIO.SoundIoChannelLayout>

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
        var channelTuple = internalPointer.pointee.channels
        return withUnsafeBytes(of: &channelTuple) { raw in
            let ptr = raw.baseAddress!.assumingMemoryBound(to: SoundIoChannelId.self)
            let buffer = UnsafeBufferPointer(start: ptr, count: Int(SOUNDIO_MAX_CHANNELS))
            return Array(buffer)
        }
    }

    public static func findBestMatching(preferred: ChannelLayoutList, available: ChannelLayoutList) -> ChannelLayout? {
        let matches = soundio_best_matching_channel_layout(preferred.internalPointer.baseAddress, preferred.count, available.internalPointer.baseAddress, available.count)
        if let p = matches {
            return ChannelLayout(internalPointer: UnsafeMutablePointer(mutating: p))
        }
        return nil
    }
}

public func getChannelName(for channelId: ChannelId) -> String {
    return String(cString: soundio_get_channel_name(channelId))
}
