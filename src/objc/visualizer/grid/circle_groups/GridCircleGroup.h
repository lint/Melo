#import <UIKit/UIKit.h>

typedef enum : NSInteger {
    GRID_CIRCLE_GROUP_ADDITION_STATUS_SUCCESSFUL,
    GRID_CIRCLE_GROUP_ADDITION_STATUS_CONTAINED,
    GRID_CIRCLE_GROUP_ADDITION_STATUS_FAILURE,
} NewCircleAdditionStatus;

@interface GridCircleGroup : NSObject
@property(strong, nonatomic) NSMutableArray *circles;
@property(strong, nonatomic) NSMutableDictionary *circleInfoMap;
@end