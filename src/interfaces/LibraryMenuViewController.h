
#import <UIKit/UIKit.h>

@interface LibraryMenuViewController : UITableViewController

// Library.xm
@property(assign, nonatomic) BOOL shouldInjectCustomData;
- (id)dataSource;

@end