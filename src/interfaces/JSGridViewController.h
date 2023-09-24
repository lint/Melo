
#import <UIKit/UIKit.h>

@interface JSGridViewController : UIViewController

// Layout.xm
@property(assign, nonatomic) BOOL shouldApplyCustomLayout;
- (void)checkShouldApplyCustomLayout;

@end