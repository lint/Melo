
#import <UIKit/UIKit.h>

// forward declaration
// @class VisualizerView;

@interface MusicNowPlayingControlsViewController : UIViewController

// Backport.xm
- (void)handleBackportPrefsUpdate:(NSNotification *)arg1;

// Library.xm
// @property(strong, nonatomic) VisualizerView *vizView;
// @property(assign, nonatomic) BOOL shouldShowVizView;
- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1;
// - (void)layoutVizView;
@end