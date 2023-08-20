
// forward declaration
@class RecentlyAddedManager;

@interface LibraryRecentlyAddedViewController

// custom properties
@property(strong, nonatomic) RecentlyAddedManager *recentlyAddedManager;
@property(strong, nonatomic) AlbumActionsViewController *albumActionsVC;

// custom methods
- (void)checkAlbumOrder;
- (void)handleMoveToSectionAction:(NSInteger)sectionIndex;
- (void)handleShiftAction:(BOOL)isMovingLeft;
- (void)moveAlbumCellFromAdjustedIndexPath:(NSIndexPath *)arg1 toAdjustedIndexPath:(NSIndexPath *)arg2 dataUpdateBlock:(void (^)())arg3;

@end