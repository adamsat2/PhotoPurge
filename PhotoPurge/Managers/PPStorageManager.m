//
//  PPStorageManager.m
//  PhotoPurge
//

#import "PPStorageManager.h"

static NSString * const PPKeyTotalBytesReclaimed = @"PPKeyTotalBytesReclaimed";

@interface PPStorageManager ()

@property (nonatomic, assign) int64_t totalBytesReclaimed;

@end

@implementation PPStorageManager

+ (instancetype)sharedManager {
    static PPStorageManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PPStorageManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _totalBytesReclaimed = [[NSUserDefaults standardUserDefaults] integerForKey:PPKeyTotalBytesReclaimed];
    }
    return self;
}

- (NSString *)formattedTotalBytesReclaimed {
    if (self.totalBytesReclaimed <= 0) {
        return @"0 KB";
    }
    return [NSByteCountFormatter stringFromByteCount:self.totalBytesReclaimed
                                         countStyle:NSByteCountFormatterCountStyleFile];
}

- (void)calculateByteSizeForAssets:(NSArray<PHAsset *> *)assets
                       completion:(void (^)(int64_t totalBytes))completion {
    if (!completion) return;
    if (assets.count == 0) {
        completion(0);
        return;
    }
    
    // Execute on background queue to avoid blocking main thread UI
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        int64_t totalBytes = 0;
        
        for (PHAsset *asset in assets) {
            NSArray<PHAssetResource *> *resources = [PHAssetResource assetResourcesForAsset:asset];
            for (PHAssetResource *resource in resources) {
                // Read fileSize property via KVC directly from metadata
                id fileSizeVal = [resource valueForKey:@"fileSize"];
                if ([fileSizeVal respondsToSelector:@selector(longLongValue)]) {
                    totalBytes += [fileSizeVal longLongValue];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(totalBytes);
        });
    });
}

- (void)recordReclaimedBytes:(int64_t)bytes {
    if (bytes <= 0) return;
    
    self.totalBytesReclaimed += bytes;
    [[NSUserDefaults standardUserDefaults] setInteger:self.totalBytesReclaimed
                                               forKey:PPKeyTotalBytesReclaimed];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
