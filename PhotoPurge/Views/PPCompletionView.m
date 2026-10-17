//
//  PPCompletionView.m
//  PhotoPurge
//

#import "PPCompletionView.h"

@interface PPCompletionView ()

@property (nonatomic, strong) UIImageView *symbolImageView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;

@property (nonatomic, strong) UIView *metricsContainerView;
@property (nonatomic, strong) UIStackView *metricsStackView;
@property (nonatomic, strong) UILabel *stagedCountLabel;
@property (nonatomic, strong) UILabel *stagedBytesLabel;
@property (nonatomic, strong) UILabel *lifetimeBytesLabel;

@property (nonatomic, strong) UIButton *commitPurgesButton;
@property (nonatomic, strong) UIButton *restartButton;

@property (nonatomic, assign) NSUInteger currentStagedCount;

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
    UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:56 weight:UIImageSymbolWeightLight];
    UIImage *sealImage = [UIImage systemImageNamed:@"checkmark.seal.fill" withConfiguration:symbolConfig];
    
    _symbolImageView = [[UIImageView alloc] initWithImage:sealImage];
    _symbolImageView.tintColor = [UIColor systemGreenColor];
    _symbolImageView.contentMode = UIViewContentModeScaleAspectFit;
    _symbolImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_symbolImageView];
    
    // Primary title label
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"All Caught Up";
    _titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    _titleLabel.textColor = [UIColor labelColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_titleLabel];
    
    // Metrics container view (card-styled container)
    _metricsContainerView = [[UIView alloc] init];
    _metricsContainerView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    _metricsContainerView.layer.cornerRadius = 14.0;
    _metricsContainerView.layer.masksToBounds = YES;
    _metricsContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_metricsContainerView];
    
    // Metrics vertical stack view (spacing 8.0 pt)
    _metricsStackView = [[UIStackView alloc] init];
    _metricsStackView.axis = UILayoutConstraintAxisVertical;
    _metricsStackView.alignment = UIStackViewAlignmentFill;
    _metricsStackView.distribution = UIStackViewDistributionFillEqually;
    _metricsStackView.spacing = 8.0;
    _metricsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [_metricsContainerView addSubview:_metricsStackView];
    
    // Monospaced digit metrics labels
    _stagedCountLabel = [[UILabel alloc] init];
    _stagedCountLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightMedium];
    _stagedCountLabel.textColor = [UIColor labelColor];
    _stagedCountLabel.textAlignment = NSTextAlignmentCenter;
    [_metricsStackView addArrangedSubview:_stagedCountLabel];
    
    _stagedBytesLabel = [[UILabel alloc] init];
    _stagedBytesLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightMedium];
    _stagedBytesLabel.textColor = [UIColor secondaryLabelColor];
    _stagedBytesLabel.textAlignment = NSTextAlignmentCenter;
    [_metricsStackView addArrangedSubview:_stagedBytesLabel];
    
    _lifetimeBytesLabel = [[UILabel alloc] init];
    _lifetimeBytesLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightMedium];
    _lifetimeBytesLabel.textColor = [UIColor secondaryLabelColor];
    _lifetimeBytesLabel.textAlignment = NSTextAlignmentCenter;
    [_metricsStackView addArrangedSubview:_lifetimeBytesLabel];
    
    // Prominent destructive purge button (visible only when stagedCount > 0)
    _commitPurgesButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _commitPurgesButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    _commitPurgesButton.layer.cornerRadius = 12.0;
    _commitPurgesButton.clipsToBounds = YES;
    _commitPurgesButton.backgroundColor = [UIColor systemRedColor];
    [_commitPurgesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _commitPurgesButton.translatesAutoresizingMaskIntoConstraints = NO;
    _commitPurgesButton.hidden = YES;
    [_commitPurgesButton addTarget:self action:@selector(handleCommitPurgesButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_commitPurgesButton];
    
    // Restart button (visible when stagedCount == 0)
    _restartButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _restartButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    _restartButton.layer.cornerRadius = 12.0;
    _restartButton.clipsToBounds = YES;
    _restartButton.backgroundColor = [UIColor systemBlueColor];
    [_restartButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_restartButton setTitle:@"Review From Beginning" forState:UIControlStateNormal];
    _restartButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_restartButton addTarget:self action:@selector(handleRestartButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_restartButton];
    
    // Layout Constraints
    [NSLayoutConstraint activateConstraints:@[
        [_symbolImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_symbolImageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:36.0],
        [_symbolImageView.widthAnchor constraintEqualToConstant:68.0],
        [_symbolImageView.heightAnchor constraintEqualToConstant:68.0],
        
        [_titleLabel.topAnchor constraintEqualToAnchor:_symbolImageView.bottomAnchor constant:16.0],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20.0],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20.0],
        
        [_metricsContainerView.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:20.0],
        [_metricsContainerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:24.0],
        [_metricsContainerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-24.0],
        
        [_metricsStackView.topAnchor constraintEqualToAnchor:_metricsContainerView.topAnchor constant:14.0],
        [_metricsStackView.bottomAnchor constraintEqualToAnchor:_metricsContainerView.bottomAnchor constant:-14.0],
        [_metricsStackView.leadingAnchor constraintEqualToAnchor:_metricsContainerView.leadingAnchor constant:16.0],
        [_metricsStackView.trailingAnchor constraintEqualToAnchor:_metricsContainerView.trailingAnchor constant:-16.0],
        
        [_commitPurgesButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:28.0],
        [_commitPurgesButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-28.0],
        [_commitPurgesButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-28.0],
        [_commitPurgesButton.heightAnchor constraintEqualToConstant:50.0],
        [_commitPurgesButton.topAnchor constraintGreaterThanOrEqualToAnchor:_metricsContainerView.bottomAnchor constant:16.0],
        
        [_restartButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:28.0],
        [_restartButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-28.0],
        [_restartButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-28.0],
        [_restartButton.heightAnchor constraintEqualToConstant:50.0],
        [_restartButton.topAnchor constraintGreaterThanOrEqualToAnchor:_metricsContainerView.bottomAnchor constant:16.0]
    ]];
}

- (void)configureWithStagedCount:(NSUInteger)stagedCount
                    stagedBytes:(int64_t)stagedBytes
                  lifetimeBytes:(int64_t)lifetimeBytes {
    self.currentStagedCount = stagedCount;
    
    NSString *formattedStaged = (stagedBytes <= 0) ? @"0 KB" : [NSByteCountFormatter stringFromByteCount:stagedBytes countStyle:NSByteCountFormatterCountStyleFile];
    NSString *formattedLifetime = (lifetimeBytes <= 0) ? @"0 KB" : [NSByteCountFormatter stringFromByteCount:lifetimeBytes countStyle:NSByteCountFormatterCountStyleFile];
    
    self.stagedCountLabel.text = [NSString stringWithFormat:@"Photos to Purge: %lu", (unsigned long)stagedCount];
    self.stagedBytesLabel.text = [NSString stringWithFormat:@"Space to Reclaim: %@", formattedStaged];
    self.lifetimeBytesLabel.text = [NSString stringWithFormat:@"Lifetime Reclaimed: %@", formattedLifetime];
    
    if (stagedCount > 0) {
        self.titleLabel.text = @"Review Complete";
        [self.commitPurgesButton setTitle:[NSString stringWithFormat:@"Purge %lu Photos Now", (unsigned long)stagedCount] forState:UIControlStateNormal];
        self.commitPurgesButton.hidden = NO;
        self.restartButton.hidden = YES;
    } else {
        self.titleLabel.text = @"All Caught Up";
        self.commitPurgesButton.hidden = YES;
        self.restartButton.hidden = NO;
    }
}

- (void)showCalculatingStateWithStagedCount:(NSUInteger)stagedCount
                              lifetimeBytes:(int64_t)lifetimeBytes {
    self.currentStagedCount = stagedCount;
    
    NSString *formattedLifetime = (lifetimeBytes <= 0) ? @"0 KB" : [NSByteCountFormatter stringFromByteCount:lifetimeBytes countStyle:NSByteCountFormatterCountStyleFile];
    
    self.stagedCountLabel.text = [NSString stringWithFormat:@"Photos to Purge: %lu", (unsigned long)stagedCount];
    self.stagedBytesLabel.text = @"Space to Reclaim: Calculating...";
    self.lifetimeBytesLabel.text = [NSString stringWithFormat:@"Lifetime Reclaimed: %@", formattedLifetime];
    
    if (stagedCount > 0) {
        self.titleLabel.text = @"Review Complete";
        [self.commitPurgesButton setTitle:[NSString stringWithFormat:@"Purge %lu Photos Now", (unsigned long)stagedCount] forState:UIControlStateNormal];
        self.commitPurgesButton.hidden = NO;
        self.restartButton.hidden = YES;
    } else {
        self.titleLabel.text = @"All Caught Up";
        self.commitPurgesButton.hidden = YES;
        self.restartButton.hidden = NO;
    }
}

- (void)updateTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (void)configureWithTotalReviewed:(NSUInteger)totalReviewed pendingCount:(NSUInteger)pendingCount {
    [self configureWithStagedCount:pendingCount stagedBytes:0 lifetimeBytes:0];
}

#pragma mark - Button Actions

- (void)handleCommitPurgesButtonTapped {
    if ([self.delegate respondsToSelector:@selector(completionViewDidRequestCommitPurges:)]) {
        [self.delegate completionViewDidRequestCommitPurges:self];
    } else if ([self.delegate respondsToSelector:@selector(completionViewDidRequestPurge:)]) {
        [self.delegate completionViewDidRequestPurge:self];
    }
}

- (void)handleRestartButtonTapped {
    if ([self.delegate respondsToSelector:@selector(completionViewDidRequestRestart:)]) {
        [self.delegate completionViewDidRequestRestart:self];
    }
}

@end
