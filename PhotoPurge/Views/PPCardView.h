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

- (void)configureWithImage:(UIImage *)image;
- (void)configureMetadataWithAsset:(PHAsset *)asset;
- (void)swipeLeftProgrammatically;
- (void)swipeRightProgrammatically;

@end

NS_ASSUME_NONNULL_END
