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

        print("--------Input Devices--------")
        for i in 0..<inputCount {
            let device = try getInputDevice(at: i)
            device.print(default: i == defaultInput)
        }

        print("\n--------Output Devices--------")
        for i in 0..<outputCount {
            let device = try getOutputDevice(at: i)
            device.print(default: i == defaultOutput)
        }

        print("\(inputCount + outputCount) devicess found")
    }
}

extension Device {
    func print(default isDefault: Bool) {
        Swift.print("\(name)\(isDefault ? " (default)" : "")\(raw ? " (raw)" : "")")
        if shortOutput {
            return
        }
    }
}

var shortOutput = false
var backend: Backend = .none

func main() throws {
    let argv = ProcessInfo.processInfo.arguments

    var watch = false

    for (var i, arg) in argv.enumerated().dropFirst(1) {
        switch arg {
        case "--watch":
            watch = true
        case "--short":
            shortOutput = true
        case "--backend":
            i += 1
            if argv.count - 1 <= i {
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
            usage(path: argv[0])
        }
    }

    let soundio = try SoundIO()

    if backend == .none {
        try soundio.connect()
    } else {
        try soundio.connect(to: backend)
    }

    if watch {

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

