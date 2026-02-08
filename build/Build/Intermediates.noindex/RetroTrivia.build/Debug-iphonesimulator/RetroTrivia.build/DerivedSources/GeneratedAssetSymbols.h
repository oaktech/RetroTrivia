#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.oak-tech.RetroTrivia";

/// The "ElectricBlue" asset catalog color resource.
static NSString * const ACColorNameElectricBlue AC_SWIFT_PRIVATE = @"ElectricBlue";

/// The "HotMagenta" asset catalog color resource.
static NSString * const ACColorNameHotMagenta AC_SWIFT_PRIVATE = @"HotMagenta";

/// The "NeonPink" asset catalog color resource.
static NSString * const ACColorNameNeonPink AC_SWIFT_PRIVATE = @"NeonPink";

/// The "NeonYellow" asset catalog color resource.
static NSString * const ACColorNameNeonYellow AC_SWIFT_PRIVATE = @"NeonYellow";

/// The "RetroPurple" asset catalog color resource.
static NSString * const ACColorNameRetroPurple AC_SWIFT_PRIVATE = @"RetroPurple";

#undef AC_SWIFT_PRIVATE
