//
//  PPSwipeViewController.m
//  PhotoPurge
//

#import "PPSwipeViewController.h"
#import <Photos/Photos.h>

@interface PPSwipeViewController ()

@property (nonatomic, strong) PHFetchResult<PHAsset *> *assets;

@end

@implementation PPSwipeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemGray6Color];
    self.title = @"PhotoPurge";
    
    [self loadPhotoLibraryAssets];
}

- (void)loadPhotoLibraryAssets {
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    
    // Sort by creationDate in descending order
    NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
    options.sortDescriptors = @[dateSort];
    
    self.assets = [PHAsset fetchAssetsWithOptions:options];
    
    NSLog(@"PhotoPurge: Successfully loaded %lu assets.", (unsigned long)self.assets.count);
}

@end
