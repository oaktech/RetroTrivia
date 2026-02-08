import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "ElectricBlue" asset catalog color resource.
    static let electricBlue = DeveloperToolsSupport.ColorResource(name: "ElectricBlue", bundle: resourceBundle)

    /// The "HotMagenta" asset catalog color resource.
    static let hotMagenta = DeveloperToolsSupport.ColorResource(name: "HotMagenta", bundle: resourceBundle)

    /// The "NeonPink" asset catalog color resource.
    static let neonPink = DeveloperToolsSupport.ColorResource(name: "NeonPink", bundle: resourceBundle)

    /// The "NeonYellow" asset catalog color resource.
    static let neonYellow = DeveloperToolsSupport.ColorResource(name: "NeonYellow", bundle: resourceBundle)

    /// The "RetroPurple" asset catalog color resource.
    static let retroPurple = DeveloperToolsSupport.ColorResource(name: "RetroPurple", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "ElectricBlue" asset catalog color.
    static var electricBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .electricBlue)
#else
        .init()
#endif
    }

    /// The "HotMagenta" asset catalog color.
    static var hotMagenta: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hotMagenta)
#else
        .init()
#endif
    }

    /// The "NeonPink" asset catalog color.
    static var neonPink: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .neonPink)
#else
        .init()
#endif
    }

    /// The "NeonYellow" asset catalog color.
    static var neonYellow: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .neonYellow)
#else
        .init()
#endif
    }

    /// The "RetroPurple" asset catalog color.
    static var retroPurple: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .retroPurple)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "ElectricBlue" asset catalog color.
    static var electricBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .electricBlue)
#else
        .init()
#endif
    }

    /// The "HotMagenta" asset catalog color.
    static var hotMagenta: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .hotMagenta)
#else
        .init()
#endif
    }

    /// The "NeonPink" asset catalog color.
    static var neonPink: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .neonPink)
#else
        .init()
#endif
    }

    /// The "NeonYellow" asset catalog color.
    static var neonYellow: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .neonYellow)
#else
        .init()
#endif
    }

    /// The "RetroPurple" asset catalog color.
    static var retroPurple: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .retroPurple)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "ElectricBlue" asset catalog color.
    static var electricBlue: SwiftUI.Color { .init(.electricBlue) }

    /// The "HotMagenta" asset catalog color.
    static var hotMagenta: SwiftUI.Color { .init(.hotMagenta) }

    /// The "NeonPink" asset catalog color.
    static var neonPink: SwiftUI.Color { .init(.neonPink) }

    /// The "NeonYellow" asset catalog color.
    static var neonYellow: SwiftUI.Color { .init(.neonYellow) }

    /// The "RetroPurple" asset catalog color.
    static var retroPurple: SwiftUI.Color { .init(.retroPurple) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "ElectricBlue" asset catalog color.
    static var electricBlue: SwiftUI.Color { .init(.electricBlue) }

    /// The "HotMagenta" asset catalog color.
    static var hotMagenta: SwiftUI.Color { .init(.hotMagenta) }

    /// The "NeonPink" asset catalog color.
    static var neonPink: SwiftUI.Color { .init(.neonPink) }

    /// The "NeonYellow" asset catalog color.
    static var neonYellow: SwiftUI.Color { .init(.neonYellow) }

    /// The "RetroPurple" asset catalog color.
    static var retroPurple: SwiftUI.Color { .init(.retroPurple) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

