//
//  PPPermissionView.h
//  PhotoPurge
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PPPermissionViewState) {
    // Initial prompt asking the user to trigger permission dialog
    PPPermissionViewStatePrompt,
    // Fallback state when permission was denied or restricted
    PPPermissionViewStateDenied
};

@class PPPermissionView;

@protocol PPPermissionViewDelegate <NSObject>

// Triggered when the user taps "Continue" in the pre-prompt state
- (void)permissionViewDidRequestAuthorization:(PPPermissionView *)permissionView;

// Triggered when the user taps "Open Settings" in the denied state
- (void)permissionViewDidRequestOpenSettings:(PPPermissionView *)permissionView;

@end

@interface PPPermissionView : UIView

@property (nonatomic, weak, nullable) id<PPPermissionViewDelegate> delegate;


// Updates the visual styling and CTA based on permission state
- (void)configureForState:(PPPermissionViewState)state;

@end

NS_ASSUME_NONNULL_END
