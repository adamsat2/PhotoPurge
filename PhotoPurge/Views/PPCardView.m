//
//  PPCardView.m
//  PhotoPurge
//

#import "PPCardView.h"
#import "PPPlayerView.h"
#import <PhotosUI/PhotosUI.h>
#import <AVFoundation/AVFoundation.h>

@interface PPCardView () <PHLivePhotoViewDelegate>

// The image view is kept private inside the .m file so outside classes can't mess with it directly
// Private View Hierarchy
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) CGPoint originalCenter;
@property (nonatomic, strong) UILabel *keepBadgeLabel;
@property (nonatomic, strong) UILabel *deleteBadgeLabel;
@property (nonatomic, strong) UIView *colorOverlayView;
@property (nonatomic, strong) UIImpactFeedbackGenerator *feedbackGenerator;
@property (nonatomic, assign) BOOL hasTriggeredThresholdHaptic;

// Metadata Overlay
@property (nonatomic, strong) UIVisualEffectView *metadataPillView;
@property (nonatomic, strong) UIStackView *metadataStackView;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIView *mediaTypeBadgeContainer;
@property (nonatomic, strong) UILabel *mediaTypeBadgeLabel;

// Running Media Elements
@property (nonatomic, strong) PHLivePhotoView *livePhotoView;
@property (nonatomic, strong) PPPlayerView *videoPlayerView;
@property (nonatomic, strong, nullable) AVPlayer *player;
@property (nonatomic, strong, nullable) id playerEndObserver;
@property (nonatomic, strong, nullable) PHAsset *associatedAsset;

// Audio Pill
@property (nonatomic, strong) UIVisualEffectView *volumePillView;
@property (nonatomic, strong) UIButton *volumeButton;
@property (nonatomic, assign) BOOL isMuted;

// Gestures
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UILongPressGestureRecognizer *livePhotoGesture;

@end

@implementation PPCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.isMuted = YES;
        
        // Card styling
        self.layer.cornerRadius = 16.0;
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowOpacity = 0.2;
        self.layer.shadowRadius = 8.0;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        
        // Init image view to fill the card's bounds
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.layer.cornerRadius = 16.0; // Matches the card's corner radius
        // Ensure the image view resizes automatically if the card's frame changes
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_imageView];
        
        // Init video player view
        _videoPlayerView = [[PPPlayerView alloc] initWithFrame:self.bounds];
        _videoPlayerView.layer.cornerRadius = 16.0;
        _videoPlayerView.clipsToBounds = YES;
        _videoPlayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _videoPlayerView.hidden = YES;
        _videoPlayerView.alpha = 0.0;
        [self addSubview:_videoPlayerView];
        
        // Init live photo view
        _livePhotoView = [[PHLivePhotoView alloc] initWithFrame:self.bounds];
        _livePhotoView.layer.cornerRadius = 16.0;
        _livePhotoView.clipsToBounds = YES;
        _livePhotoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
        _livePhotoView.delegate = self;
        _livePhotoView.hidden = YES;
        _livePhotoView.alpha = 0.0;
        [self addSubview:_livePhotoView];
        
        // Init color tint overlay
        _colorOverlayView = [[UIView alloc] initWithFrame:self.bounds];
        _colorOverlayView.layer.cornerRadius = 16.0;
        _colorOverlayView.clipsToBounds = YES;
        _colorOverlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _colorOverlayView.alpha = 0.0;
        _colorOverlayView.userInteractionEnabled = NO; // Let touches pass through
        [self addSubview:_colorOverlayView];
        
        _imageRequestID = PHInvalidImageRequestID;
        [self setupBadges];
        [self setupMetadataOverlay];
        [self setupVolumePill];
        
        _feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [_feedbackGenerator prepare];
        _hasTriggeredThresholdHaptic = NO;
        
        [self setupGestures];
    }
    return self;
}

- (void)configureWithImage:(UIImage *)image {
    self.imageView.image = image;
}

#pragma mark - Badge Setup

- (void)setupBadges {
    // Keep Badge (Top-Left, Green, slight counter-clockwise tilt)
    _keepBadgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(24.0, 24.0, 110.0, 44.0)];
    _keepBadgeLabel.text = @"KEEP";
    _keepBadgeLabel.textAlignment = NSTextAlignmentCenter;
    _keepBadgeLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightHeavy];
    _keepBadgeLabel.textColor = [UIColor systemGreenColor];
    _keepBadgeLabel.layer.borderColor = [UIColor systemGreenColor].CGColor;
    _keepBadgeLabel.layer.borderWidth = 3.0;
    _keepBadgeLabel.layer.cornerRadius = 8.0;
    _keepBadgeLabel.clipsToBounds = YES;
    _keepBadgeLabel.transform = CGAffineTransformMakeRotation(-0.2); // ~ -11 degrees
    _keepBadgeLabel.alpha = 0.0;
    [self addSubview:_keepBadgeLabel];
    
    // Delete Badge (Top-Right, Red, slight clockwise tilt)
    CGFloat cardWidth = self.bounds.size.width;
    _deleteBadgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(cardWidth - 110.0 - 24.0, 24.0, 110.0, 44.0)];
    _deleteBadgeLabel.text = @"PURGE";
    _deleteBadgeLabel.textAlignment = NSTextAlignmentCenter;
    _deleteBadgeLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightHeavy];
    _deleteBadgeLabel.textColor = [UIColor systemRedColor];
    _deleteBadgeLabel.layer.borderColor = [UIColor systemRedColor].CGColor;
    _deleteBadgeLabel.layer.borderWidth = 3.0;
    _deleteBadgeLabel.layer.cornerRadius = 8.0;
    _deleteBadgeLabel.clipsToBounds = YES;
    _deleteBadgeLabel.transform = CGAffineTransformMakeRotation(0.2); // ~ +11 degrees
    _deleteBadgeLabel.alpha = 0.0;
    _deleteBadgeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:_deleteBadgeLabel];
}

#pragma mark - Metadata Pill Setup

- (void)setupMetadataOverlay {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark];
    self.metadataPillView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.metadataPillView.layer.cornerRadius = 14.0;
    self.metadataPillView.clipsToBounds = YES;
    self.metadataPillView.translatesAutoresizingMaskIntoConstraints = NO;
    self.metadataPillView.userInteractionEnabled = NO; // Prevent gesture interference
    [self addSubview:self.metadataPillView];
    
    self.metadataStackView = [[UIStackView alloc] init];
    self.metadataStackView.axis = UILayoutConstraintAxisHorizontal;
    self.metadataStackView.alignment = UIStackViewAlignmentCenter;
    self.metadataStackView.spacing = 6.0;
    self.metadataStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.metadataPillView.contentView addSubview:self.metadataStackView];
    
    // Date Label
    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
    self.dateLabel.textColor = [UIColor whiteColor];
    [self.metadataStackView addArrangedSubview:self.dateLabel];
    
    // Subtype Badge Label
    self.mediaTypeBadgeLabel = [[UILabel alloc] init];
    self.mediaTypeBadgeLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold];
    self.mediaTypeBadgeLabel.textColor = [UIColor whiteColor];
    
    self.mediaTypeBadgeContainer = [[UIView alloc] init];
    self.mediaTypeBadgeContainer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    self.mediaTypeBadgeContainer.layer.cornerRadius = 6.0;
    self.mediaTypeBadgeContainer.clipsToBounds = YES;
    self.mediaTypeBadgeContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.mediaTypeBadgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mediaTypeBadgeContainer addSubview:self.mediaTypeBadgeLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.mediaTypeBadgeLabel.topAnchor constraintEqualToAnchor:self.mediaTypeBadgeContainer.topAnchor constant:2.0],
        [self.mediaTypeBadgeLabel.bottomAnchor constraintEqualToAnchor:self.mediaTypeBadgeContainer.bottomAnchor constant:-2.0],
        [self.mediaTypeBadgeLabel.leadingAnchor constraintEqualToAnchor:self.mediaTypeBadgeContainer.leadingAnchor constant:6.0],
        [self.mediaTypeBadgeLabel.trailingAnchor constraintEqualToAnchor:self.mediaTypeBadgeContainer.trailingAnchor constant:-6.0]
    ]];
    
    [self.metadataStackView addArrangedSubview:self.mediaTypeBadgeContainer];
    
    // Anchor metadata pill to leading and bottom edges
    [NSLayoutConstraint activateConstraints:@[
        [self.metadataPillView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16.0],
        [self.metadataPillView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-16.0],
        
        [self.metadataStackView.topAnchor constraintEqualToAnchor:self.metadataPillView.contentView.topAnchor constant:5.0],
        [self.metadataStackView.bottomAnchor constraintEqualToAnchor:self.metadataPillView.contentView.bottomAnchor constant:-5.0],
        [self.metadataStackView.leadingAnchor constraintEqualToAnchor:self.metadataPillView.contentView.leadingAnchor constant:10.0],
        [self.metadataStackView.trailingAnchor constraintEqualToAnchor:self.metadataPillView.contentView.trailingAnchor constant:-10.0]
    ]];
}

+ (NSDateFormatter *)sharedDateFormatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
    });
    return formatter;
}

- (void)configureMetadataWithAsset:(PHAsset *)asset {
    // Creation date formatting
    if (asset.creationDate) {
        self.dateLabel.text = [[PPCardView sharedDateFormatter] stringFromDate:asset.creationDate];
        self.dateLabel.hidden = NO;
    } else {
        self.dateLabel.hidden = YES;
    }
    
    // Media subtypes and type detection
    if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoScreenshot) {
        self.mediaTypeBadgeContainer.hidden = NO;
        self.mediaTypeBadgeLabel.text = @"Screenshot";
    } else if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
        self.mediaTypeBadgeContainer.hidden = NO;
        self.mediaTypeBadgeLabel.text = @"Live";
    } else if (asset.mediaType == PHAssetMediaTypeVideo) {
        self.mediaTypeBadgeContainer.hidden = NO;
        self.mediaTypeBadgeLabel.text = @"Video";
        //NSUInteger minutes = (NSUInteger)asset.duration / 60;
        //NSUInteger seconds = (NSUInteger)asset.duration % 60;
        //self.mediaTypeBadgeLabel.text = [NSString stringWithFormat:@"%lu:%02lu", (unsigned long)minutes, (unsigned long)seconds];
    } else {
        self.mediaTypeBadgeContainer.hidden = YES;
    }
}

#pragma mark - Volume Pill Setup

- (void)setupVolumePill {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark];
    _volumePillView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    _volumePillView.layer.cornerRadius = 16.0;
    _volumePillView.clipsToBounds = YES;
    _volumePillView.translatesAutoresizingMaskIntoConstraints = NO;
    _volumePillView.hidden = YES;
    [self addSubview:_volumePillView];
    
    _volumeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _volumeButton.tintColor = [UIColor whiteColor];
    _volumeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_volumeButton addTarget:self action:@selector(handleVolumeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [_volumePillView.contentView addSubview:_volumeButton];
    
    [self updateVolumeButtonAppearance];
    
    [NSLayoutConstraint activateConstraints:@[
        [_volumePillView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16.0],
        [_volumePillView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-16.0],
        [_volumePillView.widthAnchor constraintEqualToConstant:32.0],
        [_volumePillView.heightAnchor constraintEqualToConstant:32.0],
        
        [_volumeButton.topAnchor constraintEqualToAnchor:_volumePillView.contentView.topAnchor],
        [_volumeButton.bottomAnchor constraintEqualToAnchor:_volumePillView.contentView.bottomAnchor],
        [_volumeButton.leadingAnchor constraintEqualToAnchor:_volumePillView.contentView.leadingAnchor],
        [_volumeButton.trailingAnchor constraintEqualToAnchor:_volumePillView.contentView.trailingAnchor]
    ]];
}

- (void)updateVolumeButtonAppearance {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:13 weight:UIImageSymbolWeightSemibold];
    NSString *symbolName = self.isMuted ? @"speaker.slash.fill" : @"speaker.wave.2.fill";
    UIImage *icon = [UIImage systemImageNamed:symbolName withConfiguration:config];
    [self.volumeButton setImage:icon forState:UIControlStateNormal];
}

- (void)handleVolumeButtonTapped {
    self.isMuted = !self.isMuted;
    if (self.player) {
        self.player.muted = self.isMuted;
    }
    
    [UIView animateWithDuration:0.15 animations:^{
        self.volumeButton.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [self updateVolumeButtonAppearance];
        [UIView animateWithDuration:0.15 animations:^{
            self.volumeButton.transform = CGAffineTransformIdentity;
        }];
    }];
}

#pragma mark - Gestures
- (void)setupGestures {
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:_panGesture];
    
    // Hold to play Live Photo
    _livePhotoGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLivePhotoLongPress:)];
    _livePhotoGesture.minimumPressDuration = 0.2;
    _livePhotoGesture.cancelsTouchesInView = NO;
    [self addGestureRecognizer:_livePhotoGesture];
}

- (void)handleLivePhotoLongPress:(UILongPressGestureRecognizer *)gesture {
    if (!self.livePhotoView.livePhoto || self.livePhotoView.hidden) {
        return;
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [self.livePhotoView stopPlayback];
    }
}

#pragma mark - Media Preparation & Playback

- (void)prepareRunningMediaWithAsset:(PHAsset *)asset cachingManager:(PHCachingImageManager *)imageManager {
    self.associatedAsset = asset;
    
    // Video Asset Setup
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        self.volumePillView.hidden = NO;
        
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        
        __weak typeof(self) weakSelf = self;
        [imageManager requestPlayerItemForVideo:asset
                                        options:options
                                  resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf || ![strongSelf.assetIdentifier isEqualToString:asset.localIdentifier]) {
                    return;
                }
                [strongSelf setupPlayerWithItem:playerItem];
            });
        }];
        
        // Live Photo Asset Setup
    } else if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
        self.volumePillView.hidden = YES;
        
        PHLivePhotoRequestOptions *options = [[PHLivePhotoRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        CGSize targetSize = CGSizeMake(self.bounds.size.width * [UIScreen mainScreen].scale,
                                       self.bounds.size.height * [UIScreen mainScreen].scale);
        
        __weak typeof(self) weakSelf = self;
        [imageManager requestLivePhotoForAsset:asset
                                    targetSize:targetSize
                                   contentMode:PHImageContentModeAspectFill
                                       options:options
                                 resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf || ![strongSelf.assetIdentifier isEqualToString:asset.localIdentifier]) {
                    return;
                }
                if (livePhoto) {
                    strongSelf.livePhotoView.livePhoto = livePhoto;
                    strongSelf.livePhotoView.hidden = NO;
                    [UIView animateWithDuration:0.25 animations:^{
                        strongSelf.livePhotoView.alpha = 1.0;
                    }];
                }
            });
        }];
    } else {
        self.volumePillView.hidden = YES;
    }
}

- (void)setupPlayerWithItem:(AVPlayerItem *)playerItem {
    [self cleanUpPlayerObservers];
    
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    self.player.muted = self.isMuted;
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    self.videoPlayerView.player = self.player;
    
    // Seamless Looping Observer
    __weak typeof(self) weakSelf = self;
    self.playerEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                                               object:playerItem
                                                                                queue:[NSOperationQueue mainQueue]
                                                                           usingBlock:^(NSNotification * _Nonnull note) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }];
    
    self.videoPlayerView.hidden = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.videoPlayerView.alpha = 1.0;
    }];
    
    if (self.userInteractionEnabled) {
        [self.player play];
    }
}

- (void)startMediaPlayback {
    if (self.player) {
        [self.player play];
    }
}

- (void)pauseMediaPlayback {
    if (self.player) {
        [self.player pause];
    }
    if (self.livePhotoView && self.livePhotoView.livePhoto) {
        [self.livePhotoView stopPlayback];
    }
}

- (void)cleanUpPlayerObservers {
    if (self.playerEndObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.playerEndObserver];
        self.playerEndObserver = nil;
    }
}

- (void)tearDownMediaPlayback {
    [self pauseMediaPlayback];
    [self cleanUpPlayerObservers];
    
    if (self.player) {
        [self.player replaceCurrentItemWithPlayerItem:nil];
        self.videoPlayerView.player = nil;
        self.player = nil;
    }
    
    self.videoPlayerView.hidden = YES;
    self.videoPlayerView.alpha = 0.0;
    
    if (self.livePhotoView) {
        self.livePhotoView.livePhoto = nil;
        self.livePhotoView.hidden = YES;
        self.livePhotoView.alpha = 0.0;
    }
    
    self.volumePillView.hidden = YES;
    self.associatedAsset = nil;
}

- (void)dealloc {
    [self cleanUpPlayerObservers];
}

#pragma mark - Gesture Handling

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    // Current finger translation relative to where the drag started
    CGPoint translation = [gesture translationInView:self.superview];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            self.originalCenter = self.center;
            self.hasTriggeredThresholdHaptic = NO;
            [self.feedbackGenerator prepare];
            [self pauseMediaPlayback];
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            // Calculate rotation angle proportional to horizontal movement
            CGFloat maxRotation = 0.35; // ~20 degrees in radians
            CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
            CGFloat rotationAngle = (translation.x / screenWidth) * maxRotation;
            
            // Create translation and rotation affine transforms
            CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(translation.x, translation.y);
            CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(rotationAngle);
            
            // Concatenate both transforms and apply to the card view
            self.transform = CGAffineTransformConcat(rotationTransform, translationTransform);
            
            CGFloat threshold = 120.0;
            CGFloat maxOverlayAlpha = 0.28;
            
            if (translation.x > 0) {
                // Swiping Right: Show Keep badge, hide Purge badge
                CGFloat progress = fmin(translation.x / threshold, 1.0);
                self.keepBadgeLabel.alpha = progress;
                self.deleteBadgeLabel.alpha = 0.0;
                self.colorOverlayView.backgroundColor = [UIColor systemGreenColor];
                self.colorOverlayView.alpha = progress * maxOverlayAlpha;
            } else if (translation.x < 0) {
                // Swiping Left: Show Purge badge, hide Keep badge
                CGFloat progress = fmin(fabs(translation.x) / threshold, 1.0);
                self.deleteBadgeLabel.alpha = progress;
                self.keepBadgeLabel.alpha = 0.0;
                self.colorOverlayView.backgroundColor = [UIColor systemRedColor];
                self.colorOverlayView.alpha = progress * maxOverlayAlpha;
            } else {
                self.keepBadgeLabel.alpha = 0.0;
                self.deleteBadgeLabel.alpha = 0.0;
                self.colorOverlayView.alpha = 0.0;
            }
            
            if (fabs(translation.x) >= threshold && !self.hasTriggeredThresholdHaptic) {
                [self.feedbackGenerator impactOccurred];
                self.hasTriggeredThresholdHaptic = YES;
            } else if (fabs(translation.x) < threshold) {
                // Reset flag if user drags back toward center
                self.hasTriggeredThresholdHaptic = NO;
            }
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            // Velocity helps detect a fast "fling" even if distance is short
            CGPoint velocity = [gesture velocityInView:self.superview];
            CGFloat xTranslation = translation.x;
            
            CGFloat threshold = 120.0;
            CGFloat flingVelocity = 800.0;
            
            if (xTranslation > threshold || velocity.x > flingVelocity) {
                // Swipe Right (Keep)
                [self animateOffScreenToRight];
            } else if (xTranslation < -threshold || velocity.x < -flingVelocity) {
                // Swipe Left (Delete)
                [self animateOffScreenToLeft];
            } else {
                // Below threshold: snap back with spring damping
                [self snapBackToCenter];
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Card Animations

- (void)snapBackToCenter {
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:0.75
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.transform = CGAffineTransformIdentity;
        self.center = self.originalCenter;
        self.keepBadgeLabel.alpha = 0.0;
        self.deleteBadgeLabel.alpha = 0.0;
        self.colorOverlayView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self startMediaPlayback]; // Keep playing once the card is back in place
    }];
}

- (void)animateOffScreenToLeft {
    CGFloat offscreenX = -[UIScreen mainScreen].bounds.size.width - 200.0;
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.center = CGPointMake(offscreenX, self.center.y);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [self.delegate cardViewDidSwipeLeft:self];
    }];
}

- (void)animateOffScreenToRight {
    CGFloat offscreenX = [UIScreen mainScreen].bounds.size.width * 2.0;
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.center = CGPointMake(offscreenX, self.center.y);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [self.delegate cardViewDidSwipeRight:self];
    }];
}

#pragma mark - Programmatic Actions

- (void)swipeLeftProgrammatically {
    [self.feedbackGenerator impactOccurred];
    
    // Reveal purge badge and red tint immediately for animation
    [UIView animateWithDuration:0.1 animations:^{
        self.deleteBadgeLabel.alpha = 1.0;
        self.colorOverlayView.backgroundColor = [UIColor systemRedColor];
        self.colorOverlayView.alpha = 0.28;
    } completion:^(BOOL finished) {
        [self animateOffScreenToLeft];
    }];
}

- (void)swipeRightProgrammatically {
    [self.feedbackGenerator impactOccurred];
    
    // Reveal keep badge and green tint immediately for animation
    [UIView animateWithDuration:0.1 animations:^{
        self.keepBadgeLabel.alpha = 1.0;
        self.colorOverlayView.backgroundColor = [UIColor systemGreenColor];
        self.colorOverlayView.alpha = 0.28;
    } completion:^(BOOL finished) {
        [self animateOffScreenToRight];
    }];
}

@end
