//
//  PPTheme.m
//  PhotoPurge
//

#import "PPTheme.h"

@implementation PPTheme

#pragma mark - Color Construction Helpers

+ (UIColor *)dynamicColorWithLight:(UIColor *)light dark:(UIColor *)dark {
    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return dark;
        } else {
            return light;
        }
    }];
}

+ (UIColor *)colorWithR:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a {
    return [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a];
}

#pragma mark - Surfaces & Canvas

+ (UIColor *)canvasBackgroundColor {
    return [self dynamicColorWithLight:[self colorWithR:244 g:241 b:234 a:1.0]   // Warm Cream Linen (#F4F1EA)
                                  dark:[self colorWithR:18  g:18  b:20  a:1.0]];  // Deep Pitch Carbon (#121214)
}

+ (UIColor *)cardSurfaceColor {
    return [self dynamicColorWithLight:[self colorWithR:255 g:255 b:255 a:1.0]   // Pure Matte White
                                  dark:[self colorWithR:30  g:30  b:34  a:1.0]];  // Charcoal Matte (#1E1E22)
}

+ (UIColor *)secondarySurfaceColor {
    return [self dynamicColorWithLight:[self colorWithR:234 g:230 b:221 a:1.0]   // Warm Ecru (#EAE6DD)
                                  dark:[self colorWithR:38  g:38  b:43  a:1.0]];  // Darkroom Chamber (#26262B)
}

+ (UIColor *)actionButtonBackgroundColor {
    return [self dynamicColorWithLight:[self colorWithR:255 g:255 b:255 a:1.0]   // Clean White
                                  dark:[self colorWithR:34  g:34  b:39  a:1.0]];  // Charcoal Raised (#222227)
}

#pragma mark - Core Photographic Curation Actions

+ (UIColor *)keepActionColor {
    return [self dynamicColorWithLight:[self colorWithR:46  g:139 b:87  a:1.0]   // Sage Emerald (#2E8B57)
                                  dark:[self colorWithR:46  g:213 b:115 a:1.0]];  // Mint Phosphor (#2ED573)
}

+ (UIColor *)purgeActionColor {
    return [self dynamicColorWithLight:[self colorWithR:224 g:49  b:49  a:1.0]   // Vermilion Crimson (#E03131)
                                  dark:[self colorWithR:255 g:71  b:87  a:1.0]];  // Neon Coral (#FF4757)
}

+ (UIColor *)undoActionColor {
    return [self dynamicColorWithLight:[self colorWithR:217 g:119 b:6   a:1.0]   // Warm Amber (#D97706)
                                  dark:[self colorWithR:255 g:165 b:2   a:1.0]];  // Luminous Gold (#FFA502)
}

#pragma mark - Typography

+ (UIColor *)primaryTextColor {
    return [self dynamicColorWithLight:[self colorWithR:28  g:25  b:23  a:1.0]   // Deep Espresso Ink (#1C1917)
                                  dark:[self colorWithR:245 g:245 b:247 a:1.0]];  // Clean Parchment (#F5F5F7)
}

+ (UIColor *)secondaryTextColor {
    return [self dynamicColorWithLight:[self colorWithR:107 g:102 b:97  a:1.0]   // Muted Sepia Slate (#6B6661)
                                  dark:[self colorWithR:158 g:155 b:150 a:1.0]];  // Muted Darkroom Silver (#9E9B96)
}

#pragma mark - Accents & Chrome

+ (UIColor *)pillBorderColor {
    return [self dynamicColorWithLight:[self colorWithR:213 g:208 b:197 a:0.9]   // Warm Stone Gray (#D5D0C5)
                                  dark:[self colorWithR:61  g:61  b:68  a:0.9]];  // Dark Zinc (#3D3D44)
}

+ (UIColor *)pillTextColor {
    return [self dynamicColorWithLight:[self colorWithR:44  g:52  b:55  a:1.0]   // Deep Slate Umber (#2C3437)
                                  dark:[self colorWithR:228 g:228 b:230 a:1.0]];  // Soft Warm Titanium (#E4E4E6)
}

+ (UIColor *)pillBackgroundColor {
    return [self dynamicColorWithLight:[self colorWithR:234 g:230 b:221 a:0.65]  // Tinted Ecru
                                  dark:[self colorWithR:38  g:38  b:43  a:0.75]]; // Tinted Chamber
}

+ (UIColor *)navigationTintColor {
    return [self dynamicColorWithLight:[self colorWithR:28  g:25  b:23  a:1.0]   // Deep Espresso Ink
                                  dark:[self colorWithR:245 g:245 b:247 a:1.0]];  // Clean Parchment
}

#pragma mark - Global Appearance

+ (void)applyAppearance {
    // Navigation bar appearance
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [self canvasBackgroundColor];
    appearance.shadowColor = [UIColor clearColor];
    
    appearance.titleTextAttributes = @{
        NSForegroundColorAttributeName: [self primaryTextColor],
        NSFontAttributeName: [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold]
    };
    appearance.largeTitleTextAttributes = @{
        NSForegroundColorAttributeName: [self primaryTextColor],
        NSFontAttributeName: [UIFont systemFontOfSize:34.0 weight:UIFontWeightBold]
    };
    
    [UINavigationBar appearance].standardAppearance = appearance;
    [UINavigationBar appearance].compactAppearance = appearance;
    [UINavigationBar appearance].scrollEdgeAppearance = appearance;
    [UINavigationBar appearance].tintColor = [self navigationTintColor];
}

@end
