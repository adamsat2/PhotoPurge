//
//  PPSwipeViewController.m
//  PhotoPurge
//

#import "PPSwipeViewController.h"
#import "PPCardView.h"
#import <Photos/Photos.h>

@interface PPSwipeViewController () <PPCardViewDelegate>

@property (nonatomic, strong) PHFetchResult<PHAsset *> *assets;
@property (nonatomic, strong) PPCardView *currentCardView;
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
    
    [self displayTopCard];
}

- (void)displayTopCard {
    if (self.assets.count == 0 || self.currentIndex >= self.assets.count) {
        NSLog(@"PhotoPurge: Reached end of asset queue or library is empty.");
        self.currentCardView = nil;
        return;
    }
    
    PHAsset *firstAsset = self.assets[self.currentIndex];
    
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;
    
    CGFloat cardWidth = screenWidth - 40.0;
    CGFloat cardHeight = screenHeight * 0.65;
    CGFloat cardX = 20.0;
    CGFloat cardY = (screenHeight - cardHeight) / 2.0;
    
    CGRect cardFrame = CGRectMake(cardX, cardY, cardWidth, cardHeight);
    
    self.currentCardView = [[PPCardView alloc] initWithFrame:cardFrame];
    self.currentCardView.delegate = self;
    [self.view addSubview:self.currentCardView];
    
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    requestOptions.networkAccessAllowed = YES; // Allows download from iCloud should it be needed
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize targetSize = CGSizeMake(cardWidth * scale, cardHeight * scale);
    
    [[PHImageManager defaultManager] requestImageForAsset:firstAsset
                                               targetSize:targetSize
                                              contentMode:PHImageContentModeAspectFill
                                                  options:requestOptions
                                            resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                [self.currentCardView configureWithImage:result];
            }
        });
    }];
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
    
    self.currentIndex++;
    [self displayTopCard];
}

- (void)cardViewDidSwipeRight:(PPCardView *)cardView {
    NSLog(@"PhotoPurge: Kept asset %lu.", (unsigned long)self.currentIndex);
    
    self.currentIndex++;
    [self displayTopCard];
}

@end
