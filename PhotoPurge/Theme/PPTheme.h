//
//  PPTheme.h
//  PhotoPurge
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PPTheme : NSObject

#pragma mark - Surfaces & Canvas

/// Canvas background (Warm Cream Linen in Light, Deep Pitch Carbon in Dark)
+ (UIColor *)canvasBackgroundColor;

/// Card surface (Pure Matte White in Light, Charcoal Matte in Dark)
+ (UIColor *)cardSurfaceColor;

/// Secondary surface / container (Warm Ecru in Light, Darkroom Chamber in Dark)
+ (UIColor *)secondarySurfaceColor;

/// Action button circle surface (Pure White in Light, Charcoal Raised in Dark)
+ (UIColor *)actionButtonBackgroundColor;

#pragma mark - Core Photographic Curation Actions

/// Keep / Preserve (Sage Emerald in Light, Mint Phosphor in Dark)
+ (UIColor *)keepActionColor;

/// Purge / Delete (Vermilion Crimson in Light, Neon Coral in Dark)
+ (UIColor *)purgeActionColor;

/// Undo / Rewind (Warm Amber in Light, Luminous Gold in Dark)
+ (UIColor *)undoActionColor;

#pragma mark - Typography

/// Primary text & titles (Deep Espresso Ink in Light, Clean Parchment in Dark)
+ (UIColor *)primaryTextColor;

/// Secondary text & subtitles (Muted Sepia Slate in Light, Muted Darkroom Silver in Dark)
+ (UIColor *)secondaryTextColor;

#pragma mark - Accents & Chrome

/// Storage pill border
+ (UIColor *)pillBorderColor;

/// Storage pill text / icon tint
+ (UIColor *)pillTextColor;

/// Storage pill background
+ (UIColor *)pillBackgroundColor;

/// Bar button and navigation chrome tint
+ (UIColor *)navigationTintColor;

#pragma mark - Global Appearance

/// Applies the theme to standard UIKit appearances (UINavigationBar, etc.)
+ (void)applyAppearance;

@end

NS_ASSUME_NONNULL_END
