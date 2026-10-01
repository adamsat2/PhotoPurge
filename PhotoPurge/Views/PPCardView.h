//
//  PPCardView.h
//  PhotoPurge
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PPCardView;

@protocol PPCardViewDelegate <NSObject>

- (void)cardViewDidSwipeLeft:(PPCardView *)cardView;
- (void)cardViewDidSwipeRight:(PPCardView *)cardView;

@end

@interface PPCardView : UIView

@property (nonatomic, weak, nullable) id<PPCardViewDelegate> delegate; // Weak to avoid a retain cycle

- (void)configureWithImage:(UIImage *)image;
- (void)swipeLeftProgrammatically;
- (void)swipeRightProgrammatically;

@end

NS_ASSUME_NONNULL_END
