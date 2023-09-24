
#import <UIKit/UIKit.h>

@interface AlbumsViewController : UIViewController

// Layout.xm
@property(strong, nonatomic) NSDictionary *albumCellDisplayOptions;
- (void)handleLayoutPrefsUpdate:(NSNotification *)arg1;

@end