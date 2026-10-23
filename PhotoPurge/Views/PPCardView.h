//
//  PPCardView.h
//  PhotoPurge
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class PPCardView;

@protocol PPCardViewDelegate <NSObject>

- (void)cardViewDidSwipeLeft:(PPCardView *)cardView;
- (void)cardViewDidSwipeRight:(PPCardView *)cardView;

@end

@interface PPCardView : UIView

@property (nonatomic, weak, nullable) id<PPCardViewDelegate> delegate; // Weak to avoid a retain cycle
@property (nonatomic, copy, nullable) NSString *assetIdentifier;
@property (nonatomic, assign) PHImageRequestID imageRequestID;
@property (nonatomic, assign) BOOL isDismissing;
@property (nonatomic, strong, readonly) UIImpactFeedbackGenerator *feedbackGenerator;

- (void)configureWithImage:(UIImage *)image;
- (void)configureMetadataWithAsset:(PHAsset *)asset;
- (void)prepareRunningMediaWithAsset:(PHAsset *)asset cachingManager:(PHCachingImageManager *)imageManager;
- (void)startMediaPlayback;
- (void)pauseMediaPlayback;
- (void)tearDownMediaPlayback;
- (void)swipeLeftProgrammatically;
- (void)swipeRightProgrammatically;
- (void)animateOffScreenToLeftWithCompletion:(nullable void (^)(void))completion;
- (void)animateOffScreenToRightWithCompletion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
