import Foundation
import SoundIO

func usage(path: String) {
    let programName = URL(fileURLWithPath: path).lastPathComponent
    print("""
        Usage: \(programName) [options]
            Options:
              [--watch]
              [--backend dummy|alsa|pulseaudio|jack|coreaudio|wasapi]
              [--short]
        """)
    exit(EXIT_FAILURE)
}

extension SoundIO {

    func listDevices() throws {
        let outputCount = try outputDeviceCount()
        let inputCount = try inputDeviceCount()

        let defaultOutput = try defaultOutputDeviceIndex()
        let defaultInput = try defaultInputDeviceIndex()

        print("--------Input Devices--------\n")
        for i in 0..<inputCount {
            let device = try getInputDevice(at: i)
            try device.printInfo(default: i == defaultInput)
        }

        print("\n--------Output Devices--------\n")
        for i in 0..<outputCount {
            let device = try getOutputDevice(at: i)
            try device.printInfo(default: i == defaultOutput)
        }

        print("\(inputCount + outputCount) devicess found")
    }
}

extension Device {
    func printInfo(default isDefault: Bool) throws {
        print("\(name)\(isDefault ? " (default)" : "")\(raw ? " (raw)" : "")")
        if shortOutput {
            return
        }
        print("  id: \(id)")

        if let error = probeError() {
            print("probe error: \(error.message)")
            return
        }

        print("  channel layouts:")
        for i in 0..<layoutCount {
            print("    ", terminator: "")
            layouts[i].printName()
            print("")
        }

        if 0 < currentLayout.channelCount {
            print("  current layout: ", terminator: "")
            currentLayout.printName()
            print("")
        }

        print("  sample rates:")
        for i in 0..<sampleRateCount {
            let range = sampleRates[i]
            print("    \(range.max) - (range.min)")
        }
    }
}

extension ChannelLayout {
    func printName() {
        if let name = name {
            print(name, terminator: "")
        } else {
            print(channels.map { getChannelName(for: $0) }.joined(separator: ", "), terminator: "")
        }
    }
}

var shortOutput = false
var backend: Backend = .none

func main() throws {
    let argv = ProcessInfo.processInfo.arguments

    var watch = false

    var i = 1
    while i < argv.count {
        let arg = argv[i]
        switch arg {
        case "--watch":
            watch = true
        case "--short":
            shortOutput = true
        case "--backend":
            i += 1
            if argv.count - 1 < i {
                usage(path: argv[0])
            } else {
                switch argv[i] {
                case "dummy":
                    backend = .dummy
                case "alsa":
                    backend = .alsa
                case "pulseaudio":
                    backend = .pulseAudio
                case "jack":
                    backend = .jack
                case "coreaudio":
                    backend = .coreAudio
                case "wasapi":
                    backend = .wasapi
                default:
                    print("Invalid backend: \(argv[i])")
                    usage(path: argv[0])
                }
            }
        default:
            print("default", arg)
            usage(path: argv[0])
        }

        i += 1
    }

    let soundio = try SoundIO()

    if backend == .none {
        try soundio.connect()
    } else {
        try soundio.connect(to: backend)
    }

    if watch {
        soundio.onDevicesChange {
            print("devices changed")
            try! $0.listDevices()
        }
        while true {
            soundio.waitEvents()
        }
    } else {
        soundio.flushEvents()
        try soundio.listDevices()
    }
}

do {
    try main()
} catch let error as SoundIOError {
    print("Error: \(error)")
    exit(EXIT_FAILURE)
}

