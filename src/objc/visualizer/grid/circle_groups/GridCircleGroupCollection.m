
#import "GridCircleGroupCollection.h"
#import "../types/types.h"
#import "GridCircleGroup.h"

@implementation GridCircleGroupCollection

- (instancetype)init {

    if ((self = [super init])) {

        _groups = [NSMutableArray array];
        _circles = [NSMutableArray array];
    }

    return self;
}

- (GridCircle *)circleWithIdentifierInCollection:(NSString *)ident {

    for (GridCircleGroup *group in _groups) {
        GridCircle *circle = [group circleWithIdentifier:ident];

        if (circle) {
            return circle;
        }
    }

    return nil;   
}

- (void)removeCircleWithIdentifierFromCollection:(NSString *)ident {
    
    for (GridCircleGroup *group in _groups) {
        [group removeCircleWithIdentifier:ident];
    }

    NSMutableArray *circlesToRemove = [NSMutableArray array];
    for (GridCircle *circle in _circles) {
        if ([ident isEqualToString:circle.identifier]) {
            [circlesToRemove addObject:circle];
        }
    }

    [_circles removeObjectsInArray:circlesToRemove];
    [self createShapesFromGroups];
}

- (void)addCircleToCollection:(GridCircle *)circle {

    // remove the circle that shares the new circle's identiifer if it exists
    // [self removeCircleWithIdentifier:circle.identifier];
    // TODO: don't want to recreate shapes twice, so i just copied the code... but there's definitely a better way of doing it
    for (GridCircleGroup *group in _groups) {
        [group removeCircleWithIdentifier:circle.identifier];
    }

    NSMutableArray *circlesToRemove = [NSMutableArray array];
    for (GridCircle *otherCircle in _circles) {
        if ([otherCircle.identifier isEqualToString:circle.identifier]) {
            [circlesToRemove addObject:otherCircle];
        }
    }
    [_circles removeObjectsInArray:circlesToRemove];


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

    // return if the circle is fully contained by another circle in the group
    if (circleIsContained) {
        return;
    }

    // create new group
    if (!addedCircleToGroup) {
        GridCircleGroup *newGroup = [GridCircleGroup new];
        [newGroup attemptCircleAddition:circle];
        [_groups addObject:newGroup];
    }

    [_circles addObject:circle];
    [self createShapesFromGroups];
}

- (void)createShapesFromGroups {

    for (GridCircleGroup *group in _groups) {
        [group calculateShape];
    }
}






@end