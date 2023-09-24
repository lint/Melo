
#import <UIKit/UIKit.h>

@interface JSGridViewController : UIViewController

// Layout.xm
@property(assign, nonatomic) BOOL shouldApplyCustomLayout;
@property(strong, nonatomic) NSDictionary *albumCellDisplayOptions;
- (void)checkShouldApplyCustomLayout;
- (void)handleLayoutPrefsUpdate:(NSNotification *)arg1;

@end