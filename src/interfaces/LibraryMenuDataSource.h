
#import <UIKit/UIKit.h>

@interface LibraryMenuDataSource : NSObject
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

// Library.xm
@property(assign, nonatomic) BOOL shouldInjectCustomData;
@end