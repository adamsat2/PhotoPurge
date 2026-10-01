//
//  PPSwipeViewController.m
//  PhotoPurge
//

#import "PPSwipeViewController.h"
#import "PPCardView.h"
#import <Photos/Photos.h>

@interface PPSwipeViewController () <PPCardViewDelegate>

@property (nonatomic, strong) PHFetchResult<PHAsset *> *assets;
@property (nonatomic, strong, nullable) PPCardView *topCardView;
@property (nonatomic, strong, nullable) PPCardView *bottomCardView;
@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, strong) NSMutableArray<PHAsset *> *pendingDeletionAssets;

@end

@implementation PPSwipeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemGray6Color];
    self.title = @"PhotoPurge";
    self.currentIndex = 0;
    self.pendingDeletionAssets = [[NSMutableArray alloc] init];
    
    [self loadPhotoLibraryAssets];
}

- (void)loadPhotoLibraryAssets {
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    
    // Sort by creationDate in descending order
    NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
    options.sortDescriptors = @[dateSort];
    
    self.assets = [PHAsset fetchAssetsWithOptions:options];
    
    NSLog(@"PhotoPurge: Successfully loaded %lu assets.", (unsigned long)self.assets.count);
    
    [self setupInitialStack];
}

#pragma mark - Stack Geometry & Instantiation

- (CGRect)cardFrame {
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;
    
    CGFloat cardWidth = screenWidth - 40.0;
    CGFloat cardHeight = screenHeight * 0.65;
    CGFloat cardX = 20.0;
    CGFloat cardY = (screenHeight - cardHeight) / 2.0;
    
    return CGRectMake(cardX, cardY, cardWidth, cardHeight);
}

- (PPCardView *)createCardForIndex:(NSUInteger)index isInteractive:(BOOL)isInteractive {
    if (index >= self.assets.count) {
        return nil;
    }
    
    CGRect frame = [self cardFrame];
    PPCardView *card = [[PPCardView alloc] initWithFrame:frame];
    card.userInteractionEnabled = isInteractive;
    if (isInteractive) {
        card.delegate = self;
    }
    
    PHAsset *asset = self.assets[index];
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    requestOptions.networkAccessAllowed = YES; // Allows download from iCloud should it be needed
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize targetSize = CGSizeMake(frame.size.width * scale, frame.size.height * scale);
    
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:targetSize
                                              contentMode:PHImageContentModeAspectFill
                                                  options:requestOptions
                                            resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                [card configureWithImage:result];
            }
        });
    }];
    
    return card;
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
    }
}

#pragma mark - PPCardViewDelegate

- (void)cardViewDidSwipeLeft:(PPCardView *)cardView {
    if (self.currentIndex < self.assets.count) {
        PHAsset *swipedAsset = self.assets[self.currentIndex];
        [self.pendingDeletionAssets addObject:swipedAsset];
        NSLog(@"PhotoPurge: Marked asset %lu for deletion. Staged count: %lu",
              (unsigned long)self.currentIndex,
              (unsigned long)self.pendingDeletionAssets.count);
    }
    
    [self advanceStack];
}

- (void)cardViewDidSwipeRight:(PPCardView *)cardView {
    NSLog(@"PhotoPurge: Kept asset %lu.", (unsigned long)self.currentIndex);
    
    [self advanceStack];
}

@end
