import Foundation
import ArgumentParser

// MARK: - JSON Utilities

enum JSONError: LocalizedError {
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode object to JSON"
        }
    }
}

extension Encodable {
    func toJSONString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let jsonData = try encoder.encode(self)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw JSONError.encodingFailed
        }
        
        return jsonString
    }
}

// MARK: - CLI Commands

struct BrightnessCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "CLI utility for retrieving and setting brightness of displays",
        subcommands: [DetectDisplays.self, SetBrightness.self],
        defaultSubcommand: DetectDisplays.self
    )
}

struct DetectDisplays: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Detects connected displays and prints their information."
    )
    
    func run() throws {
        let displayManager = DisplayManager()
        let displays = displayManager.retrieveDisplays()
        
        let jsonOutput = try displays.toJSONString()
        print(jsonOutput)
    }
}

struct SetBrightness: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Sets the brightness of a specific display."
    )
    
    @Argument(help: "The ID of the display to set brightness for.")
    var displayID: Int
    
    @Argument(help: "The brightness value to set (0.0 to 1.0).")
    var brightness: Double
    
    func run() throws {
        guard brightness >= 0.0 && brightness <= 1.0 else {
            throw ValidationError("Brightness must be between 0.0 and 1.0")
        }
        
        let displayManager = DisplayManager()
        let success = displayManager.setBrightness(forDisplayID: displayID, brightness: Float(brightness))
        
        print(success)
    }
}

// MARK: - Entry Point

BrightnessCLI.main()