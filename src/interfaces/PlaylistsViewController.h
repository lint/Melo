
#import <UIKit/UIKit.h>

@interface PlaylistsViewController : UIViewController

// Backport.xm
@property(assign, nonatomic) BOOL shouldApplyCustomValues;
- (void)handleBackportPrefsUpdate:(NSNotification *)arg1;
- (UICollectionView *)findCollectionView;
@end