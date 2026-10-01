//
//  PPCompletionView.m
//  PhotoPurge
//

#import "PPCompletionView.h"

@interface PPCompletionView ()

@property (nonatomic, strong) UIImageView *symbolImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, assign) NSUInteger currentPendingCount;

@end

@implementation PPCompletionView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupCardAppearance];
        [self setupSubviews];
    }
    return self;
}

- (void)setupCardAppearance {
    self.backgroundColor = [UIColor systemBackgroundColor];
    self.layer.cornerRadius = 16.0;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.12;
    self.layer.shadowRadius = 8.0;
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.clipsToBounds = NO;
}

- (void)setupSubviews {
    // Completion SF icon
    UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:64 weight:UIImageSymbolWeightLight];
    UIImage *sealImage = [UIImage systemImageNamed:@"checkmark.seal.fill" withConfiguration:symbolConfig];
    
    _symbolImageView = [[UIImageView alloc] initWithImage:sealImage];
    _symbolImageView.tintColor = [UIColor systemGreenColor];
    _symbolImageView.contentMode = UIViewContentModeScaleAspectFit;
    _symbolImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_symbolImageView];
    
    // Title label
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"All Caught Up!";
    _titleLabel.font = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
    _titleLabel.textColor = [UIColor labelColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_titleLabel];
    
    // Subtitle / summary label
    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    _subtitleLabel.textColor = [UIColor secondaryLabelColor];
    _subtitleLabel.textAlignment = NSTextAlignmentCenter;
    _subtitleLabel.numberOfLines = 0;
    _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_subtitleLabel];
    
    // Primary CTA button
    _actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _actionButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    _actionButton.layer.cornerRadius = 12.0;
    _actionButton.clipsToBounds = YES;
    _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_actionButton addTarget:self action:@selector(handleActionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_actionButton];
    
    // Auto Layout Constraints (Centered stack layout)
    [NSLayoutConstraint activateConstraints:@[
        [_symbolImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_symbolImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-60.0],
        [_symbolImageView.widthAnchor constraintEqualToConstant:80.0],
        [_symbolImageView.heightAnchor constraintEqualToConstant:80.0],
        
        [_titleLabel.topAnchor constraintEqualToAnchor:_symbolImageView.bottomAnchor constant:20.0],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:24.0],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-24.0],
        
        [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:8.0],
        [_subtitleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:24.0],
        [_subtitleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-24.0],
        
        [_actionButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:32.0],
        [_actionButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-32.0],
        [_actionButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-32.0],
        [_actionButton.heightAnchor constraintEqualToConstant:50.0]
    ]];
}

- (void)configureWithTotalReviewed:(NSUInteger)totalReviewed pendingCount:(NSUInteger)pendingCount {
    self.currentPendingCount = pendingCount;
    
    if (pendingCount > 0) {
        self.subtitleLabel.text = [NSString stringWithFormat:@"You reviewed %lu items.\n%lu items are staged for deletion.",
                                   (unsigned long)totalReviewed,
                                   (unsigned long)pendingCount];
        
        [self.actionButton setTitle:[NSString stringWithFormat:@"Purge %lu Photos Now", (unsigned long)pendingCount]
                           forState:UIControlStateNormal];
        self.actionButton.backgroundColor = [UIColor systemRedColor];
        [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        self.subtitleLabel.text = [NSString stringWithFormat:@"You've reviewed all %lu photos in this batch with no items queued for deletion.",
                                   (unsigned long)totalReviewed];
        
        [self.actionButton setTitle:@"Review From Beginning" forState:UIControlStateNormal];
        self.actionButton.backgroundColor = [UIColor systemBlueColor];
        [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

- (void)handleActionButtonTapped {
    if (self.currentPendingCount > 0) {
        [self.delegate completionViewDidRequestPurge:self];
    } else {
        [self.delegate completionViewDidRequestRestart:self];
    }
}

@end
