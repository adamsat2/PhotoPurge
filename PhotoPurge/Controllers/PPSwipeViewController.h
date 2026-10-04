//
//  PPSwipeViewController.h
//  PhotoPurge
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PPPhotoFilterType) {
    PPPhotoFilterTypeAllPhotos,
    PPPhotoFilterTypeScreenshots,
    PPPhotoFilterTypeVideos,
    PPPhotoFilterTypeLivePhotos
};

@interface PPSwipeViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
