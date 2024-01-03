
#import <UIKit/UIKit.h>

// forward declarations
@class GridCircle;

@interface GridCircleGroupCollection : NSObject
@property(strong, nonatomic) NSMutableArray *groups;
@property(strong, nonatomic) NSMutableArray *circles;

- (GridCircle *)circleWithIdentifierInCollection:(NSString *)ident;
- (void)removeCircleWithIdentifierFromCollection:(NSString *)ident;
- (void)addCircleToCollection:(GridCircle *)circle;
- (void)createShapesFromGroups;

@end