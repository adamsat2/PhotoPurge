//
//  PPPlayerView.m
//  PhotoPurge
//

#import "PPPlayerView.h"

@implementation PPPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return self;
}

- (AVPlayer *)player {
    return self.playerLayer.player;
}

- (void)setPlayer:(nullable AVPlayer *)player {
    self.playerLayer.player = player;
}

@end
