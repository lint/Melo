
#import "GridCircleGroupCollection.h"
#import "../grid_structs.h"

@implementation GridCircleGroupCollection

- (instancetype)init {

    if ((self = [super init])) {

        _groups = [NSMutableArray array];
    }

    return self;
}

- (void)resetGroups {
    _groups = [NSMutableArray array];
}

- (void)addCircleToCollection:(GridCircle *)circle {

    BOOL addedCircleToGroup = NO;
    BOOL circleIsContained = NO;

    // iterate over every current group
    for (GridCircleGroup *group in _groups) {
        
        // try to add the circle to the group
        NewCircleAdditionStatus status = [group attemptCircleAddition:circle];

        if (status == GRID_CIRCLE_GROUP_ADDITION_STATUS_SUCCESSFUL) {
            addedCircleToGroup = YES;
            break;
        } else if (status == GRID_CIRCLE_GROUP_ADDITION_STATUS_CONTAINED) {
            circleIsContained = YES;
            break;
        }
    }

    // return if a new group does not need to be made
    if (addedCircleToGroup || circleIsContained) {
        return;
    }

    // create new group
    GridCircleGroup *newGroup = [GridCircleGroup new];
    [newGroup attemptCircleAddition:circle];
    [_groups addObject:newGroup];
}

- (void)createShapesFromGroups {

    for (GridCircleGroup *group in _groups) {
        [group calculateShape];
    }
}






@end