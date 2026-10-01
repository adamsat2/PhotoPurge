//
//  PPCardView.m
//  PhotoPurge
//

#import "PPCardView.h"

@interface PPCardView ()

// The image view is kept private inside the .m file so outside classes can't mess with it directly
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) CGPoint originalCenter;
@property (nonatomic, strong) UILabel *keepBadgeLabel;
@property (nonatomic, strong) UILabel *deleteBadgeLabel;
@property (nonatomic, strong) UIView *colorOverlayView;
@property (nonatomic, strong) UIImpactFeedbackGenerator *feedbackGenerator;
@property (nonatomic, assign) BOOL hasTriggeredThresholdHaptic;

@end

@implementation PPCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
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
        
        // Init color tint overlay
        _colorOverlayView = [[UIView alloc] initWithFrame:self.bounds];
        _colorOverlayView.layer.cornerRadius = 16.0;
        _colorOverlayView.clipsToBounds = YES;
        _colorOverlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _colorOverlayView.alpha = 0.0;
        _colorOverlayView.userInteractionEnabled = NO; // Let touches pass through
        [self addSubview:_colorOverlayView];
        
        [self setupBadges];
        
        _feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [_feedbackGenerator prepare];
        _hasTriggeredThresholdHaptic = NO;
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
    }
    return self;
}

- (void)configureWithImage:(UIImage *)image {
    self.imageView.image = image;
}

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

#pragma mark - Gesture Handling

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    // Current finger translation relative to where the drag started
    CGPoint translation = [gesture translationInView:self.superview];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            self.originalCenter = self.center;
            self.hasTriggeredThresholdHaptic = NO;
            [self.feedbackGenerator prepare];
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
    } completion:nil];
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
