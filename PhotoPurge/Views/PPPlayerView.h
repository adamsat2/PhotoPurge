//
//  PPPlayerView.h
//  PhotoPurge
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PPPlayerView : UIView

@property (nonatomic, strong, nullable) AVPlayer *player;
@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

@end

NS_ASSUME_NONNULL_END
