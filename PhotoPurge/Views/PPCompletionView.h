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

@end

@interface PPCompletionView : UIView

@property (nonatomic, weak, nullable) id<PPCompletionViewDelegate> delegate;

// totalReviewed is the total count of photos reviewed in this session.
// pendingCount is the number of items currently staged for deletion.
- (void)configureWithTotalReviewed:(NSUInteger)totalReviewed
                      pendingCount:(NSUInteger)pendingCount;

@end

NS_ASSUME_NONNULL_END
