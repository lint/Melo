
#import "UIKit/UIKit.h"

@interface RecentlyViewedPageManager : NSObject
@property(strong, nonatomic) NSMutableDictionary *navMap;
@property(strong, nonatomic) NSMutableArray *albumQueue;
@proprety(assign, nonatomic) NSInteger queueSizeLimit;
@property(assign, nonatomic) BOOL shouldLimitQueues;

- (void)addAlbumPageToQueue:(id)arg1;
- (void)updateQueueConfigFromPrefs;
- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1;
- (void)addNavControllerToMap:(UINavigationController *)arg1;
- (NSArray *)viewControllersForMappedNavController:(UINavigationController *)arg1;

@end