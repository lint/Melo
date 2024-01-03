
#import "GridVisualizerManager.h"
#import "circle_groups/circle_groups.h"
#import "types/types.h"
#import "../../utilities/utilities.h"
#import "GridMath.h"

@implementation GridVisualizerManager

- (instancetype)init {

    if ((self = [super init])) {

        _numColumns = 0;
        _lastNumRows = 0;
        _viewBounds = CGRectZero;

        // _circles = [NSMutableDictionary dictionary];
        _circleChangeDetected = NO;
        _gridPoints = [NSMutableArray array];
        _circleGroups = [[GridCircleGroupCollection alloc] init];
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
        
        _numColumns = newNumColumns;
        _lastNumRows = 0;

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

    // reset gridpoints array
    _gridPoints = [NSMutableArray array];

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

    // set the default value for every point in the grid
    for (NSInteger i = 0; i < _numColumns; i++) {     
        
        NSMutableArray *column = [NSMutableArray array];

        for (NSInteger j = 0; j < numRows; j++) {

            CGPoint defaultValue = CGPointMake(i * 1.0 / _numColumns, j * 1.0 / _numColumns);
            GridPoint *gridPoint = [[GridPoint alloc] initWithDefaultValue:defaultValue];

            [column addObject:gridPoint];
        }

        [_gridPoints addObject:column];
    }

    _lastNumRows = numRows;

    [self addCircleWithIdentifier:@"test" normCenter:CGPointMake(.4, .5) radius:.20 strength:.5];
    [self addCircleWithIdentifier:@"test2" normCenter:CGPointMake(.6, .5) radius:.20 strength:.5];
    // [self addCircleWithIdentifier:@"test3" normCenter:CGPointMake(.5, .3) radius:.20 strength:.5];
    // [self addCircleWithIdentifier:@"test3" center:CGPointMake(.5, .5) radius:.1 strength:1];
    // [self addCircleWithIdentifier:@"test3" center:CGPointMake(.75, .5) radius:.2 strength:1];

    // _shapeLayer.path = [self pathFromGrid].CGPath;
}

// adds a new circle to the circles dictionary with the given information (overwrites circle with identifier if it exists)
- (void)addCircleWithIdentifier:(NSString *)ident normCenter:(CGPoint)center radius:(CGFloat)radius strength:(CGFloat)strength {

    GridCircle *circle = [[GridCircle alloc] initWithIdentifier:ident normalizedCenter:center radius:radius strength:strength];
    if ([self hasViewBounds]) {
        circle.center = CGPointMake(center.x, center.y * _viewBounds.size.height / _viewBounds.size.width);
    } else {
        circle.center = CGPointZero;
    }

    [_circleGroups addCircleToCollection:circle];

    _circleChangeDetected = YES;
}

- (void)removeCircleWithIdentifier:(NSString *)ident {
    [_circleGroups removeCircleWithIdentifierFromCollection:ident];
    _circleChangeDetected = YES;
}

- (void)calculateCircleWidthBasedCenters {

    if (![self hasViewBounds]) {
        return;
    }

    CGFloat viewWidth = _viewBounds.size.width;
    CGFloat viewHeight = _viewBounds.size.height;

    for (NSInteger i = 0; i < [_circleGroups.circles count]; i++) {
        GridCircle *circle = _circleGroups.circles[i];
        CGPoint normCenter = circle.viewNormalizedCenter;
        circle.center = CGPointMake(normCenter.x, normCenter.y * viewHeight / viewWidth);
    }
}

// resets the gridpoints' destination and source values
- (void)prepareGridPointsForAnimation {

    for (NSInteger x = 0; x < _numColumns; x++) {
        for (NSInteger y = 0; y < _lastNumRows; y++) {

            GridPoint *gridPoint = _gridPoints[x][y];

            if (_circleChangeDetected) {
                gridPoint.dst = gridPoint.defaultValue;
                // gridPoint.circleApplySrc = gridPoint.defaultValue;
                // gridPoint.appliedCirclesMask = 0;
            }
            gridPoint.src = gridPoint.cur;            
            
            // _gridPoints[x][y] = gridPoint;
        }
    }
}

// - (GridPoint)applyCircle:(GridCircle)circle toPoint:(GridPoint)gridPoint 
//     circleIndex:(NSInteger)circleIndex {
    
//     CGFloat startingX = gridPoint.circleApplySrc.x;
//     CGFloat startingY = gridPoint.circleApplySrc.y;

//     CGFloat xDiff = startingX - circle.center.x;
//     CGFloat yDiff = startingY - circle.center.y;
//     CGFloat distance = sqrtf(xDiff * xDiff + yDiff * yDiff);

//     if (distance > circle.radius || distance == 0) {
//     // if (!distance) {
//         return gridPoint;
//     }

//     CGFloat distMult = circle.radius / distance;

//     CGPoint closestCirclePoint = CGPointMake(
//         circle.center.x + xDiff * distMult,
//         circle.center.y + yDiff * distMult
//     );

//     CGFloat dstXTranslation = (closestCirclePoint.x - startingX) * circle.strength;
//     CGFloat dstYTranslation = (closestCirclePoint.y - startingY) * circle.strength;

//     gridPoint.dst.x += dstXTranslation;
//     gridPoint.dst.y += dstYTranslation;
//     gridPoint.appliedCirclesMask |= 1 << circleIndex;

//     return gridPoint;
// }

// translates the grid points within the radius of any defined circle
- (void)applyCirclesToGrid {

    // grid is dependent on the visualizer view size and if the circles actually changed
    if (![self hasViewBounds] || !_circleChangeDetected) {
        return;
    }

    _circleChangeDetected = NO;

    for (NSInteger x = 0; x < _numColumns; x++) {
        for (NSInteger y = 0; y < _lastNumRows; y++) {

            GridPoint *gridPoint = _gridPoints[x][y];

            for (GridCircleGroup *group in _circleGroups.groups) {

                if ([group circlesContainPoint:gridPoint.defaultValue]) {
                    CGPoint newPoint = [group calculateClosestPointToShapeFromPoint:gridPoint.defaultValue];
                    gridPoint.dst = newPoint;
                    break;
                }
            }

            // CGFloat maxDist = 0;
            // CGPoint endPoint;

            // for (NSInteger i = 0; i < _numCircles; i++) {

            //     CGPoint startPoint = gridPoint->defaultValue;

            //     GridCircle *circle = [self circleAtIndex:i];
            //     Grid3dPoint point3d = [self point3dFromPoint:&startPoint];

            //     if (![self is3dPoint:&point3d containedInSphere:circle]) {
            //         continue;
            //     }

            //     Grid3dPoint proj = [self calculateProjectionOfPoint:&point3d ontoSphere:circle];
            //     Grid3dPoint weightedProj = [self calculate3dPointBetween3dPoint:&point3d and3dPoint:&proj destWeight:circle->strength];

            //     CGFloat dist = [self calculateDistanceBetween3dPoint:&point3d and3dPoint:&proj];

            //     if (dist > maxDist) {
            //         maxDist = dist;
            //         endPoint = CGPointMake(proj.x, proj.y);
            //     }
            // }

            // if (maxDist > 0) {
            //     gridPoint->dst = endPoint;
            // }
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

            GridPoint *gridPoint = _gridPoints[x][y];

            CGPoint currPoint = CGPointMake(
                sourceWeight * gridPoint.src.x + destWeight * gridPoint.dst.x,
                sourceWeight * gridPoint.src.y + destWeight * gridPoint.dst.y
            );
            
            gridPoint.cur = currPoint;
        }
    }    
}

// creates a bezier path following every row and column in the grid
- (UIBezierPath *)currentGridPath {

    UIBezierPath *path = [UIBezierPath new];

    GridPoint *gridPoint;

    // create a line down each column
    for (NSInteger i = 0; i < _numColumns; i++) {
        
        gridPoint = _gridPoints[i][0];
        [path moveToPoint:[self displayCoordsForPoint:gridPoint.cur]];
    
        for (NSInteger j = 1; j < _lastNumRows; j++) {
            gridPoint = _gridPoints[i][j];
            [path addLineToPoint:[self displayCoordsForPoint:gridPoint.cur]];
        }
    }

    // create a line across each row
    for (NSInteger i = 0; i < _lastNumRows; i++) {
        
        gridPoint = _gridPoints[0][i];
        [path moveToPoint:[self displayCoordsForPoint:gridPoint.cur]];

        for (NSInteger j = 1; j < _numColumns; j++) {
            gridPoint = _gridPoints[j][i];
            [path addLineToPoint:[self displayCoordsForPoint:gridPoint.cur]];
        }
    }

    return path;
}

- (UIBezierPath *)currentCirclesPath {

    UIBezierPath *path = [UIBezierPath new];

    for (NSInteger i = 0; i < [_circleGroups.circles count]; i++) {
        GridCircle *circle = _circleGroups.circles[i];

        CGPoint edgePoint = [GridMath pointOnCircle:circle withAngle:0];
        CGPoint edgePointDisplayCoords = [self displayCoordsForPoint:edgePoint];
        CGPoint centerDisplayCoords = [self displayCoordsForPoint:circle.center];

        [path moveToPoint:edgePointDisplayCoords];
        [path addArcWithCenter:centerDisplayCoords radius:circle.radius * _viewBounds.size.width startAngle:0 endAngle:M_PI clockwise:NO];
        [path addArcWithCenter:centerDisplayCoords radius:circle.radius * _viewBounds.size.width startAngle:M_PI endAngle:0 clockwise:NO];
    }

    return path;
}

- (UIBezierPath *)currentIntersectionLinesPath {

    UIBezierPath *path = [UIBezierPath new];

    for (GridCircleGroup *group in _circleGroups.groups) {

        // for (GridCircle *circle in group.circles) {
        //     GridCircleInfo *circleInfo = [group circleInfoForCircle:circle];

        //     for (GridLine *line in circleInfo.regionBoundaryLines) {

        //         CGPoint lineStartDisplayCoords = [self displayCoordsForPoint:line.start];
        //         CGPoint lineEndDisplayCoords = [self displayCoordsForPoint:line.end];

        //         [path moveToPoint:lineStartDisplayCoords];
        //         [path addLineToPoint:lineEndDisplayCoords];
        //     }
        // }

        for (GridLine *line in group.edges) {

            CGPoint lineStartDisplayCoords = [self displayCoordsForPoint:line.start];
            CGPoint lineEndDisplayCoords = [self displayCoordsForPoint:line.end];

            [path moveToPoint:lineStartDisplayCoords];
            [path addLineToPoint:lineEndDisplayCoords];
        }

    }

    return path;
}

- (CGPoint)displayCoordsForPoint:(CGPoint)point {
    
    return CGPointMake(
        point.x * _viewBounds.size.width,
        point.y * _numColumns / _lastNumRows * _viewBounds.size.height
    );
}

@end