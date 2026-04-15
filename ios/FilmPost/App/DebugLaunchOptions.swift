import Foundation

enum DebugLaunchOptions {
    static func shouldAutoRunDemo(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        arguments.contains("-auto-demo")
    }
}
