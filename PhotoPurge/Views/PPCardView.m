//
//  PPCardView.m
//  PhotoPurge
//

#import "PPCardView.h"

@interface PPCardView ()

// The image view is kept private inside the .m file so outside classes can't mess with it directly
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) CGPoint originalCenter;

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
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
                [self addGestureRecognizer:panGesture];
    }
    return self;
}

- (void)configureWithImage:(UIImage *)image {
    self.imageView.image = image;
}

#pragma mark - Gesture Handling

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    // Current finger translation relative to where the drag started
    CGPoint translation = [gesture translationInView:self.superview];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            self.originalCenter = self.center;
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

@end
