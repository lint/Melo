
#import <UIKit/UIKit.h>

// forward declaration
@class RecentlyAddedManager, WiggleModeManager, AnimationManager, AlbumActionsViewController;

@interface LibraryRecentlyAddedViewController : UIViewController

// Pinning.xm
@property(strong, nonatomic) WiggleModeManager *wiggleModeManager;
@property(strong, nonatomic) RecentlyAddedManager *recentlyAddedManager;
@property(strong, nonatomic) AlbumActionsViewController *albumActionsVC;
@property(strong, nonatomic) AnimationManager *animationManager;
- (void)checkAlbumOrder;
- (void)handleActionMoveAlbumAtIndexPath:(NSIndexPath *)sourceAdjustedIndexPath toSection:(NSInteger)sectionIndex;
- (void)handleActionShiftAlbumAtIndexPath:(NSIndexPath *)sourceAdjustedIndexPath movingLeft:(BOOL)isMovingLeft;
- (void)moveAlbumCellFromAdjustedIndexPath:(NSIndexPath *)arg1 toAdjustedIndexPath:(NSIndexPath *)arg2 dataUpdateBlock:(void (^)())arg3;
- (void)toggleSectionCollapsedAtIndex:(NSInteger)arg1;
- (void)handleDoubleTapOnAlbum:(UITapGestureRecognizer *)sender;
- (NSArray *)customContextActionsForAlbumAtIndexPath:(NSIndexPath *)indexPathForContextActions;
- (void)handlePinningPrefsUpdate:(NSNotification *)arg1;

- (NSIndexPath *)collectionView:(UICollectionView *)collectionView targetIndexPathForMoveOfItemFromOriginalIndexPath:(NSIndexPath *)originalIndexPath 
    atCurrentIndexPath:(NSIndexPath *)currentIndexPath toProposedIndexPath:(NSIndexPath *)proposedIndexPath;

// WiggleMode.xm
- (void)endWiggleMode;
- (void)toggleWiggleMode;
- (void)createEndWiggleModeButtonItems;
- (void)handleLongPress:(UILongPressGestureRecognizer *)arg1;
- (void)startDragAtPoint:(CGPoint)arg1; 
- (void)updateDragAtPoint:(CGPoint)arg1;
- (void)endDragAtPoint:(CGPoint)arg1;
- (void)checkAutoScrollWithPoint:(CGPoint)arg1;
- (void)handleAutoScrollTimerFired:(NSTimer *)timer;
- (void)autoScrollAction:(BOOL)goingUp;
- (void)triggerHapticFeedback;

// Layout.xm
- (void)handleLayoutPrefsUpdate:(NSNotification *)arg1;

@end