//
//  PPOnboardingViewController.m
//  PhotoPurge
//

#import "PPOnboardingViewController.h"
#import "PPSwipeViewController.h"
#import "PPTheme.h"
#import <Photos/Photos.h>

@interface PPOnboardingViewController ()

@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, assign) NSInteger denialCount;

@end

@implementation PPOnboardingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [PPTheme canvasBackgroundColor];
    self.denialCount = 0;
    
    [self setupUI];
    [self checkInitialPhotoAuthorization];
}

- (void)setupUI {
    // Initialize Label
    self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 200, self.view.bounds.size.width - 48, 100)];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    self.messageLabel.textColor = [PPTheme primaryTextColor];
    self.messageLabel.text = @"Welcome to PhotoPurge. We need access to your library to begin.";
    [self.view addSubview:self.messageLabel];
    
    // Initialize Button
    self.actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.actionButton.frame = CGRectMake(48, 320, self.view.bounds.size.width - 96, 50);
    self.actionButton.backgroundColor = [PPTheme undoActionColor];
    [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    self.actionButton.layer.cornerRadius = 14.0;
    self.actionButton.clipsToBounds = YES;
    [self.actionButton setTitle:@"Grant Access" forState:UIControlStateNormal];
    
    // Add target-action for button tap
    [self.actionButton addTarget:self
                          action:@selector(actionButtonTapped)
                forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.actionButton];
}

- (void)checkInitialPhotoAuthorization {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    [self handleAuthorizationStatus:status];
}

- (void)actionButtonTapped {
    if (self.denialCount >= 2) {
        // Deep-link to app settings via UIApplicationOpenSettingsURLString
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:settingsURL]) {
            [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
        }
    } else {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
            // UI updates must be dispatched to the main thread.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleAuthorizationStatus:status];
            });
        }];
    }
}

- (void)handleAuthorizationStatus:(PHAuthorizationStatus)status {
    switch (status) {
        case PHAuthorizationStatusNotDetermined:
            // Waiting for user action
            break;
            
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied:
            self.denialCount++;
            if (self.denialCount >= 2) {
                self.messageLabel.text = @"Photo access is required. Please enable it in Settings.";
                [self.actionButton setTitle:@"Open Settings" forState:UIControlStateNormal];
            } else {
                self.messageLabel.text = @"Access denied. PhotoPurge cannot work without access to your photos.";
                [self.actionButton setTitle:@"Try Again" forState:UIControlStateNormal];
            }
            break;
            
        case PHAuthorizationStatusLimited:
            self.messageLabel.text = @"Limited access granted. Proceeding to swipe screen...";
            self.actionButton.hidden = YES;
            [self transitionToSwipeScreen];
            break;
            
        case PHAuthorizationStatusAuthorized:
            self.messageLabel.text = @"Access granted. Proceeding to swipe screen...";
            self.actionButton.hidden = YES;
            [self transitionToSwipeScreen];
            break;
    }
}

- (void)transitionToSwipeScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Fallback window resolution: if self.view.window is nil, query the connected UIWindowScene
        UIWindow *window = self.view.window;
        if (!window) {
            UIWindowScene *scene = (UIWindowScene *)[[[UIApplication sharedApplication] connectedScenes] anyObject];
            window = scene.windows.firstObject;
        }
        
        if (!window) return;

        PPSwipeViewController *swipeVC = [[PPSwipeViewController alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:swipeVC];
        
        // Animation to the new root
        [UIView transitionWithView:window
                          duration:0.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            window.rootViewController = navController;
        } completion:nil];
    });
}

@end
