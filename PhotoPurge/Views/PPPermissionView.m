//
//  PPPermissionView.m
//  PhotoPurge
//

#import "PPPermissionView.h"

@interface PPPermissionView ()

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, assign) PPPermissionViewState currentState;

@end

@implementation PPPermissionView

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
    // Icon view
    _iconImageView = [[UIImageView alloc] init];
    _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    _iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_iconImageView];
    
    // Title label
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    _titleLabel.textColor = [UIColor labelColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_titleLabel];
    
    // Description label
    _descriptionLabel = [[UILabel alloc] init];
    _descriptionLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    _descriptionLabel.textColor = [UIColor secondaryLabelColor];
    _descriptionLabel.textAlignment = NSTextAlignmentCenter;
    _descriptionLabel.numberOfLines = 0;
    _descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_descriptionLabel];
    
    // Primary CTA button
    _actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _actionButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    _actionButton.layer.cornerRadius = 12.0;
    _actionButton.clipsToBounds = YES;
    _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_actionButton addTarget:self action:@selector(handleActionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_actionButton];
    
    // Layout Constraints matching card proportions
    [NSLayoutConstraint activateConstraints:@[
        [_iconImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_iconImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-70.0],
        [_iconImageView.widthAnchor constraintEqualToConstant:76.0],
        [_iconImageView.heightAnchor constraintEqualToConstant:76.0],
        
        [_titleLabel.topAnchor constraintEqualToAnchor:_iconImageView.bottomAnchor constant:20.0],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:24.0],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-24.0],
        
        [_descriptionLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:10.0],
        [_descriptionLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:24.0],
        [_descriptionLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-24.0],
        
        [_actionButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:28.0],
        [_actionButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-28.0],
        [_actionButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-28.0],
        [_actionButton.heightAnchor constraintEqualToConstant:50.0]
    ]];
}

- (void)configureForState:(PPPermissionViewState)state {
    self.currentState = state;
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:64 weight:UIImageSymbolWeightRegular];
    
    switch (state) {
        case PPPermissionViewStatePrompt: {
            self.iconImageView.image = [UIImage systemImageNamed:@"photo.stack.fill" withConfiguration:config];
            self.iconImageView.tintColor = [UIColor systemBlueColor];
            self.titleLabel.text = @"Photo Access Needed";
            self.descriptionLabel.text = @"PhotoPurge requires access to your library to help review, organize, and delete unwanted photos.";
            
            [self.actionButton setTitle:@"Continue" forState:UIControlStateNormal];
            self.actionButton.backgroundColor = [UIColor systemBlueColor];
            [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        }
        case PPPermissionViewStateDenied: {
            self.iconImageView.image = [UIImage systemImageNamed:@"exclamationmark.triangle.fill" withConfiguration:config];
            self.iconImageView.tintColor = [UIColor systemOrangeColor];
            self.titleLabel.text = @"Access Restricted";
            self.descriptionLabel.text = @"Photo access has been denied. To use PhotoPurge, please enable Photo Library permissions in iOS Settings.";
            
            [self.actionButton setTitle:@"Open Settings" forState:UIControlStateNormal];
            self.actionButton.backgroundColor = [UIColor systemGrayColor];
            [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        }
    }
}

- (void)handleActionButtonTapped {
    if (self.currentState == PPPermissionViewStatePrompt) {
        [self.delegate permissionViewDidRequestAuthorization:self];
    } else {
        [self.delegate permissionViewDidRequestOpenSettings:self];
    }
}

@end
