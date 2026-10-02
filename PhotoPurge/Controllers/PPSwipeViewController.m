//
//  PPSwipeViewController.m
//  PhotoPurge
//

#import "PPSwipeViewController.h"
#import "PPCardView.h"
#import "PPCompletionView.h"
#import "PPPermissionView.h"
#import <Photos/Photos.h>

typedef NS_ENUM(NSInteger, PPSwipeActionType) {
    PPSwipeActionTypeKeep,
    PPSwipeActionTypePurge
};

@interface PPSwipeHistoryItem : NSObject

@property (nonatomic, assign) PPSwipeActionType actionType;
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, assign) NSUInteger originalIndex;

+ (instancetype)itemWithAction:(PPSwipeActionType)action
                         asset:(PHAsset *)asset
                         index:(NSUInteger)index;

@end

@implementation PPSwipeHistoryItem

+ (instancetype)itemWithAction:(PPSwipeActionType)action
                         asset:(PHAsset *)asset
                         index:(NSUInteger)index {
    PPSwipeHistoryItem *item = [[PPSwipeHistoryItem alloc] init];
    item.actionType = action;
    item.asset = asset;
    item.originalIndex = index;
    return item;
}

@end

@interface PPSwipeViewController () <PPCardViewDelegate, PPCompletionViewDelegate, PPPermissionViewDelegate, PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) PHFetchResult<PHAsset *> *assets;
@property (nonatomic, strong, nullable) PPCardView *topCardView;
@property (nonatomic, strong, nullable) PPCardView *bottomCardView;
@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *pendingDeletionAssets;
@property (nonatomic, strong) NSMutableArray<PPSwipeHistoryItem *> *actionHistory;
@property (nonatomic, strong) UIButton *undoButton;
@property (nonatomic, strong) UIButton *confirmDeleteButton;
@property (nonatomic, strong) UILabel *trashBadgeLabel;
@property (nonatomic, strong) UIButton *purgeButton;
@property (nonatomic, strong) UIButton *keepButton;
@property (nonatomic, strong, nullable) PPCompletionView *completionView;
@property (nonatomic, strong, nullable) PPPermissionView *permissionView;

@end

@implementation PPSwipeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemGray6Color];
    self.title = @"PhotoPurge";
    self.currentIndex = 0;
    self.pendingDeletionAssets = [[NSMutableArray alloc] init];
    self.actionHistory = [[NSMutableArray alloc] init];
    
    [self setupActionButtons];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [self evaluatePhotoAuthorizationStatus];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)applicationWillEnterForeground {
    // Re-check permission if user altered settings while in background
    [self evaluatePhotoAuthorizationStatus];
}

- (void)loadPhotoLibraryAssets {
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    
    // Sort by creationDate in descending order
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    
    self.assets = [PHAsset fetchAssetsWithOptions:options];
    self.currentIndex = 0;
    
    NSLog(@"PhotoPurge: Successfully loaded %lu assets.", (unsigned long)self.assets.count);
    
    [self setupInitialStack];
}

#pragma mark - Stack Geometry & Instantiation

- (CGRect)cardFrame {
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;
    
    CGFloat cardWidth = screenWidth - 40.0;
    CGFloat cardHeight = screenHeight * 0.60;
    CGFloat cardX = 20.0;
    CGFloat cardY = (screenHeight - cardHeight) / 2.0 - 15.0;
    
    return CGRectMake(cardX, cardY, cardWidth, cardHeight);
}

- (nullable PPCardView *)createCardForIndex:(NSUInteger)index isInteractive:(BOOL)isInteractive {
    if (index >= self.assets.count) {
        return nil;
    }
    
    PHAsset *asset = self.assets[index];
    PPCardView *cardView = [[PPCardView alloc] initWithFrame:[self cardFrame]];
    cardView.assetIdentifier = asset.localIdentifier;
    cardView.delegate = isInteractive ? self : nil;
    cardView.userInteractionEnabled = isInteractive;
    
    [cardView configureMetadataWithAsset:asset];
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES; // Incase iCloud is needed
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    CGSize targetSize = CGSizeMake(cardView.bounds.size.width * [UIScreen mainScreen].scale,
                                   cardView.bounds.size.height * [UIScreen mainScreen].scale);
    
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:targetSize
                                              contentMode:PHImageContentModeAspectFill
                                                  options:options
                                            resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result && [cardView.assetIdentifier isEqualToString:asset.localIdentifier]) {
                [cardView configureWithImage:result];
            }
        });
    }];
    
    return cardView;
}

#pragma mark - Stack Management

- (void)setupInitialStack {
    if (self.assets.count == 0) return;
    
    // Create bottom card first if a second asset exists
    if (self.assets.count > 1) {
        self.bottomCardView = [self createCardForIndex:self.currentIndex + 1 isInteractive:NO];
        if (self.bottomCardView) {
            self.bottomCardView.transform = CGAffineTransformMakeScale(0.95, 0.95);
            [self.view addSubview:self.bottomCardView];
        }
    }
    
    // Create top card and place it above bottom card
    self.topCardView = [self createCardForIndex:self.currentIndex isInteractive:YES];
    if (self.topCardView) {
        [self.view addSubview:self.topCardView];
    }
}

- (void)advanceStack {
    self.currentIndex++;
    
    // Promote bottomCardView to topCardView
    self.topCardView = self.bottomCardView;
    self.bottomCardView = nil;
    
    if (self.topCardView) {
        self.topCardView.userInteractionEnabled = YES;
        self.topCardView.delegate = self;
        
        // Animate bottom card expanding to full size
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.topCardView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
    
    // Prepare next bottom card in background
    NSUInteger nextIndex = self.currentIndex + 1;
    if (nextIndex < self.assets.count) {
        self.bottomCardView = [self createCardForIndex:nextIndex isInteractive:NO];
        if (self.bottomCardView) {
            self.bottomCardView.transform = CGAffineTransformMakeScale(0.95, 0.95);
            
            // Insert underneath the current top card
            if (self.topCardView) {
                [self.view insertSubview:self.bottomCardView belowSubview:self.topCardView];
            } else {
                [self.view addSubview:self.bottomCardView];
            }
        }
    } else if (!self.topCardView) {
        [self showCompletionView];
    }
}

#pragma mark - PPCardViewDelegate

- (void)cardViewDidSwipeLeft:(PPCardView *)cardView {
    if (self.currentIndex < self.assets.count) {
        PHAsset *swipedAsset = self.assets[self.currentIndex];
        [self.pendingDeletionAssets addObject:swipedAsset];
        PPSwipeHistoryItem *item = [PPSwipeHistoryItem itemWithAction:PPSwipeActionTypePurge
                                                                asset:swipedAsset
                                                                index:self.currentIndex];
        [self.actionHistory addObject:item];
    }
    
    [self advanceStack];
    [self updateControlClusterStates];
}

- (void)cardViewDidSwipeRight:(PPCardView *)cardView {
    if (self.currentIndex < self.assets.count) {
        PHAsset *swipedAsset = self.assets[self.currentIndex];
        PPSwipeHistoryItem *item = [PPSwipeHistoryItem itemWithAction:PPSwipeActionTypeKeep
                                                                asset:swipedAsset
                                                                index:self.currentIndex];
        [self.actionHistory addObject:item];
    }
    
    [self advanceStack];
    [self updateControlClusterStates];
}

#pragma mark - Action Buttons

- (void)setupActionButtons {
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;
    
    CGRect cardRect = [self cardFrame];
    CGFloat cardBottom = CGRectGetMaxY(cardRect);
    
    // Account for safe area bottom (Home indicator)
    CGFloat bottomInset = self.view.safeAreaInsets.bottom;
    if (bottomInset == 0) {
        bottomInset = 20.0; // Fallback bottom padding for older devices / SE
    }
    
    // The exact usable vertical space between card bottom and home indicator
    CGFloat usableBottomY = screenHeight - bottomInset;
    CGFloat availableHeight = usableBottomY - cardBottom;
    
    // Center the diamond
    CGFloat centerX = screenWidth / 2.0;
    CGFloat centerY = cardBottom + (availableHeight / 2.0);
    
    // Geometry Constants
    CGFloat primaryDiameter = 56.0;   // Left (Purge) & right (Keep)
    CGFloat secondaryDiameter = 44.0; // Top (Restore) & bottom (Confirm)
    
    // Radial offsets from center point
    CGFloat horizontalOffset = 60.0;
    CGFloat verticalOffset = 36.0;
    
    // Common shadow configuration helper
    void (^applyButtonStyling)(UIButton *, CGFloat) = ^(UIButton *btn, CGFloat diameter) {
        btn.backgroundColor = [UIColor whiteColor];
        btn.layer.cornerRadius = diameter / 2.0;
        btn.layer.shadowColor = [UIColor blackColor].CGColor;
        btn.layer.shadowOpacity = 0.14;
        btn.layer.shadowRadius = 5.0;
        btn.layer.shadowOffset = CGSizeMake(0, 3);
    };
    
    // Undo Button (middle up, orange)
    self.undoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.undoButton.frame = CGRectMake(centerX - (secondaryDiameter / 2.0),
                                       centerY - verticalOffset - (secondaryDiameter / 2.0),
                                       secondaryDiameter,
                                       secondaryDiameter);
    applyButtonStyling(self.undoButton, secondaryDiameter);
    self.undoButton.tintColor = [UIColor systemOrangeColor];
    
    UIImageSymbolConfiguration *undoConfig = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightBold];
    [self.undoButton setImage:[UIImage systemImageNamed:@"arrow.uturn.backward" withConfiguration:undoConfig] forState:UIControlStateNormal];
    [self.undoButton addTarget:self action:@selector(undoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.undoButton];
    
    // Purge Button (left, red X mark icon)
    self.purgeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.purgeButton.frame = CGRectMake(centerX - horizontalOffset - (primaryDiameter / 2.0),
                                        centerY - (primaryDiameter / 2.0),
                                        primaryDiameter,
                                        primaryDiameter);
    applyButtonStyling(self.purgeButton, primaryDiameter);
    self.purgeButton.tintColor = [UIColor systemRedColor];
    
    UIImageSymbolConfiguration *xConfig = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightHeavy];
    [self.purgeButton setImage:[UIImage systemImageNamed:@"xmark" withConfiguration:xConfig] forState:UIControlStateNormal];
    [self.purgeButton addTarget:self action:@selector(purgeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.purgeButton];
    
    // Keep Button (right, green checkmark icon)
    self.keepButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.keepButton.frame = CGRectMake(centerX + horizontalOffset - (primaryDiameter / 2.0),
                                       centerY - (primaryDiameter / 2.0),
                                       primaryDiameter,
                                       primaryDiameter);
    applyButtonStyling(self.keepButton, primaryDiameter);
    self.keepButton.tintColor = [UIColor systemGreenColor];
    
    UIImageSymbolConfiguration *checkConfig = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightBold];
    [self.keepButton setImage:[UIImage systemImageNamed:@"checkmark" withConfiguration:checkConfig] forState:UIControlStateNormal];
    [self.keepButton addTarget:self action:@selector(keepButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.keepButton];
    
    // Confirm button (middle down, red trash icon)
    self.confirmDeleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.confirmDeleteButton.frame = CGRectMake(centerX - (secondaryDiameter / 2.0),
                                                centerY + verticalOffset - (secondaryDiameter / 2.0),
                                                secondaryDiameter,
                                                secondaryDiameter);
    applyButtonStyling(self.confirmDeleteButton, secondaryDiameter);
    self.confirmDeleteButton.tintColor = [UIColor systemRedColor];
    
    UIImageSymbolConfiguration *trashConfig = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold];
    [self.confirmDeleteButton setImage:[UIImage systemImageNamed:@"trash.fill" withConfiguration:trashConfig] forState:UIControlStateNormal];
    [self.confirmDeleteButton addTarget:self action:@selector(confirmDeleteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.confirmDeleteButton];
    
    // Staged items count badge (attached to top-right corner of confirm button)
    CGFloat badgeSize = 18.0;
    self.trashBadgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(secondaryDiameter - (badgeSize / 2.0) - 1.0,
                                                                     -(badgeSize / 2.0) + 1.0,
                                                                     badgeSize,
                                                                     badgeSize)];
    self.trashBadgeLabel.backgroundColor = [UIColor systemRedColor];
    self.trashBadgeLabel.textColor = [UIColor whiteColor];
    self.trashBadgeLabel.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightBold];
    self.trashBadgeLabel.textAlignment = NSTextAlignmentCenter;
    self.trashBadgeLabel.layer.cornerRadius = badgeSize / 2.0;
    self.trashBadgeLabel.layer.masksToBounds = YES;
    self.trashBadgeLabel.hidden = YES;
    [self.confirmDeleteButton addSubview:self.trashBadgeLabel];
    
    
    [self updateControlClusterStates];
}

- (void)updateControlClusterStates {
    BOOL isPermitted = (self.permissionView == nil);
    BOOL isAtCompletion = (self.completionView != nil);
    
    // Update keep / purge states
    BOOL canSwipeCards = isPermitted && !isAtCompletion && (self.topCardView != nil);
    self.purgeButton.enabled = canSwipeCards;
    self.purgeButton.alpha = canSwipeCards ? 1.0 : 0.35;
    
    self.keepButton.enabled = canSwipeCards;
    self.keepButton.alpha = canSwipeCards ? 1.0 : 0.35;
    
    // Update undo state
    BOOL canUndo = isPermitted && (self.actionHistory.count > 0);
    self.undoButton.enabled = canUndo;
    self.undoButton.alpha = canUndo ? 1.0 : 0.35;
    
    // Update confirm deletion state and badge counter
    NSUInteger stagedCount = self.pendingDeletionAssets.count;
    BOOL canConfirm = isPermitted && (stagedCount > 0);
    self.confirmDeleteButton.enabled = canConfirm;
    self.confirmDeleteButton.alpha = canConfirm ? 1.0 : 0.35;
    
    if (stagedCount > 0 && isPermitted) {
        self.trashBadgeLabel.hidden = NO;
        self.trashBadgeLabel.text = stagedCount > 99 ? @"99+" : [NSString stringWithFormat:@"%lu", (unsigned long)stagedCount];
    } else {
        self.trashBadgeLabel.hidden = YES;
    }
}

- (void)undoButtonTapped {
    if (self.actionHistory.count == 0) {
        return;
    }
    
    // Dismiss completion card (if visible)
    if (self.completionView) {
        [self.completionView removeFromSuperview];
        self.completionView = nil;
    }
    
    // Pop last recorded valid action
    PPSwipeHistoryItem *lastItem = self.actionHistory.lastObject;
    [self.actionHistory removeLastObject];
    
    // Revert deletion staging if needed
    if (lastItem.actionType == PPSwipeActionTypePurge && [self.pendingDeletionAssets containsObject:lastItem.asset]) {
        [self.pendingDeletionAssets removeObject:lastItem.asset];
    }
    
    // Roll back to that specific asset's index
    self.currentIndex = lastItem.originalIndex;
    
    // Demote top card to bottom card
    if (self.bottomCardView) {
        [self.bottomCardView removeFromSuperview];
        self.bottomCardView = nil;
    }
    
    if (self.topCardView) {
        self.bottomCardView = self.topCardView;
        self.bottomCardView.userInteractionEnabled = NO;
        self.bottomCardView.delegate = nil;
        
        [UIView animateWithDuration:0.2 animations:^{
            self.bottomCardView.transform = CGAffineTransformMakeScale(0.95, 0.95);
        }];
    }
    
    // Animate restored card back onto the stack
    PPCardView *restoredCard = [self createCardForIndex:self.currentIndex isInteractive:YES];
    if (restoredCard) {
        self.topCardView = restoredCard;
        
        CGFloat offscreenX = (lastItem.actionType == PPSwipeActionTypeKeep) ?
            [UIScreen mainScreen].bounds.size.width * 1.5 :
            -[UIScreen mainScreen].bounds.size.width;
            
        restoredCard.center = CGPointMake(offscreenX, restoredCard.center.y);
        [self.view addSubview:restoredCard];
        
        [UIView animateWithDuration:0.35
                              delay:0.0
             usingSpringWithDamping:0.8
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            restoredCard.frame = [self cardFrame];
        } completion:nil];
    }
    
    [self updateControlClusterStates];
}

- (void)purgeButtonTapped {
    if (self.topCardView) {
        [self.topCardView swipeLeftProgrammatically];
    }
}

- (void)keepButtonTapped {
    if (self.topCardView) {
        [self.topCardView swipeRightProgrammatically];
    }
}

- (void)confirmDeleteButtonTapped {
    if (self.pendingDeletionAssets.count == 0) {
        return;
    }
    
    [self presentBatchDeletionAlert];
}

#pragma mark - Batch Deletion Pipeline

- (void)presentBatchDeletionAlert {
    NSUInteger count = self.pendingDeletionAssets.count;
    NSString *title = [NSString stringWithFormat:@"Purge %lu Photos?", (unsigned long)count];
    NSString *message = @"These photos will be submitted to Photos for deletion.";
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Delete %lu Photos", (unsigned long)count]
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
        [self executePhotoLibraryDeletion];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    
    // For iPad compatibility where action sheets require a popover presentation anchor
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.confirmDeleteButton;
        alert.popoverPresentationController.sourceRect = self.confirmDeleteButton.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)executePhotoLibraryDeletion {
    NSArray<PHAsset *> *assetsToDelete = [self.pendingDeletionAssets copy];
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // Requests OS deletion sheet from user
        [PHAssetChangeRequest deleteAssets:assetsToDelete];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                NSLog(@"PhotoPurge: Successfully deleted %lu assets from device.", (unsigned long)assetsToDelete.count);
                
                // Clear the staging queue
                [self.pendingDeletionAssets removeAllObjects];
                
                // Filter out items whose assets were deleted
                NSPredicate *keepPredicate = [NSPredicate predicateWithBlock:^BOOL(PPSwipeHistoryItem *item, NSDictionary *bindings) {
                    return ![assetsToDelete containsObject:item.asset];
                }];
                [self.actionHistory filterUsingPredicate:keepPredicate];
                
                // Update controls
                [self updateControlClusterStates];
                
                // Provide success haptic
                UINotificationFeedbackGenerator *notifier = [[UINotificationFeedbackGenerator alloc] init];
                [notifier notificationOccurred:UINotificationFeedbackTypeSuccess];
            } else if (error) {
                NSLog(@"PhotoPurge: Error deleting assets: %@", error.localizedDescription);
            }
        });
    }];
}

#pragma mark - Completion Card Management

- (void)showCompletionView {
    if (self.completionView) {
        [self.completionView removeFromSuperview];
    }
    
    CGRect frame = [self cardFrame];
    self.completionView = [[PPCompletionView alloc] initWithFrame:frame];
    self.completionView.delegate = self;
    self.completionView.alpha = 0.0;
    
    [self.completionView configureWithTotalReviewed:self.assets.count
                                       pendingCount:self.pendingDeletionAssets.count];
    
    [self.view addSubview:self.completionView];
    
    [self updateControlClusterStates];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.completionView.alpha = 1.0;
    }];
}

#pragma mark - PPCompletionViewDelegate

- (void)completionViewDidRequestPurge:(PPCompletionView *)completionView {
    [self presentBatchDeletionAlert];
}

- (void)completionViewDidRequestRestart:(PPCompletionView *)completionView {
    [UIView animateWithDuration:0.2 animations:^{
        self.completionView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.completionView removeFromSuperview];
        self.completionView = nil;
        
        self.currentIndex = 0;
        [self.pendingDeletionAssets removeAllObjects];
        [self.actionHistory removeAllObjects];
        
        [self setupInitialStack];
        [self updateControlClusterStates];
    }];
}

#pragma mark - Authorization Lifecycle

- (void)evaluatePhotoAuthorizationStatus {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (status) {
            case PHAuthorizationStatusAuthorized:
            case PHAuthorizationStatusLimited: {
                // Access granted, dismiss any permission view and load assets
                [self dismissPermissionView];
                if (!self.assets) {
                    [self loadPhotoLibraryAssets];
                }
                [self updateControlClusterStates];
                break;
            }
            case PHAuthorizationStatusNotDetermined: {
                [self showPermissionViewWithState:PPPermissionViewStatePrompt];
                [self updateControlClusterStates];
                break;
            }
            case PHAuthorizationStatusDenied:
            case PHAuthorizationStatusRestricted: {
                [self showPermissionViewWithState:PPPermissionViewStateDenied];
                [self updateControlClusterStates];
                break;
            }
        }
    });
}

- (void)showPermissionViewWithState:(PPPermissionViewState)state {
    if (!self.permissionView) {
        self.permissionView = [[PPPermissionView alloc] initWithFrame:[self cardFrame]];
        self.permissionView.delegate = self;
        [self.view addSubview:self.permissionView];
    }
    
    [self.permissionView configureForState:state];
    self.permissionView.hidden = NO;
    
    // Hide active cards while permission card is shown
    self.topCardView.hidden = YES;
    self.bottomCardView.hidden = YES;
}

- (void)dismissPermissionView {
    if (self.permissionView) {
        [self.permissionView removeFromSuperview];
        self.permissionView = nil;
    }
    
    self.topCardView.hidden = NO;
    self.bottomCardView.hidden = NO;
}

#pragma mark - PPPermissionViewDelegate

- (void)permissionViewDidRequestAuthorization:(PPPermissionView *)permissionView {
    [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self evaluatePhotoAuthorizationStatus];
        });
    }];
}

- (void)permissionViewDidRequestOpenSettings:(PPPermissionView *)permissionView {
    NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:settingsURL]) {
        [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
    }
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:self.assets];
    if (!changeDetails) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Snapshot previous state before applying changes
        NSArray<PHAsset *> *removedObjects = [changeDetails removedObjects];
        NSIndexSet *insertedIndexes = [changeDetails insertedIndexes];
        
        // Commit updated fetch result
        self.assets = [changeDetails fetchResultAfterChanges];
        
        // Reconcile Staged Deletions (remove assets deleted outside the app)
        if (self.pendingDeletionAssets.count > 0 && removedObjects.count > 0) {
            [self.pendingDeletionAssets removeObjectsInArray:removedObjects];
        }
        
        // Reconcile Action History (prune references to externally deleted photos)
        if (self.actionHistory.count > 0 && removedObjects.count > 0) {
            NSPredicate *validAssetPredicate = [NSPredicate predicateWithBlock:^BOOL(PPSwipeHistoryItem *item, NSDictionary *bindings) {
                return ![removedObjects containsObject:item.asset];
            }];
            [self.actionHistory filterUsingPredicate:validAssetPredicate];
        }
        
        // Handle empty library state
        if (self.assets.count == 0) {
            [self.topCardView removeFromSuperview];
            self.topCardView = nil;
            [self.bottomCardView removeFromSuperview];
            self.bottomCardView = nil;
            [self showCompletionView];
            [self updateControlClusterStates];
            return;
        }
        
        // Handle restorations & insertions
        BOOL didInsertVisibleOrPrecedingAsset = NO;
        
        if (insertedIndexes.count > 0) {
            NSUInteger lowestInsertedIndex = [insertedIndexes firstIndex];
            
            // If the restored/added asset was placed at or before our current view position
            if (lowestInsertedIndex <= self.currentIndex) {
                // Rewind currentIndex to the restored photo so it immediately appears on top
                self.currentIndex = lowestInsertedIndex;
                didInsertVisibleOrPrecedingAsset = YES;
            } else if (lowestInsertedIndex == self.currentIndex + 1) {
                // Restored directly underneath the top card (into bottom card slot)
                didInsertVisibleOrPrecedingAsset = YES;
            }
        }
        
        // Check if visible cards were deleted
        BOOL topCardDeleted = NO;
        for (PHAsset *removed in removedObjects) {
            if (self.topCardView && [self.topCardView.assetIdentifier isEqualToString:removed.localIdentifier]) {
                topCardDeleted = YES;
                break;
            }
        }
        
        // Dismiss completion view if assets are now available
        if (self.completionView && self.assets.count > 0 && self.currentIndex < self.assets.count) {
            [self.completionView removeFromSuperview];
            self.completionView = nil;
        }
        
        // Clamp index to valid bounds
        if (self.currentIndex >= self.assets.count) {
            self.currentIndex = (self.assets.count > 0) ? (self.assets.count - 1) : 0;
        }
        
        // Rebuild stack if top card was deleted, an asset was restored into view,
        // or a general non-incremental collection reload happened
        if (topCardDeleted || didInsertVisibleOrPrecedingAsset || ![changeDetails hasIncrementalChanges]) {
            [UIView transitionWithView:self.view
                              duration:0.25
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                if (self.topCardView) {
                    [self.topCardView removeFromSuperview];
                    self.topCardView = nil;
                }
                if (self.bottomCardView) {
                    [self.bottomCardView removeFromSuperview];
                    self.bottomCardView = nil;
                }
                [self setupInitialStack];
            } completion:nil];
        }
        
        [self updateControlClusterStates];
    });
}

@end
