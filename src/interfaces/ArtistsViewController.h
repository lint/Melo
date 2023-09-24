#import <UIKit/UIKit.h>

@interface ArtistsViewController : UIViewController

// Layout.xm
@property(strong, nonatomic) NSDictionary *albumCellDisplayOptions;
- (void)handleLayoutPrefsUpdate:(NSNotification *)arg1;

@end