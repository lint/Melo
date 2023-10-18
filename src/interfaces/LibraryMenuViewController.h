
#import <UIKit/UIKit.h>

// forward declaration
@class LibraryMenuManager;

@interface LibraryMenuViewController : UITableViewController

// Library.xm
@property(assign, nonatomic) BOOL shouldInjectCustomData;
@property(strong, nonatomic) LibraryMenuManager *libraryMenuManager;
- (id)dataSource;

@end