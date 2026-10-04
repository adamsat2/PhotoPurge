//
//  PPStorageManager.h
//  PhotoPurge
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PPStorageManager : NSObject

@property (nonatomic, readonly) int64_t totalBytesReclaimed;

+ (instancetype)sharedManager;

- (NSString *)formattedTotalBytesReclaimed;

- (void)calculateByteSizeForAssets:(NSArray<PHAsset *> *)assets
                       completion:(void (^)(int64_t totalBytes))completion;

- (void)recordReclaimedBytes:(int64_t)bytes;

@end

NS_ASSUME_NONNULL_END
