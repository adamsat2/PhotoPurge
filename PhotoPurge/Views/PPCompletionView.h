//
//  PPCompletionView.h
//  PhotoPurge
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PPCompletionView;

@protocol PPCompletionViewDelegate <NSObject>

// Triggered when tapping the primary restart button
- (void)completionViewDidRequestRestart:(PPCompletionView *)completionView;

// Triggered if there are pending deletions and user requests immediate batch purge
- (void)completionViewDidRequestPurge:(PPCompletionView *)completionView;

@optional
// Optional specific handler for committing purges directly from the completion view
- (void)completionViewDidRequestCommitPurges:(PPCompletionView *)completionView;

@end

@interface PPCompletionView : UIView

@property (nonatomic, weak, nullable) id<PPCompletionViewDelegate> delegate;
@property (nonatomic, strong, readonly) UILabel *titleLabel;

- (void)configureWithStagedCount:(NSUInteger)stagedCount
                    stagedBytes:(int64_t)stagedBytes
                  lifetimeBytes:(int64_t)lifetimeBytes;

- (void)showCalculatingStateWithStagedCount:(NSUInteger)stagedCount
                              lifetimeBytes:(int64_t)lifetimeBytes;

- (void)updateTitle:(NSString *)title;

// Legacy configuration method maintained for backward compatibility
- (void)configureWithTotalReviewed:(NSUInteger)totalReviewed
                      pendingCount:(NSUInteger)pendingCount;

@end

NS_ASSUME_NONNULL_END
