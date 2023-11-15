
#import "GridVisualizerManager.h"
#import "../../utilities/utilities.h"

@interface GridArcShape : NSObject
@property(strong, nonatomic) NSMutableArray *arcs;
@property(strong, nonatomic) NSMutableArray *circles;
@end

@implementation GridArcShape

- (instancetype)init {

    if ((self = [super init])) {

        _arcs = [NSMutableArray array];
        _circles = [NSMutableArray array];

    }

    return self;
}

@end

@implementation GridVisualizerManager

- (instancetype)init {

    if ((self = [super init])) {

        _numColumns = 0;
        _lastNumRows = 0;
        _viewBounds = CGRectZero;

        // _circles = [NSMutableDictionary dictionary];
        _circleChangeDetected = NO;
        _numCircles = 0;
        _maxNumCircles = 16;
        _gridCircles = calloc(_maxNumCircles, sizeof(GridCircle));
        _circleGroups = [NSMutableArray array];

    }

    return self;
}

// checks if the view bounds property has a value
- (BOOL)hasViewBounds {
    return !CGRectEqualToRect(_viewBounds, CGRectZero);
}

// sets the number of columns if it has changed
- (void)updateNumColumns:(NSInteger)newNumColumns {
    if (newNumColumns != _numColumns) {
        
        // check if each column has been allocated at least one row
        if (_lastNumRows != 0) {
            for (NSInteger i = 0; i < _numColumns; i++) {
                free(_gridPoints[i]);
            }
        }

        // check if there was space allocated for at least one column
        if (_numColumns == 0) {
            free(_gridPoints);
        }

        _numColumns = newNumColumns;
        _lastNumRows = 0;
        _gridPoints = malloc(_numColumns * sizeof(CGPoint *));

        [self setupGridPoints];
        [self calculateCircleWidthBasedCenters];
    }
}

// allocate space for and setup all points in the grid to their default values
- (void)setupGridPoints {

    // grid is dependent on the visualizer view size
    if (![self hasViewBounds] || _numColumns == 0) {
        return;
    }

    // calculate the number of rows and cell size
    CGFloat boundsWidth = _viewBounds.size.width;
    CGFloat boundsHeight = _viewBounds.size.height;
    CGFloat cellWidth = boundsWidth / (_numColumns - 1);
    NSInteger numRows = ceil(boundsHeight / cellWidth);
    CGFloat cellHeight = boundsHeight / (numRows - 1);

    // do not continue if there are no rows 
    if (numRows == 0) {
        return;
    }

    // manage memory sizes for the grid 
    if (_lastNumRows != numRows) {

        // free previous rows
        if (_lastNumRows != 0) {
            for (NSInteger i = 0; i < _numColumns; i++) {
                free(_gridPoints[i]);
            }
        }

        // allocate space for rows for each column
        for (NSInteger i = 0; i < _numColumns; i++) {
            _gridPoints[i] = malloc(numRows * sizeof(GridPoint));;
        }
    }

    // set the default value for every point in the grid
    for (NSInteger i = 0; i < _numColumns; i++) {        
        for (NSInteger j = 0; j < numRows; j++) {

            GridPoint gridPoint;
            // CGPoint defaultValue = CGPointMake(i * cellWidth, j * cellHeight);
            CGPoint defaultValue = CGPointMake(i * 1.0 / _numColumns, j * 1.0 / _numColumns);
            
            gridPoint.defaultValue = defaultValue;
            gridPoint.src = defaultValue;
            gridPoint.dst = defaultValue;
            gridPoint.cur = defaultValue;
            gridPoint.circleApplySrc = defaultValue;

            _gridPoints[i][j] = gridPoint;
        }
    }

    _lastNumRows = numRows;

    [self addCircleWithIdentifier:@"test" normCenter:CGPointMake(.4, .5) radius:.20 strength:.1];
    // [self addCircleWithIdentifier:@"test2" normCenter:CGPointMake(.6, .5) radius:.20 strength:.5];
    // [self addCircleWithIdentifier:@"test3" normCenter:CGPointMake(.5, .3) radius:.25 strength:.5];
    // [self addCircleWithIdentifier:@"test3" center:CGPointMake(.5, .5) radius:.1 strength:1];
    // [self addCircleWithIdentifier:@"test3" center:CGPointMake(.75, .5) radius:.2 strength:1];

    // _shapeLayer.path = [self pathFromGrid].CGPath;
}

// adds a new circle to the circles dictionary with the given information (overwrites circle with identifier if it exists)
- (void)addCircleWithIdentifier:(NSString *)ident normCenter:(CGPoint)center radius:(CGFloat)radius strength:(CGFloat)strength {

    GridCircle circle;
    circle.radius = radius;
    circle.strength = strength;
    circle.identifier = ident;
    circle.isContained = NO;
    circle.isIntersected = NO;
    circle.normCenter = center;
    circle.z = strength;

    if ([self hasViewBounds]) {
        circle.center = CGPointMake(center.x, center.y * _viewBounds.size.height / _viewBounds.size.width);
    } else {
        circle.center = CGPointZero;
    }

    // NSValue *val = [NSValue valueWithBytes:&circle objCType:@encode(GridCircle)];
    // _circles[ident] = val;

    NSInteger index = [self indexOfCircleWithIdentifier:ident];
    if (index == -1) {
        index = _numCircles++;
        [self resizeGridCirclesArrayIfNeeded:index];
    }

    _gridCircles[index] = circle;
    _circleChangeDetected = YES;
}

- (void)calculateCircleWidthBasedCenters {

    if (![self hasViewBounds]) {
        return;
    }

    CGFloat viewWidth = _viewBounds.size.width;
    CGFloat viewHeight = _viewBounds.size.height;

    for (NSInteger i = 0; i < _numCircles; i++) {
        GridCircle *circle = [self circleAtIndex:i];
        CGPoint normCenter = circle->normCenter;
        circle->center = CGPointMake(normCenter.x, normCenter.y * viewHeight / viewWidth);
    }
}

// returns the index of a circle with a given identifier
- (NSInteger)indexOfCircleWithIdentifier:(NSString *)ident {

    for (NSInteger i = 0; i < _numCircles; i++) {
        GridCircle circle = _gridCircles[i];

        if ([ident isEqualToString:circle.identifier]) {
            return i;
        }
    }

    return -1;
}

// return the circle struct associated with the given identifier
- (GridCircle *)circleWithIdentifier:(NSString *)ident {

    NSInteger index = [self indexOfCircleWithIdentifier:ident];
    if (index == -1) {
        return nil;
    }

    return &_gridCircles[index];
}

// removes the circle with the given identifier
- (void)removeCircleWithIdentifier:(NSString *)ident {

    NSInteger index = [self indexOfCircleWithIdentifier:ident];
    if (index == -1) {
        return;
    }

    for (NSInteger i = index; i < _numCircles - 1; i++) {
        _gridCircles[i] = _gridCircles[i + 1];
    }
    
    _numCircles--;
    _circleChangeDetected = YES;
}

// resizes the circles array if needed 
- (void)resizeGridCirclesArrayIfNeeded:(NSInteger)nextInsertionIndex {

    NSInteger newMax = -1;
    while (nextInsertionIndex >= _maxNumCircles) {
        _maxNumCircles *= 2;
        newMax = _maxNumCircles;
    }

    if (newMax != -1) {
        _gridCircles = realloc(_gridCircles, _maxNumCircles * sizeof(GridCircle));
    }
}

// resets the gridpoints' destination and source values
- (void)prepareGridPointsForAnimation {

    for (NSInteger x = 0; x < _numColumns; x++) {
        for (NSInteger y = 0; y < _lastNumRows; y++) {

            GridPoint gridPoint = _gridPoints[x][y];

            if (_circleChangeDetected) {
                gridPoint.dst = gridPoint.defaultValue;
                gridPoint.circleApplySrc = gridPoint.defaultValue;
                gridPoint.appliedCirclesMask = 0;
            }
            gridPoint.src = gridPoint.cur;            
            
            _gridPoints[x][y] = gridPoint;
        }
    }
}

- (GridPoint)applyCircle:(GridCircle)circle toPoint:(GridPoint)gridPoint 
    circleIndex:(NSInteger)circleIndex {
    
    CGFloat startingX = gridPoint.circleApplySrc.x;
    CGFloat startingY = gridPoint.circleApplySrc.y;

    CGFloat xDiff = startingX - circle.center.x;
    CGFloat yDiff = startingY - circle.center.y;
    CGFloat distance = sqrt(xDiff * xDiff + yDiff * yDiff);

    if (distance > circle.radius || distance == 0) {
    // if (!distance) {
        return gridPoint;
    }

    CGFloat distMult = circle.radius / distance;

    CGPoint closestCirclePoint = CGPointMake(
        circle.center.x + xDiff * distMult,
        circle.center.y + yDiff * distMult
    );

    CGFloat dstXTranslation = (closestCirclePoint.x - startingX) * circle.strength;
    CGFloat dstYTranslation = (closestCirclePoint.y - startingY) * circle.strength;

    // if (strength < 0) {
        
    //     // top two quadrants
    //     if (startingY < coordinateCenter.y) {
    //         dstYTranslation = MIN(dstYTranslation, coordinateCenter.y - startingY);
        
    //     // bottom two quadrants
    //     } else if (startingY > coordinateCenter.y) {
    //         dstYTranslation = MAX(dstYTranslation, coordinateCenter.y - startingY);
    //     }

    //     // left two quadrants
    //     if (startingX < coordinateCenter.x) {
    //         dstXTranslation = MIN(dstXTranslation, coordinateCenter.x - startingX);

    //     // right two quadrants
    //     } else if (startingX > coordinateCenter.x) {
    //         dstXTranslation = MAX(dstXTranslation, coordinateCenter.x - startingX);
    //     }
    // }

    gridPoint.dst.x += dstXTranslation;
    gridPoint.dst.y += dstYTranslation;
    gridPoint.appliedCirclesMask |= 1 << circleIndex;

    return gridPoint;
}

- (void)applyArcShape:(NSArray *)arcShape toGridPoint:(GridPoint *)gridPoint {

    if (![self isPoint:&gridPoint->circleApplySrc containedInArcShape:arcShape]) {
        return;
    }

    CGPoint closestPoint = [self calculateClosestPointOnArcShape:arcShape fromPoint:&gridPoint->circleApplySrc];
    gridPoint->dst = closestPoint;
}

// translates the grid points within the radius of any defined circle
- (void)applyCirclesToGrid {

    // grid is dependent on the visualizer view size and if the circles actually changed
    if (![self hasViewBounds] || !_circleChangeDetected) {
        return;
    }

    _circleChangeDetected = NO;

    // for (NSInteger i = 0; i < _numCircles; i++) {

    //     GridCircle circle = _gridCircles[i];
    //     CGPoint center = circle.center;
    //     CGFloat radius = circle.radius;
    //     CGFloat strength = circle.strength;

    //     NSInteger dataIndexRadius = round((_numColumns - 1) * fabs(radius));
    //     CGPoint dataIndexCenter = CGPointMake(
    //         round(center.x * (_numColumns - 1)),
    //         round(center.y * (_lastNumRows - 1))
    //     );

    //     CGFloat coordinateRadius = _viewBounds.size.width * fabs(radius);
    //     CGPoint coordinateCenter = CGPointMake(
    //         center.x * _viewBounds.size.width, 
    //         center.y * _viewBounds.size.height
    //     );

    //     NSInteger minX = MIN(MAX(round(dataIndexCenter.x - dataIndexRadius), 0), _numColumns - 1);
    //     NSInteger maxX = MIN(MAX(round(dataIndexCenter.x + dataIndexRadius), 0), _numColumns - 1);
    //     NSInteger minY = MIN(MAX(round(dataIndexCenter.y - dataIndexRadius), 0), _lastNumRows - 1);
    //     NSInteger maxY = MIN(MAX(round(dataIndexCenter.y + dataIndexRadius), 0), _lastNumRows - 1);

    //     for (NSInteger x = minX; x <= maxX; x++) {
    //         for (NSInteger y = minY; y <= maxY; y++) {

    //             GridPoint gridPoint = _gridPoints[x][y];
    //             gridPoint.circleApplySrc = gridPoint.dst;
    //             gridPoint = [self applyCircle:circle toPoint:gridPoint coordinateCenter:coordinateCenter coordinateRadius:coordinateRadius circleIndex:i];

    //             _gridPoints[x][y] = gridPoint;
    //         }
    //     }
    // }
    
    // // iterate over every point 
    // for (NSInteger x = 0; x < _numColumns; x++) {
    //     for (NSInteger y = 0; y < _lastNumRows; y++) {

    //         GridPoint gridPoint = _gridPoints[x][y];
            
    //         // loop until no more circles are applied (if no circles are initially applied this loop will not run)
    //         // NSInteger lastMask = -1;
    //         // while (gridPoint.appliedCirclesMask != lastMask) {
    //         //     lastMask = gridPoint.appliedCirclesMask;
    //         //     gridPoint.circleApplySrc = gridPoint.dst;
                
    //             // iterate over every circle
    //             for (NSInteger i = 0; i < _numCircles; i++) {
                    
    //                 // continue if circle has already been applied
    //                 if ((gridPoint.appliedCirclesMask >> i) & 1) {
    //                     continue;
    //                 }

    //                 GridCircle circle = _gridCircles[i];

    //                 // CGFloat coordinateRadius = _viewBounds.size.width * fabs(circle.radius);
    //                 // CGPoint coordinateCenter = CGPointMake(
    //                 //     circle.center.x * _viewBounds.size.width, 
    //                 //     circle.center.y * _viewBounds.size.height
    //                 // );

    //                 // gridPoint = [self applyCircle:circle toPoint:gridPoint coordinateCenter:coordinateCenter coordinateRadius:coordinateRadius circleIndex:i];
    //                 gridPoint = [self applyCircle:circle toPoint:gridPoint circleIndex:i];
    //                 // gridPoint.dst.x = gridPoint.defaultValue.x;
    //             }
    //         // }

    //         _gridPoints[x][y] = gridPoint;
    //     }
    // }

    // [self createArcsFromIntersectingCircles];

    // for (NSInteger x = 0; x < _numColumns; x++) {
    //     for (NSInteger y = 0; y < _lastNumRows; y++) {

    //         GridPoint *gridPoint = &_gridPoints[x][y];

    //         for (NSArray *arcShape in _gridArcShapes) {


    //             [self applyArcShape:arcShape toGridPoint:gridPoint];


    //         }
    //     }
    // }

    // iterate over every point 
    // for (NSInteger x = 0; x < _numColumns; x++) {
    //     for (NSInteger y = 0; y < _lastNumRows; y++) {

    //         GridPoint gridPoint = _gridPoints[x][y];
    //         gridPoint.circleApplySrc = gridPoint.defaultValue;

    //         NSInteger minCircleIndex = -1;
    //         CGFloat minCircleDist = CGFLOAT_MAX;
            
    //         // iterate over every circle
    //         for (NSInteger i = 0; i < _numCircles; i++) {
                
    //             GridCircle circle = _gridCircles[i];
    //             CGFloat coordinateRadius = _viewBounds.size.width * fabs(circle.radius);
    //             CGPoint coordinateCenter = CGPointMake(
    //                 circle.center.x * _viewBounds.size.width, 
    //                 circle.center.y * _viewBounds.size.height
    //             );

    //             CGFloat dist = [self calculateDistanceBetweenPoint:&coordinateCenter andPoint:&gridPoint.defaultValue];

    //             if (dist < coordinateRadius && dist < minCircleDist) {
    //                 minCircleDist = dist;
    //                 minCircleIndex = i;
    //             }
                
    //         }

    //         if (minCircleIndex > -1) {

    //             GridCircle circle = _gridCircles[minCircleIndex];
    //             CGFloat coordinateRadius = _viewBounds.size.width * fabs(circle.radius);
    //             CGPoint coordinateCenter = CGPointMake(
    //                 circle.center.x * _viewBounds.size.width, 
    //                 circle.center.y * _viewBounds.size.height
    //             );

    //             gridPoint = [self applyCircle:circle toPoint:gridPoint coordinateCenter:coordinateCenter coordinateRadius:coordinateRadius circleIndex:minCircleIndex];
    //         }

    //         _gridPoints[x][y] = gridPoint;
    //     }
    // }



    for (NSInteger x = 0; x < _numColumns; x++) {
        for (NSInteger y = 0; y < _lastNumRows; y++) {

            GridPoint *gridPoint = &_gridPoints[x][y];

            CGFloat maxDist = 0;
            CGPoint endPoint;

            for (NSInteger i = 0; i < _numCircles; i++) {

                CGPoint startPoint = gridPoint->defaultValue;

                GridCircle *circle = [self circleAtIndex:i];
                Grid3dPoint point3d = [self point3dFromPoint:&startPoint];

                if (![self is3dPoint:&point3d containedInSphere:circle]) {
                    continue;
                }

                Grid3dPoint proj = [self calculateProjectionOfPoint:&point3d ontoSphere:circle];
                Grid3dPoint weightedProj = [self calculate3dPointBetween3dPoint:&point3d and3dPoint:&proj destWeight:circle->strength];

                CGFloat dist = [self calculateDistanceBetween3dPoint:&point3d and3dPoint:&proj];

                if (dist > maxDist) {
                    maxDist = dist;
                    endPoint = CGPointMake(proj.x, proj.y);
                }
            }

            if (maxDist > 0) {
                gridPoint->dst = endPoint;
            }
        }
    }
}

// update the current points for the grid based on the percentage that the animation has elapsed between the source and destination points
- (void)calculateCurrentGrid:(float)animationPercent {

    // calculate the weight for source vs destination
    float destWeight = MIN(MAX(animationPercent, 0), 1);
    float sourceWeight = 1 - destWeight;

    // iterate over every point
    for (NSInteger x = 0; x < _numColumns; x++) {
        for (NSInteger y = 0; y < _lastNumRows; y++) {

            GridPoint gridPoint = _gridPoints[x][y];

            CGPoint currPoint = CGPointMake(
                sourceWeight * gridPoint.src.x + destWeight * gridPoint.dst.x,
                sourceWeight * gridPoint.src.y + destWeight * gridPoint.dst.y
            );
            
            _gridPoints[x][y].cur = currPoint;
        }
    }    
}

// creates a bezier path following every row and column in the grid
- (UIBezierPath *)currentGridPath {

    UIBezierPath *path = [UIBezierPath new];

    // create a line down each column
    for (NSInteger i = 0; i < _numColumns; i++) {
    
        [path moveToPoint:[self displayCoordsForPoint:_gridPoints[i][0].cur]];
    
        for (NSInteger j = 1; j < _lastNumRows; j++) {
            [path addLineToPoint:[self displayCoordsForPoint:_gridPoints[i][j].cur]];
        }
    }

    // create a line across each row
    for (NSInteger i = 0; i < _lastNumRows; i++) {
    
        [path moveToPoint:[self displayCoordsForPoint:_gridPoints[0][i].cur]];
    
        for (NSInteger j = 1; j < _numColumns; j++) {
            [path addLineToPoint:[self displayCoordsForPoint:_gridPoints[j][i].cur]];
        }
    }

    return path;
}

- (UIBezierPath *)currentCirclesPath {

    UIBezierPath *path = [UIBezierPath new];

    for (NSInteger i = 0; i < _numCircles; i++) {
        GridCircle *circle = [self circleAtIndex:i];

        CGPoint edgePoint = [self calculatePointOnCircle:circle angle:0];
        CGPoint edgePointDisplayCoords = [self displayCoordsForPoint:edgePoint];
        CGPoint centerDisplayCoords = [self displayCoordsForPoint:circle->center];

        [path moveToPoint:edgePointDisplayCoords];
        [path addArcWithCenter:centerDisplayCoords radius:circle->radius * _viewBounds.size.width startAngle:0 endAngle:M_PI clockwise:NO];
        [path addArcWithCenter:centerDisplayCoords radius:circle->radius * _viewBounds.size.width startAngle:M_PI endAngle:0 clockwise:NO];
    }

    return path;
}

- (CGPoint)displayCoordsForPoint:(CGPoint)point {
    
    return CGPointMake(
        point.x * _viewBounds.size.width,
        point.y * _numColumns / _lastNumRows * _viewBounds.size.height
    );
}

- (CGPoint)calculateClosestPointOnArcShape:(NSArray *)arcShape fromPoint:(CGPoint *)point {

    CGPoint closestPoint = CGPointZero;
    CGFloat closestDist = CGFLOAT_MAX;
    CGFloat strength = 0;
    
    for (NSValue *arcValue in arcShape) {
        GridArc arc;
        [arcValue getValue:&arc size:sizeof(GridArc)];

        if ([self isPoint:point withinArc:&arc]) {
            CGFloat pointAngle = [self angleOfPoint:point aroundCircle:arc.circle];
            CGPoint closestCirclePoint = [self calculatePointOnCircle:arc.circle angle:pointAngle];

            CGFloat circlePointDist = [self calculateDistanceBetweenPoint:point andPoint:&closestCirclePoint];
            closestDist = circlePointDist;
            // closestPoint = closestCirclePoint;
            strength = arc.circle->strength;

            closestPoint = [self calculatePointBetweenPoint:point andPoint:&closestCirclePoint destWeight:strength];
            return closestPoint;

        } else if ([self isPoint:point withinCircle:arc.circle]) {

            CGFloat startPointDist = [self calculateDistanceBetweenPoint:point andPoint:&arc.startPoint];
            if (startPointDist < closestDist) {
                closestDist = startPointDist;

                CGFloat pointAngle = [self angleOfPoint:point aroundCircle:arc.circle];

                CGPoint circlePoint = [self calculatePointOnCircle:arc.circle angle:pointAngle];
                CGPoint weightedCirclePoint = [self calculatePointBetweenPoint:point andPoint:&circlePoint destWeight:arc.circle->strength];

                CGPoint projection = [self calculateProjectionOfPoint:&weightedCirclePoint toLineWithStartPoint:&arc.startPoint endPoint:&arc.startPointPair];
                // CGPoint projection = [self calculateProjectionOfPoint:point toLineWithStartPoint:&arc.startPoint endPoint:&arc.startPointPair];

                // CGFloat circlePointSquaredDist = [self calculateSquaredDistanceBetweenPoint:point andPoint:&closestCirclePoint];

                CGPoint towardsStart = [self calculatePointBetweenPoint:&weightedCirclePoint andPoint:&arc.startPoint destWeight:arc.circle->strength];
                CGPoint weightedCircleTowardsStart = [self calculatePointBetweenPoint:&weightedCirclePoint andPoint:&arc.startPoint destWeight:arc.circle->strength];

                CGFloat projectionToCenterSquaredDist = [self calculateSquaredDistanceBetweenPoint:&projection andPoint:&arc.circle->center];
                CGFloat weightedCirclePointToCenterSquaredDist = [self calculateSquaredDistanceBetweenPoint:&weightedCirclePoint andPoint:&arc.circle->center];

                if (weightedCirclePointToCenterSquaredDist <= projectionToCenterSquaredDist) {
                    closestPoint = weightedCirclePoint;
                } else {
                    closestPoint = projection;
                }

                // CGFloat startDist = [self calculateSquaredDistanceBetweenPoint:&closestPoint andPoint:&arc.startPoint];
                // CGFloat startPairDist = [self calculateSquaredDistanceBetweenPoint:&closestPoint andPoint:&arc.startPointPair];

                // if (startDist <= startPairDist) {
                //     closestPoint = [self calculatePointBetweenPoint:&closestPoint andPoint:&arc.startPoint destWeight:arc.circle->strength];
                // } else {
                //     closestPoint = [self calculatePointBetweenPoint:&closestPoint andPoint:&arc.startPointPair destWeight:arc.circle->strength];
                // }

                // closestPoint = towardsStart;

                // CGPoint projection = [self calculateProjectionOfPoint:point toLineWithStartPoint:&arc.startPoint endPoint:&arc.endPoint];
                // return projection;
                // CGPoint weightedProj = [self calculatePointBetweenPoint:point andPoint:&projection destWeight:arc.circle->strength];
                // CGPoint towardsStart = [self calculatePointBetweenPoint:&weightedProj andPoint:&arc.startPoint destWeight:arc.circle->strength];

                // // CGFloat dist = [self calculateDistanceBetweenPoint:point andPoint:&projection];
                // // if (dist < closestDist) {
                //     // closestDist = dist;
                //     closestPoint = towardsStart;
                    // strength = (arc.circle->strength + arc.startOtherCircle->strength) / 2;
                // }
                break;
            }
            
        }
    }

    return closestPoint;
}

- (CGFloat)calculatePowerOfPoint:(CGPoint *)point circle:(GridCircle *)circle {
    CGFloat radius = circle->radius;
    return [self calculateSquaredDistanceBetweenPoint:point andPoint:&circle->center] - radius*radius;
}

- (NSInteger)indexOfCircleRegionContainingPoint:(CGPoint *)point inArcShape:(NSArray *)arcShape {
    return 0;
}

- (GridCircle *)circleAtNSNumberIndex:(NSNumber *)num {
    return [self circleAtIndex:[num integerValue]];
}

- (GridCircle *)circleAtIndex:(NSInteger)index {
    return &_gridCircles[index];
}

- (void)createArcsFromIntersectingCircles {

    [self createGroupsFromCircles];

    _gridArcShapes = [NSMutableArray array];

    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"angle" ascending:YES]];

    // iterate over every group
    for (NSInteger i = 0; i < [_circleGroups count]; i++) {
        
        NSDictionary *group = _circleGroups[i];

        if ([group count] == 0) {
            continue;
        }

        NSMutableArray *edgeArcs = [NSMutableArray array];

        // iterate over every circle in the group
        for (NSNumber *groupCircleNum in group) {

            [Logger logStringWithFormat:@"checking group: %ld, circle: %@", i, groupCircleNum];

            NSMutableArray *circleIntersectionPoints = [NSMutableArray array];
            GridCircle *circle1 = [self circleAtNSNumberIndex:groupCircleNum];
            
            // iterate over every intersection that circle has and calculate the points
            for (NSNumber *intersectionCircleNum in group[groupCircleNum]) {

                GridCircle *circle2 = [self circleAtNSNumberIndex:intersectionCircleNum];
                NSArray *newIntersectionPoints = [self calculateIntersectionPointsBetweenCircle:circle1 andCircle:circle2];
                [circleIntersectionPoints addObjectsFromArray:newIntersectionPoints];
            }

            // sort the intersection points using the angle
            [circleIntersectionPoints sortUsingDescriptors:sortDescriptors];

            // iterate over every arc on the circle going counter clockwise
            NSInteger numIntersectionPoints = [circleIntersectionPoints count];
            for (NSInteger k = 0; k < numIntersectionPoints; k++) {

                NSDictionary *point1Data = circleIntersectionPoints[k];
                NSDictionary *point2Data = circleIntersectionPoints[(k + 1) % numIntersectionPoints];

                // check if the current arc is an outer edge of the circle group
                BOOL isEdge = [self isEdgeArcFromPointDict:point1Data toPointDict:point2Data arcCircle:circle1 group:group];

                // edge was found! create arc and add it to array
                if (isEdge) {
                    [Logger logString:@"found an edge arc!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"];

                    GridArc arc = [self gridArcForCircle:circle1 startPointDict:point1Data endPointDict:point2Data];
                    NSValue *val = [NSValue valueWithBytes:&arc objCType:@encode(GridArc)];

                    [edgeArcs addObject:val];
                }
            }

        }

        // add the completed set of edge arcs to the shapes array
        [_gridArcShapes addObject:edgeArcs];
    }

    // iterate over every circle and add standalone circles as arc shapes
    for (NSInteger i = 0; i < _numCircles; i++) {

        GridCircle *circle = [self circleAtIndex:i];

        // circle is not standalone if it is contained by or intersected with another circle
        if (circle->isContained || circle->isIntersected) {
            continue;
        }

        [Logger logStringWithFormat:@"found standalone circle: %ld isContained: %li isIntersected: ", i];

        // create arc that wraps all the way around the circle
        CGPoint edgePoint = [self calculatePointOnCircle:circle angle:0];
        GridArc arc = [self gridArcForCircle:circle startPoint:edgePoint startAngle:0 endPoint:edgePoint endAngle:2 * M_PI];
        arc.startOtherCircle = circle;
        arc.endOtherCircle = circle;
        arc.startPointPair = edgePoint;
        NSValue *val = [NSValue valueWithBytes:&arc objCType:@encode(GridArc)];

        [_gridArcShapes addObject:@[val]];
    }

}

- (void)resetCircleGroupValues {

    _circleGroups = [NSMutableArray array];

    for (NSInteger i = 0; i < _numCircles; i++) {
        GridCircle *circle = &_gridCircles[i];
        circle->groupIndex = -1;
        circle->isContained = NO;
        circle->isIntersected = NO;
    }
}

- (void)createGroupsFromCircles {

    [self resetCircleGroupValues];

    // iterate over every pair of circles
    for (NSInteger i = 0; i < _numCircles - 1; i++) {
        for (NSInteger j = i + 1; j < _numCircles; j++) {

            GridCircle *circle1 = [self circleAtIndex:i];
            GridCircle *circle2 = [self circleAtIndex:j];

            if (circle1->isContained || circle2->isContained) {
                continue;
            }

            CGFloat centerDist = [self calculateDistanceBetweenPoint:&circle1->center andPoint:&circle2->center];

            // circle2 is inside circle1
            if (centerDist <= circle1->radius - circle2->radius) {
                [Logger logStringWithFormat:@"found contained circle: %ld inside: %ld", j, i];

                circle2->isContained = YES;
            
            // circle1 is inside circle2
            } else if (centerDist <= circle2->radius - circle1->radius) {
                [Logger logStringWithFormat:@"found contained circle: %ld inside: %ld", i, j];

                circle1->isContained = YES;
            
            // circles intersect
            } else if (centerDist < circle1->radius + circle2->radius) {
                [Logger logStringWithFormat:@"found intersecting circles: %ld, %ld", i, j];

                circle1->isIntersected = YES;
                circle2->isIntersected = YES;
                
                [self addCircleToGroupWithCircle:circle1 atIndex:i andCircle:circle2 atIndex:j];
            }
        }
    }

    [self removeContainedCirclesFromGroups];
}

- (void)addCircleToGroupWithCircle:(GridCircle *)circle1 atIndex:(NSInteger)circle1Index andCircle:(GridCircle *)circle2 atIndex:(NSInteger)circle2Index {

    NSInteger circle1GroupIndex = circle1->groupIndex;
    NSInteger circle2GroupIndex = circle2->groupIndex;

    NSNumber *circle1IndexNum = @(circle1Index);
    NSNumber *circle2IndexNum = @(circle2Index);

    // neither circle was found in a group
    if (circle1GroupIndex == -1 && circle2GroupIndex == -1) {

        [Logger logString:@"found new group"];

        NSMutableDictionary *group = [NSMutableDictionary dictionary];
        group[circle1IndexNum] = [NSMutableArray arrayWithArray:@[circle2IndexNum]];
        group[circle2IndexNum] = [NSMutableArray arrayWithArray:@[circle1IndexNum]];

        [_circleGroups addObject:group];

        NSInteger groupIndex = [_circleGroups indexOfObject:group];
        circle1->groupIndex = groupIndex;
        circle2->groupIndex = groupIndex;

    // circle1 is in a group but circle 2 is not
    } else if (circle1GroupIndex > -1 && circle2GroupIndex == -1) {

        [Logger logString:@"adding circle2 to circle1's group"];

        NSMutableDictionary *group = _circleGroups[circle1GroupIndex];
        [group[circle1IndexNum] addObject:circle2IndexNum];
        group[circle2IndexNum] = [NSMutableArray arrayWithArray:@[circle1IndexNum]];

        circle2->groupIndex = circle1GroupIndex;

    // circle2 is in a group but circle 1 is not
    } else if (circle1GroupIndex == -1 && circle2GroupIndex > -1) {

        [Logger logString:@"adding circle1 to circle2's group"];

        NSMutableDictionary *group = _circleGroups[circle1GroupIndex];
        [group[circle2IndexNum] addObject:circle1IndexNum];
        group[circle1IndexNum] = [NSMutableArray arrayWithArray:@[circle2IndexNum]];

        circle1->groupIndex = circle2GroupIndex;

    // both circles are already in different groups
    } else if (circle1GroupIndex > -1 && circle2GroupIndex > -1 && circle1GroupIndex != circle2GroupIndex) {

        [Logger logString:@"combining groups"];
        
        NSMutableDictionary *group1 = _circleGroups[circle1GroupIndex]; 
        NSMutableDictionary *group2 = _circleGroups[circle2GroupIndex]; 

        for (NSNumber *key in group2) {
            NSMutableArray *group1Array = group1[key];

            if (group1Array) {
                [group1Array addObjectsFromArray:group2[key]];
            } else {
                group1[key] = group2[key];
            }
        }

        _circleGroups[circle2GroupIndex] = [NSMutableDictionary dictionary];
        [group1[circle1IndexNum] addObject:circle2IndexNum];
        [group1[circle2IndexNum] addObject:circle1IndexNum];

        NSInteger groupIndex = [_circleGroups indexOfObject:group1];
        circle1->groupIndex = groupIndex;
        circle2->groupIndex = groupIndex;
    
    // both circles are in the same group
    } else if (circle1GroupIndex == circle2GroupIndex) {
        NSMutableDictionary *group = _circleGroups[circle1GroupIndex]; 
        [group[circle1IndexNum] addObject:circle2IndexNum];
        [group[circle2IndexNum] addObject:circle1IndexNum];
    }
}

- (void)removeContainedCirclesFromGroups {

    for (NSInteger i = 0; i < _numCircles; i++) {
        GridCircle *circle = &_gridCircles[i];
        NSNumber *circleIndexNum = @(i);

        if (!circle->isContained) {
            continue;
        }

        for (NSMutableDictionary *group in _circleGroups) {

            for (NSNumber *groupCircleNum in group) {
                NSMutableArray *intersections = group[groupCircleNum];
                [intersections removeObject:circleIndexNum];
            }

            if (group[circleIndexNum]) {
                [group removeObjectForKey:circleIndexNum];
            }
        }
    }
}

- (GridArc)gridArcForCircle:(GridCircle *)circle startPoint:(CGPoint)startPoint startAngle:(CGFloat)startAngle endPoint:(CGPoint)endPoint endAngle:(CGFloat)endAngle {

    GridArc arc;
    arc.circle = circle;
    arc.startPoint = startPoint;
    arc.startAngle = startAngle;
    arc.endPoint = endPoint;
    arc.endAngle = endAngle;

    while (arc.endAngle < arc.startAngle) {
        arc.endAngle += 2 * M_PI;
    }

    return arc;
} 

- (GridArc)gridArcForCircle:(GridCircle *)circle startPointDict:(NSDictionary *)startPointData endPointDict:(NSDictionary *)endPointData {

    CGPoint startPoint = [startPointData[@"point"] CGPointValue];
    CGFloat startAngle = [startPointData[@"angle"] floatValue];

    CGPoint endPoint = [endPointData[@"point"] CGPointValue];
    CGFloat endAngle = [endPointData[@"angle"] floatValue];

    GridArc arc = [self gridArcForCircle:circle startPoint:startPoint startAngle:startAngle endPoint:endPoint endAngle:endAngle];
    arc.startPointPair = [startPointData[@"pointPair"] CGPointValue];
    arc.startOtherCircle = [startPointData[@"otherCircle"] pointerValue];
    arc.endOtherCircle = [endPointData[@"otherCircle"] pointerValue];

    return arc;
} 

- (BOOL)isEdgeArcFromPointDict:(NSDictionary *)point1Data toPointDict:(NSDictionary *)point2Data arcCircle:(GridCircle *)arcCircle group:(NSDictionary *)group {
    
    CGPoint point1 = [point1Data[@"point"] CGPointValue];
    CGPoint point2 = [point2Data[@"point"] CGPointValue];

    CGFloat point1Angle = [point1Data[@"angle"] floatValue];
    CGFloat point2Angle = [point2Data[@"angle"] floatValue];

    if (point2Angle < point1Angle) {
        point2Angle += 2 * M_PI;
    }

    CGFloat midpointAngle = (point1Angle + point2Angle) / 2;
    CGPoint edgePoint = [self calculatePointOnCircle:arcCircle angle:midpointAngle];

    [Logger logStringWithFormat:@"checking p1: (%lf, %lf) and p2: (%lf, %lf) edgePoint: (%lf, %lf)", point1.x, point1.y, point2.x, point2.y, edgePoint.x, edgePoint.y];

    for (NSNumber *groupCircleNum in group) {

        GridCircle *otherCircle = [self circleAtNSNumberIndex:groupCircleNum];
        
        if (arcCircle == otherCircle) {
            continue;
        }

        if ([self isPoint:&edgePoint withinCircle:otherCircle]) {
            // [Logger logStringWithFormat:@"point is in another circle: %ld, distToCenter: %lf, radius: %lf", l, edgePointDist, otherCircle.radius];
            [Logger logStringWithFormat:@"point is in another circle: %@", groupCircleNum];
            return NO;
        }
    }

    return YES;
}

- (BOOL)isPoint:(CGPoint *)point containedInArcShape:(NSArray *)arcShape {

    for (NSValue *arcValue in arcShape) {
        GridArc arc;
        [arcValue getValue:&arc size:sizeof(GridArc)];

        if ([self isPoint:point withinCircle:arc.circle]) {
            return YES;
        }   
    }

    return NO;
}

- (BOOL)isPoint:(CGPoint *)point withinArc:(GridArc *)arc {

    GridCircle *circle = arc->circle;

    if (![self isPoint:point withinCircle:circle]) {
        return NO;
    }

    CGFloat dist = [self calculateDistanceBetweenPoint:point andPoint:&circle->center];
    if (dist == 0) {
        return YES;
    }

    CGFloat angle = [self angleOfPoint:point aroundCircle:circle];
    while (angle < arc->startAngle) {
        angle += 2 * M_PI;
    }

    return angle >= arc->startAngle && angle <= arc->endAngle;

    // return ![self isPoint:point clockwiseToPoint:&arc->startPoint] && [self isPoint:point clockwiseToPoint:&arc->endPoint];
}

- (NSArray *)calculateIntersectionPointsBetweenCircle:(GridCircle *)circle1Ptr andCircle:(GridCircle *)circle2Ptr {

    GridCircle circle1 = *circle1Ptr;
    GridCircle circle2 = *circle2Ptr;

    CGFloat centerDist = [self calculateDistanceBetweenPoint:&circle1.center andPoint:&circle2.center];
    CGFloat a = (circle1.radius*circle1.radius - circle2.radius*circle2.radius + centerDist*centerDist) / (2 * centerDist);
    CGFloat h = sqrt(circle1.radius*circle1.radius - a*a);

    // circles do not intersect or are contained
    if (centerDist > circle1.radius + circle2.radius || centerDist < circle1.radius - circle2.radius || centerDist == 0) {
        return @[];
    }

    CGPoint centersMidPoint = CGPointMake(
        circle1.center.x + (a / centerDist) * (circle2.center.x - circle1.center.x),
        circle1.center.y + (a / centerDist) * (circle2.center.y - circle1.center.y)
    );

    // circles touch at one point
    if (centerDist == circle1.radius + circle2.radius) {

        NSDictionary *pointData = @{
            @"point": [NSValue valueWithCGPoint:centersMidPoint],
            @"angle": @([self angleOfPoint:&centersMidPoint aroundCircle:circle1Ptr]),
            @"otherCircle": [NSValue valueWithPointer:circle2Ptr],
            @"circle": [NSValue valueWithPointer:circle1Ptr],
            // @"pointPair": [NSValue valueWithCGPoint:centersMidPoint]
        };
        return @[pointData];
    }

    CGPoint p1 = CGPointMake(
        centersMidPoint.x + (h / centerDist) * (circle2.center.y - circle1.center.y),
        centersMidPoint.y - (h / centerDist) * (circle2.center.x - circle1.center.x)
    );
    CGPoint p2 = CGPointMake(
        centersMidPoint.x - (h / centerDist) * (circle2.center.y - circle1.center.y),
        centersMidPoint.y + (h / centerDist) * (circle2.center.x - circle1.center.x)
    );

    CGFloat p1Angle = [self angleOfPoint:&p1 aroundCircle:&circle1];
    CGFloat p2Angle = [self angleOfPoint:&p2 aroundCircle:&circle1];

    NSValue *p1Value = [NSValue valueWithCGPoint:p1];
    NSValue *p2Value = [NSValue valueWithCGPoint:p2];
    
    NSDictionary *point1Data = @{
        @"point": p1Value,
        @"angle": @(p1Angle),
        @"circle": [NSValue valueWithPointer:circle1Ptr],
        @"otherCircle": [NSValue valueWithPointer:circle2Ptr],
        @"pointPair": p2Value
    };
    NSDictionary *point2Data = @{
        @"point": p2Value,
        @"angle": @(p2Angle),
        @"circle": [NSValue valueWithPointer:circle1Ptr],
        @"otherCircle": [NSValue valueWithPointer:circle2Ptr],
        @"pointPair": p1Value
    };

    // [Logger logStringWithFormat:@"calculated intersection points for c1: %ld, c2: %ld, p1: (%lf, %lf) angle: %lf, p2: (%lf, %lf) angle: %lf",
    //                     circle1Index, circle2Index, p1.x, p1.y, p1Angle, p2.x,p2.y,p2Angle];

    return @[point1Data, point2Data];
}

- (CGFloat)angleOfPoint:(CGPoint *)point aroundCircle:(GridCircle *)circle {

    CGFloat angle = atan2(point->y - circle->center.y, point->x - circle->center.x);

    if (angle < 0) {
        angle += 2 * M_PI;
    } 

    return angle;
}

- (CGFloat)calculateDistanceBetweenPoint:(CGPoint *)p1 andPoint:(CGPoint *)p2 {
    CGFloat xDiff = p1->x - p2->x;
    CGFloat yDiff = p1->y - p2->y;
    return sqrt(xDiff * xDiff + yDiff * yDiff);
}

- (CGFloat)calculateSquaredDistanceBetweenPoint:(CGPoint *)p1 andPoint:(CGPoint *)p2 {
    CGFloat xDiff = p1->x - p2->x;
    CGFloat yDiff = p1->y - p2->y;
    return xDiff * xDiff + yDiff * yDiff;
}

- (CGPoint)calculatePointOnCircle:(GridCircle *)circle angle:(CGFloat)angle {

    CGPoint edgePoint = CGPointMake(
        circle->center.x + circle->radius * cos(angle),
        circle->center.y + circle->radius * sin(angle)
    );
    
    return edgePoint;
}

- (BOOL)isPoint:(CGPoint *)point withinCircle:(GridCircle *)circle {
    // CGFloat dist = [self calculateDistanceBetweenPoint:point andPoint:&circle->center];
    // [Logger logStringWithFormat:@"point:(%lf, %lf) within circle: center:(%lf, %lf) radius:%lf distToCenter:%lf", point->x, point->y, circle->center.x, circle->center.y, circle->radius, dist];
    // return dist < circle->radius;

    CGFloat radius = circle->radius;
    CGFloat squaredDist = [self calculateSquaredDistanceBetweenPoint:point andPoint:&circle->center];
    return squaredDist < radius * radius;
}

- (BOOL)isPoint:(CGPoint *)point1 clockwiseToPoint:(CGPoint *)point2 {
    return -point1->x*point2->y + point1->y*point2->x > 0;
}

- (CGPoint)calculateProjectionOfPoint:(CGPoint *)pointPtr toLineWithStartPoint:(CGPoint *)lineStartPointPtr endPoint:(CGPoint *)lineEndPointPtr {

    CGFloat segmentLengthSquared = [self calculateSquaredDistanceBetweenPoint:lineStartPointPtr andPoint:lineEndPointPtr];
    if (segmentLengthSquared == 0) {
        return *lineStartPointPtr;
    }

    CGPoint point = *pointPtr;
    CGPoint startPoint = *lineStartPointPtr;
    CGPoint endPoint = *lineEndPointPtr;

    CGPoint a = CGPointMake(
        point.x - startPoint.x,
        point.y - startPoint.y
    );

    CGPoint b = CGPointMake(
        endPoint.x - startPoint.x,
        endPoint.y - startPoint.y
    );

    CGFloat dot = a.x * b.x + a.y * b.y;
    CGFloat t = MAX(0, MIN(1, dot / segmentLengthSquared));

    CGPoint projection = CGPointMake(
        startPoint.x + t * b.x,
        startPoint.y + t * b.y
    );

    return projection;
}

- (CGPoint)calculatePointBetweenPoint:(CGPoint *)point1 andPoint:(CGPoint *)point2 destWeight:(CGFloat)destWeight {
    CGFloat sourceWeight = 1 - destWeight;

    return CGPointMake(
        point1->x * sourceWeight + point2->x * destWeight,
        point1->y * sourceWeight + point2->y * sourceWeight
    );
}

- (CGPoint)pointFrom3dPoint:(Grid3dPoint *)point3d {
    CGPoint point = CGPointMake(point3d->x, point3d->y);
    return point;
}

- (Grid3dPoint)point3dFromPoint:(CGPoint *)point {
    Grid3dPoint point3d;
    point3d.x = point->x;
    point3d.y = point->y;
    point3d.z = 0;
    return point3d;
}

- (BOOL)is3dPoint:(Grid3dPoint *)point containedInSphere:(GridCircle *)sphereDef {

    CGFloat xDiff = point->x - sphereDef->center.x;
    CGFloat yDiff = point->y - sphereDef->center.y;
    CGFloat zDiff = point->z - sphereDef->z;

    CGFloat distSquared = xDiff*xDiff + yDiff*yDiff + zDiff*zDiff;
    CGFloat radiusSquared = sphereDef->radius * sphereDef->radius;

    return distSquared <= radiusSquared;
}

- (Grid3dPoint)calculateProjectionOfPoint:(Grid3dPoint *)point ontoSphere:(GridCircle *)sphereDef {

    Grid3dPoint sphereCenter;
    sphereCenter.x = sphereDef->center.x;
    sphereCenter.y = sphereDef->center.y;
    sphereCenter.z = sphereDef->z;

    CGFloat xDiff = point->x - sphereCenter.x;
    CGFloat yDiff = point->y - sphereCenter.y;
    CGFloat zDiff = point->z - sphereCenter.z;

    CGFloat dist = sqrt(xDiff*xDiff + yDiff*yDiff + zDiff*zDiff);
    CGFloat scaleMult = sphereDef->radius / dist;

    Grid3dPoint res;
    res.x = sphereCenter.x + xDiff * scaleMult;
    res.y = sphereCenter.y + yDiff * scaleMult;
    res.z = sphereCenter.z + zDiff * scaleMult;

    return res;
}

- (CGFloat)calculateDistanceBetween3dPoint:(Grid3dPoint *)point1 and3dPoint:(Grid3dPoint *)point2 {

    CGFloat xDiff = point1->x - point2->x;
    CGFloat yDiff = point1->y - point2->y;
    CGFloat zDiff = point1->z - point2->z;

    return sqrt(xDiff*xDiff + yDiff*yDiff + zDiff*zDiff);
}

- (Grid3dPoint)calculate3dPointBetween3dPoint:(Grid3dPoint *)point1 and3dPoint:(Grid3dPoint *)point2 destWeight:(CGFloat)destWeight {
    
    Grid3dPoint res;
    CGFloat sourceWeight = 1 - destWeight;

    res.x = point1->x * sourceWeight + point2->x * destWeight;
    res.y = point1->y * sourceWeight + point2->y * sourceWeight;
    res.z = point1->z * sourceWeight + point2->z * destWeight;

    return res;
}



@end