import Foundation
import CoreGraphics
import AppKit
import IOKit.i2c
import AppleSiliconDDC
import AppleSiliconDDCObjC

// MARK: - Display Model

struct Display: Codable, Identifiable {
    let id: UInt32
    let name: String
    let isBuiltIn: Bool
    let brightness: Float?
    let isSupported: Bool
    
    private let ioDisplayLocation: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isBuiltIn
        case brightness
        case isSupported
    }
    
    init(displayID: CGDirectDisplayID, name: String) {
        self.id = displayID
        self.name = name
        self.isBuiltIn = CGDisplayIsBuiltin(displayID) != 0
        self.ioDisplayLocation = Self.getDisplayLocation(for: displayID)
        self.isSupported = Self.isDisplaySupported(ioDisplayLocation: ioDisplayLocation)
        
        if isBuiltIn {
            self.brightness = Self.getInternalBrightness(for: displayID)
        } else {
            self.brightness = Self.getExternalBrightness(ioDisplayLocation: ioDisplayLocation)
        }
    }
    
    // Codable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UInt32.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.isBuiltIn = try container.decode(Bool.self, forKey: .isBuiltIn)
        self.brightness = try container.decodeIfPresent(Float.self, forKey: .brightness)
        self.isSupported = try container.decode(Bool.self, forKey: .isSupported)
        self.ioDisplayLocation = nil // Not encoded/decoded
    }
    
    // MARK: - Internal Display Brightness
    
    private static func getInternalBrightness(for displayID: CGDirectDisplayID) -> Float? {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY) else {
            return nil
        }
        
        defer { dlclose(handle) }
        
        guard let symbol = dlsym(handle, "DisplayServicesGetBrightness") else {
            return nil
        }
        
        typealias GetBrightnessFunction = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
        let getBrightness = unsafeBitCast(symbol, to: GetBrightnessFunction.self)
        
        var brightness: Float = -1.0
        let result = getBrightness(displayID, &brightness)
        
        guard result == 0 else { return nil }
        
        return (brightness * 10).rounded() / 10
    }
    
    static func setInternalBrightness(for displayID: CGDirectDisplayID, brightness: Float) -> Bool {
        guard brightness >= 0.0 && brightness <= 1.0 else { return false }
        
        guard let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY) else {
            return false
        }
        
        defer { dlclose(handle) }
        
        guard let symbol = dlsym(handle, "DisplayServicesSetBrightness") else {
            return false
        }
        
        typealias SetBrightnessFunction = @convention(c) (CGDirectDisplayID, Float) -> Int32
        let setBrightness = unsafeBitCast(symbol, to: SetBrightnessFunction.self)
        
        let result = setBrightness(displayID, brightness)
        return result == 0
    }
    
    // MARK: - External Display Brightness
    
    private static func getExternalBrightness(ioDisplayLocation: String?) -> Float? {
        guard let ioDisplayLocation = ioDisplayLocation,
              let service = findMatchingService(ioDisplayLocation: ioDisplayLocation),
              let value = AppleSiliconDDC.read(service: service.service, command: 0x10) else {
            return nil
        }
        
        let brightnessLevel = value.current & 0x00FF
        let brightness = Float(brightnessLevel) / 100.0
        return (brightness * 10).rounded() / 10
    }
    
    static func setExternalBrightness(ioDisplayLocation: String?, brightness: Float) -> Bool {
        guard brightness >= 0.0 && brightness <= 1.0,
              let ioDisplayLocation = ioDisplayLocation,
              let service = findMatchingService(ioDisplayLocation: ioDisplayLocation) else {
            return false
        }
        
        let brightnessValue = UInt16(brightness * 100)
        return AppleSiliconDDC.write(service: service.service, command: 0x10, value: brightnessValue)
    }
    
    // MARK: - Helper Methods
    
    static func getDisplayLocation(for displayID: CGDirectDisplayID) -> String? {
        guard let dictionary = AppleSiliconDDCObjC.CoreDisplay_DisplayCreateInfoDictionary(displayID)?.takeRetainedValue() as NSDictionary?,
              let ioDisplayLocation = dictionary["IODisplayLocation"] as? String else {
            return nil
        }
        
        return ioDisplayLocation
    }
    
    private static func findMatchingService(ioDisplayLocation: String) -> AppleSiliconDDC.IOregService? {
        let allDisplays = AppleSiliconDDC.getIoregServicesForMatching()
        return allDisplays.first { $0.ioDisplayLocation == ioDisplayLocation }
    }
    
    private static func isDisplaySupported(ioDisplayLocation: String?) -> Bool {
        guard let ioDisplayLocation = ioDisplayLocation,
              let service = findMatchingService(ioDisplayLocation: ioDisplayLocation) else {
            return true // Built-in displays are always supported
        }

        return !service.transportUpstream.contains("HDMI")
    }
}

// MARK: - Display Manager

final class DisplayManager {
    
    func retrieveDisplays() -> [Display] {
        guard AppleSiliconDDC.isArm64 else {
            return []
        }
        
        return NSScreen.screens.compactMap { screen in
            guard let screenID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                return nil
            }
            
            return Display(displayID: screenID, name: screen.localizedName)
        }
    }
    
    func setBrightness(forDisplayID displayID: Int, brightness: Float) -> Bool {
        guard AppleSiliconDDC.isArm64 else {
            return false
        }
        
        guard brightness >= 0.0 && brightness <= 1.0 else {
            return false
        }
        
        let cgDisplayID = CGDirectDisplayID(displayID)
        let isBuiltIn = CGDisplayIsBuiltin(cgDisplayID) != 0
        
        if isBuiltIn {
            return Display.setInternalBrightness(for: cgDisplayID, brightness: brightness)
        } else {
            let ioDisplayLocation = Display.getDisplayLocation(for: cgDisplayID)
            return Display.setExternalBrightness(ioDisplayLocation: ioDisplayLocation, brightness: brightness)
        }
    }
}
