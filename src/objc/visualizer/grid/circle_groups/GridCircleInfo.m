
#import "GridCircleInfo.h"
#import "../types/types.h"

@implementation GridCircleInfo



- (instancetype)init {

    if ((self = [super init])) {

        _intersectingCircles = [NSMutableArray array];
        
        _intersectionLines = [NSMutableArray array];
        _outerArcs = [NSMutableArray array];
        _regionBoundaryLines = [NSMutableArray array];
    }

    return self;
}

- (instancetype)initWithCircle:(GridCircle *)circle {

    if ((self = [self init])) {

        _circle = circle;
    }

    return self;
}

- (void)resetCalculatedValues {
    _intersectionLines = [NSMutableArray array];
    _outerArcs = [NSMutableArray array];
    _regionBoundaryLines = [NSMutableArray array];
}

@end