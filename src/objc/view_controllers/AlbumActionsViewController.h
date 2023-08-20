
#import <UIKit/UIKit.h>
@class RecentlyAddedManager;

@interface AlbumActionsViewController : UIViewController
@property(strong, nonatomic) RecentlyAddedManager *recentlyAddedManager;
@property(strong, nonatomic) NSIndexPath *albumAdjustedIndexPath;
@property(strong, nonatomic) NSMutableDictionary *buttonMap;
@property(strong, nonatomic) id libraryRecentlyAddedViewController;
@end