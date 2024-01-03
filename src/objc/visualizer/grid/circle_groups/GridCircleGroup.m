
#import "GridCircleGroup.h"
#import "../types/types.h"
#import "../GridMath.h"
#import "GridCircleInfo.h"
#import "../delaunay/DelaunayVoronoi.h"
#import "../delaunay/DelaunayEdge.h"
#import "../delaunay/DelaunayLineSegment.h"
#import "../delaunay/DelaunayTriangle.h"
#import "../delaunay/DelaunaySite.h"

@implementation GridCircleGroup

- (instancetype)init {

    if ((self = [super init])) {

        _circles = [NSMutableArray array];
        _circleInfoMap = [NSMutableDictionary dictionary];
        _testString = [NSMutableString string];
        _edges = [NSMutableArray array];

    }

    return self;
}

- (GridCircleInfo *)circleInfoForCircle:(GridCircle *)circle {
    if (!circle) {
        return nil;
    }

    return _circleInfoMap[circle.identifier];
}

- (GridCircle *)circleWithIdentifier:(NSString *)ident {

    for (GridCircle *circle in _circles) {
        if ([ident isEqualToString:circle.identifier]) {
            return circle;
        }
    }

    return nil;   
}

- (void)removeCircleWithIdentifier:(NSString *)ident {

    GridCircle *circle = [self circleWithIdentifier:ident];
    
    if (circle) {
        [self removeCirclesInArray:@[circle]];
    }
}

- (void)removeCirclesInArray:(NSArray *)circlesToRemove {

    // remove circles from main array
    [_circles removeObjectsInArray:circlesToRemove];
    
    // remove circles from intersections
    for (id key in _circleInfoMap) {
        GridCircleInfo *circleInfo = _circleInfoMap[key];
        [circleInfo.intersectingCircles removeObjectsInArray:circlesToRemove];
    }

    // remove circles from the info map
    for (GridCircle *circle in circlesToRemove) {
        if (_circleInfoMap[circle.identifier]) {
            [_circleInfoMap removeObjectForKey:circle.identifier];
        }
    }
}

- (NewCircleAdditionStatus)attemptCircleAddition:(GridCircle *)newCircle {

    if ([_circles containsObject:newCircle]) {
        return GRID_CIRCLE_GROUP_ADDITION_STATUS_CONTAINED;
    } else if ([_circles count] == 0) {
        [self addNewCircle:newCircle];
        return GRID_CIRCLE_GROUP_ADDITION_STATUS_SUCCESSFUL;
    }

    NSMutableArray *intersectingCircles = [NSMutableArray array];
    NSMutableArray *circlesToRemove = [NSMutableArray array];
    BOOL newCircleIsContained = NO;
    BOOL shouldAddNewCircle = NO;

    for (GridCircle *groupCircle in _circles) {

        CGFloat centerDist = [GridMath distanceBetweenPoint:newCircle.center andPoint:groupCircle.center];

        // newCircle is inside groupCircle
        if (centerDist <= groupCircle.radius - newCircle.radius) {
            
            shouldAddNewCircle = NO;
            newCircleIsContained = YES;
            [circlesToRemove addObject:newCircle];
            break;
        
        // groupCircle is inside newCircle
        } else if (centerDist <= newCircle.radius - groupCircle.radius) {
            
            shouldAddNewCircle = YES;
            [circlesToRemove addObject:groupCircle];
        
        // circles intersect
        } else if (centerDist < groupCircle.radius + newCircle.radius) {
            
            shouldAddNewCircle = YES;
            [intersectingCircles addObject:groupCircle];
        }
    }
    
    // remove contained circles from the group
    [self removeCirclesInArray:circlesToRemove];

    // add a new circle to the group
    if (shouldAddNewCircle) {
        [self addNewCircle:newCircle];

        // update the group circles' intersections
        for (GridCircle *circle in intersectingCircles) {
            GridCircleInfo *circleInfo = _circleInfoMap[circle.identifier];
            [circleInfo.intersectingCircles addObject:newCircle];
        }

        // update the new circle's intersections
        GridCircleInfo *newCircleInfo = _circleInfoMap[newCircle.identifier];
        newCircleInfo.intersectingCircles = intersectingCircles;

        return GRID_CIRCLE_GROUP_ADDITION_STATUS_SUCCESSFUL;
    }

    // check if the new circle was not added due to no intersections or to being contained
    return newCircleIsContained ? GRID_CIRCLE_GROUP_ADDITION_STATUS_CONTAINED : GRID_CIRCLE_GROUP_ADDITION_STATUS_FAILURE;
}

- (void)addNewCircle:(GridCircle *)circle {
    [_circles addObject:circle];
    GridCircleInfo *circleInfo = [[GridCircleInfo alloc] initWithCircle:circle];
    _circleInfoMap[circle.identifier] = circleInfo;
}

- (void)calculateShape {

    // reset circle info
    for (id key in _circleInfoMap) {
        GridCircleInfo *circleInfo = _circleInfoMap[key];
        [circleInfo resetCalculatedValues];        
    }

    // iterate over every circle in the group
    for (GridCircle *circle in _circles) {

        [self calculateIntersectionsForCircle:circle];
        // [self calculateRegionBoundariesForCircle:circle];
        [self calculateTriangulation];
    }
}

- (void)calculateTriangulation {

    NSMutableArray *points = [NSMutableArray array];

    for (GridCircle *circle in _circles) {
        [points addObject:[NSValue valueWithCGPoint:circle.center]];
    }
    // CGRect plotBounds = CGRectMake(0, 0, _viewBounds.size.width, _viewBounds.size.height / _viewBounds.size.width);

    DelaunayVoronoi *del = [DelaunayVoronoi voronoiWithPoints:points plotBounds:CGRectZero];
    NSMutableArray *edges = [NSMutableArray array];

    // for (DelaunayEdge *e in del.edges) {

    //     GridLine *line = [[GridLine alloc] initWithStartPoint:e.delaunayLine.p0 endPoint:e.delaunayLine.p1];
    //     [edges addObject:line];
    // }

    for (DelaunayTriangle *t1 in del.triangles) {

        CGPoint circumcenter = [t1 calculateCircumcenter];
        
        for (DelaunayTriangle *t2 in del.triangles) {
            
            if (t1 == t2) {
                continue;
            }

            if ([t1 isAdjacentToTriangle:t2]) {
                CGPoint otherCircumcenter = [t2 calculateCircumcenter];
                GridLine *line = [[GridLine alloc] initWithStartPoint:circumcenter endPoint:otherCircumcenter];
                [edges addObject:line];
            }
        }    

    }

    NSMutableArray *edgesToInfinity = [NSMutableArray array];
    NSMutableArray *triangleEdges = [NSMutableArray array];

    CGFloat infScale = 100;

    for (DelaunayTriangle *t1 in del.triangles) {
        CGPoint circumcenter = [t1 calculateCircumcenter];
        GridLine *line1 = [[GridLine alloc] initWithStartPoint:t1.site1.coordinates endPoint:t1.site2.coordinates];
        GridLine *line2 = [[GridLine alloc] initWithStartPoint:t1.site2.coordinates endPoint:t1.site3.coordinates];
        GridLine *line3 = [[GridLine alloc] initWithStartPoint:t1.site3.coordinates endPoint:t1.site1.coordinates];
        [triangleEdges addObjectsFromArray:@[line1, line2, line3]];

        BOOL line1Intersected = NO;
        BOOL line2Intersected = NO;
        BOOL line3Intersected = NO;

        for (GridLine *edge in edges) {
            line1Intersected |= [GridMath findIntersectionOfLine:line1 andLine:edge solution:nil];
            line2Intersected |= [GridMath findIntersectionOfLine:line2 andLine:edge solution:nil];
            line3Intersected |= [GridMath findIntersectionOfLine:line3 andLine:edge solution:nil];
        }

        if (!line1Intersected) {
            CGPoint midpoint = [line1 calculateMidpoint];
            CGFloat xDiff = midpoint.x - circumcenter.x;
            CGFloat yDiff = midpoint.y - circumcenter.y;
            CGPoint newPoint = CGPointMake(circumcenter.x + xDiff * infScale, circumcenter.y + yDiff * infScale);

            GridLine *line = [[GridLine alloc] initWithStartPoint:circumcenter endPoint:newPoint];
            [edgesToInfinity addObject:line];
        }
        if (!line2Intersected) {
            CGPoint midpoint = [line2 calculateMidpoint];
            CGFloat xDiff = midpoint.x - circumcenter.x;
            CGFloat yDiff = midpoint.y - circumcenter.y;
            CGPoint newPoint = CGPointMake(circumcenter.x + xDiff * infScale, circumcenter.y + yDiff * infScale);

            GridLine *line = [[GridLine alloc] initWithStartPoint:circumcenter endPoint:newPoint];
            [edgesToInfinity addObject:line];
        }

        if (!line3Intersected) {
            CGPoint midpoint = [line3 calculateMidpoint];
            CGFloat xDiff = midpoint.x - circumcenter.x;
            CGFloat yDiff = midpoint.y - circumcenter.y;
            CGPoint newPoint = CGPointMake(circumcenter.x + xDiff * infScale, circumcenter.y + yDiff * infScale);

            GridLine *line = [[GridLine alloc] initWithStartPoint:circumcenter endPoint:newPoint];
            [edgesToInfinity addObject:line];
        }
    }

    [edges addObjectsFromArray:edgesToInfinity];
    // [edges addObjectsFromArray:triangleEdges];

    _edges = edges;
}

- (CGPoint)calculateClosestPointToShapeFromPoint:(CGPoint)point {

    NSArray *containingCircles = [self circlesWithRegionContainingPoint:point];

    if ([containingCircles count] != 1) {
        return point;
    }

    // for (GridCircle *circle in containingCircles) {
    GridCircle *circle = containingCircles[0];
    GridCircleInfo *circleInfo = _circleInfoMap[circle.identifier];

    CGPoint circleProjection = [GridMath projectPoint:point ontoCircle:circle];
    CGPoint weightedProjection = [GridMath pointBetweenPoint:point andPoint:circleProjection destWeight:circle.strength];

    // iterate over every outer arc of the circle
    for (GridArc *arc in circleInfo.outerArcs) {

        // check if the point is contained within the sector defined by the arc
        if ([GridMath isPoint:point withinSectorOfArc:arc]) {
            
            return weightedProjection;
        }
    }
    // }

    CGFloat minProjDist = CGFLOAT_MAX;
    CGPoint minLineProj = CGPointZero;

    for (GridLine *line in _edges) {
        
        CGPoint lineProjection = [GridMath projectPoint:weightedProjection ontoLine:line];
        CGFloat squaredDist = [GridMath squaredDistanceBetweenPoint:lineProjection andPoint:weightedProjection];

        if (squaredDist < minProjDist) {
            minProjDist = squaredDist;
            minLineProj = lineProjection;
        }
    }

    if (minProjDist == CGFLOAT_MAX) {
        return weightedProjection;
    }

    CGFloat minLineProjToCenterDist = [GridMath squaredDistanceBetweenPoint:minLineProj andPoint:circle.center];
    CGFloat weightedProjToCenterDist = [GridMath squaredDistanceBetweenPoint:weightedProjection andPoint:circle.center];

    if (weightedProjToCenterDist < minLineProjToCenterDist) {
        return weightedProjection;
    } else {
        return minLineProj;
    }
}

- (void)calculateRegionBoundariesForCircle:(GridCircle *)circle {

    GridCircleInfo *circleInfo = _circleInfoMap[circle.identifier];
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dist" ascending:YES]];

    //iterate over every intersection line of the given circle
    for (GridLine *line in circleInfo.intersectionLines) {

        // find the end point information
        NSDictionary *startPointData = @{
            @"point": [NSValue valueWithCGPoint:line.start],
            @"dist": @0
        };
        NSDictionary *endPointData = @{
            @"point": [NSValue valueWithCGPoint:line.end],
            @"dist": @([GridMath squaredDistanceBetweenPoint:line.start andPoint:line.end])
        };

        NSMutableArray *intersectionPoints = [NSMutableArray arrayWithArray:@[startPointData, endPointData]];

        // iterate over every other line of the circle
        for (GridLine *otherLine in circleInfo.intersectionLines) {

            if (line == otherLine) {
                continue;
            }

            // check if the lines intersect
            CGPoint intersectionPoint;
            BOOL foundIntersection = [GridMath findIntersectionOfLine:line andLine:otherLine solution:&intersectionPoint];

            if (foundIntersection) {

                CGFloat squaredDist = [GridMath squaredDistanceBetweenPoint:line.start andPoint:intersectionPoint];
                NSDictionary *pointData = @{
                    @"point": [NSValue valueWithCGPoint:intersectionPoint],
                    @"dist": @(squaredDist)
                };

                [intersectionPoints addObject:pointData];
            }
        }

        // sort the intersection points using the distance to the start point
        [intersectionPoints sortUsingDescriptors:sortDescriptors];

        // iterate over line segment of the generated line
        NSInteger numIntersectionPoints = [intersectionPoints count];
        for (NSInteger i = 0; i < numIntersectionPoints; i++) {

            NSDictionary *point1Data = intersectionPoints[i];
            NSDictionary *point2Data = intersectionPoints[(i + 1) % numIntersectionPoints];

            CGPoint point1 = [point1Data[@"point"] CGPointValue];
            CGPoint point2 = [point2Data[@"point"] CGPointValue];

            CGPoint midpoint = [GridMath pointBetweenPoint:point1 andPoint:point2 destWeight:0.5];

            NSInteger numContainingRegions = [self numCirclesWithRegionContainingPoint:midpoint];

            // if the midpoint is contained within more than 1 region, it is a point on the boundary
            if (numContainingRegions > 1) {
                GridLine *boundaryLine = [[GridLine alloc] initWithStartPoint:point1 endPoint:point2];
                [circleInfo.regionBoundaryLines addObject:boundaryLine];
            }
        }
    }
}

- (NSArray *)circlesWithRegionContainingPoint:(CGPoint)point {

    CGFloat minPower = CGFLOAT_MAX;
    NSMutableArray *minCircleRegions = [NSMutableArray array];
    CGFloat tolerance = 0.001;

    for (GridCircle *circle in _circles) {
        CGFloat power = [GridMath powerOfPoint:point aroundCircle:circle];
        CGFloat powerDiff = fabs(power - minPower);

        // // find the new minimum power
        // if (power < minPower && powerDiff > 0.0001) {
        //     minPower = power;
        //     [minCircleRegions removeAllObjects];
        //     [minCircleRegions addObject:circle];
        
        // // check if another circle has the same power as the min within a tolerance
        // } else if (powerDiff < 0.0001) {
        //     if (power < minPower) {
        //         [minCircleRegions insertObject:circle atIndex:0];
        //     } else {
        //         [minCircleRegions addObject:circle];
        //     }
        // }

        if (powerDiff == 0 || powerDiff/(fabs(power)+fabs(minPower)) < tolerance) {
            if (power < minPower) {
                [minCircleRegions insertObject:circle atIndex:0];
            } else {
                [minCircleRegions addObject:circle];
            }
        } else if (power < minPower) {
            minPower = power;
            [minCircleRegions removeAllObjects];
            [minCircleRegions addObject:circle];
        }
        
    }

    return minCircleRegions;
}

- (NSInteger)numCirclesWithRegionContainingPoint:(CGPoint)point {

    CGFloat minPower = CGFLOAT_MAX;
    NSInteger numMinCircleRegions = 0;
    CGFloat tolerance = 0.001;
    
    for (GridCircle *circle in _circles) {
        CGFloat power = [GridMath powerOfPoint:point aroundCircle:circle];
        CGFloat powerDiff = fabs(power - minPower);

        if (powerDiff == 0 || powerDiff/(fabs(power)+fabs(minPower)) < tolerance) {
            numMinCircleRegions++;
        } else if (power < minPower) {
            minPower = power;
            numMinCircleRegions = 1;
        }
        
        // // find the new minimum power
        // if (power < minPower && powerDiff >= 0.1) {
        //     minPower = power;
        //     numMinCircleRegions = 1;
        
        // // check if another circle has the same power as the min within a tolerance
        // } else if (powerDiff < 0.1) {
        //     numMinCircleRegions++;
        // }
    }

    return numMinCircleRegions;
}

- (void)calculateIntersectionsForCircle:(GridCircle *)circle {
    
    GridCircleInfo *circleInfo = _circleInfoMap[circle.identifier];

    if ([_circles count] == 1) {

        GridArc *arc = [[GridArc alloc] initWithStartAngle:0 endAngle:2 * M_PI circle:circle];
        [circleInfo.outerArcs addObject:arc];

        return;
    }

    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"angle" ascending:YES]];
    NSMutableArray *intersectionPoints = [NSMutableArray array];

    // iterate over every circle the given circle intersects with
    for (GridCircle *intersectingCircle in circleInfo.intersectingCircles) {

        NSArray *newIntersectionPoints = [GridMath intersectionPointsBetweenCircle:circle andCircle:intersectingCircle];
        [intersectionPoints addObjectsFromArray:newIntersectionPoints];

        // create a line from the found intersection points
        if ([newIntersectionPoints count] == 2) {
            CGPoint startPoint = [newIntersectionPoints[0][@"point"] CGPointValue];
            CGPoint endPoint = [newIntersectionPoints[1][@"point"] CGPointValue];

            GridLine *line = [[GridLine alloc] initWithStartPoint:startPoint endPoint:endPoint];
            [circleInfo.intersectionLines addObject:line];
        }
    }

    // sort the intersection points using the angle
    [intersectionPoints sortUsingDescriptors:sortDescriptors];

    // iterate over every arc on the circle going counter clockwise
    NSInteger numIntersectionPoints = [intersectionPoints count];
    for (NSInteger k = 0; k < numIntersectionPoints; k++) {

        NSDictionary *point1Data = intersectionPoints[k];
        NSDictionary *point2Data = intersectionPoints[(k + 1) % numIntersectionPoints];

        CGFloat startAngle = [point1Data[@"angle"] floatValue];
        CGFloat endAngle = [point2Data[@"angle"] floatValue];

        // check if the current arc is an outer edge of the circle group
        GridArc *arc = [[GridArc alloc] initWithStartAngle:startAngle endAngle:endAngle circle:circle];
        BOOL isEdge = [self isArcGroupOuterEdge:arc];

        if (isEdge) {
            // [Logger logString:@"found an edge arc!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"];

            [circleInfo.outerArcs addObject:arc];
        }
    }
}

- (BOOL)isArcGroupOuterEdge:(GridArc *)arc {

    // find the point on the circle that is in the middle of the arc
    CGPoint edgePoint = [arc calculateMidpoint];

    // iterate over every other circle in the group
    for (GridCircle *circle in _circles) {

        if (circle == arc.circle) {
            continue;
        }

        // if this edge point is contained within another circle, the arc is not a boundary
        if ([GridMath isPoint:edgePoint withinCircle:circle]) {
            return NO;
        }
    }

    return YES;
}

- (BOOL)circlesContainPoint:(CGPoint)point {

    for (GridCircle *circle in _circles) {
        if ([GridMath isPoint:point withinCircle:circle]) {
            return YES;
        }
    }

    return NO;
}

@end