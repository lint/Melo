
#import "GridMath.h"
#import "types/types.h"
#import "../../../interfaces/interfaces.h"

@implementation GridMath

+ (BOOL)findIntersectionOfLine:(GridLine *)line1 andLine:(GridLine *)line2 solution:(CGPoint *)solPoint {

    // from https://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect

    CGPoint v1 = CGPointMake(line1.end.x - line1.start.x, line1.end.y - line1.start.y);
    CGPoint v2 = CGPointMake(line2.end.x - line2.start.x, line2.end.y - line2.start.y);

    CGFloat s = (-v1.y * (line1.start.x - line2.start.x) + v1.x * (line1.start.y - line2.start.y)) / (-v2.x * v1.y + v1.x * v2.y);
    CGFloat t = ( v2.x * (line1.start.y - line2.start.y) - v2.y * (line1.start.x - line2.start.x)) / (-v2.x * v1.y + v1.x * v2.y);
    
    // intersection detected
    if (s >= 0 && s <= 1 && t >= 0 && t <= 1) {

        if (solPoint) {
            solPoint->x = line1.start.x + (t * v1.x);
            solPoint->y = line1.start.y + (t * v1.y);
        }

        return YES;
    }

    return NO;
}

+ (CGFloat)powerOfPoint:(CGPoint)point aroundCircle:(GridCircle *)circle {
    CGFloat radius = circle.radius;
    return [GridMath squaredDistanceBetweenPoint:point andPoint:circle.center] - radius*radius;
}

+ (CGFloat)angleOfPoint:(CGPoint)point aroundCircle:(GridCircle *)circle {

    CGFloat angle = atan2(point.y - circle.center.y, point.x - circle.center.x);

    if (angle < 0) {
        angle += 2 * M_PI;
    } 

    return angle;
}

+ (CGFloat)distanceBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2 {
    return sqrtf([GridMath squaredDistanceBetweenPoint:point1 andPoint:point2]);
}

+ (CGFloat)squaredDistanceBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2 {
    CGFloat xDiff = point1.x - point2.x;
    CGFloat yDiff = point1.y - point2.y;
    return xDiff * xDiff + yDiff * yDiff;
}

+ (CGPoint)projectPoint:(CGPoint)point ontoCircle:(GridCircle *)circle {

    CGFloat angle = [GridMath angleOfPoint:point aroundCircle:circle];
    return [GridMath pointOnCircle:circle withAngle:angle];
}

+ (CGPoint)pointOnCircle:(GridCircle *)circle withAngle:(CGFloat)angle {

    CGPoint edgePoint = CGPointMake(
        circle.center.x + circle.radius * cos(angle),
        circle.center.y + circle.radius * sin(angle)
    );
    
    return edgePoint;
}

+ (BOOL)isPoint:(CGPoint)point withinCircle:(GridCircle *)circle {
    // CGFloat dist = [GridMath calculateDistanceBetweenPoint:point andPoint:&circle->center];
    // [Logger logStringWithFormat:@"point:(%lf, %lf) within circle: center:(%lf, %lf) radius:%lf distToCenter:%lf", point->x, point->y, circle->center.x, circle->center.y, circle->radius, dist];
    // return dist < circle->radius;

    CGFloat radius = circle.radius;
    CGFloat squaredDist = [GridMath squaredDistanceBetweenPoint:point andPoint:circle.center];
    return squaredDist < radius * radius;
}

+ (BOOL)isPoint:(CGPoint)point1 clockwiseToPoint:(CGPoint)point2 {
    return -point1.x*point2.y + point1.y*point2.x > 0;
}

+ (CGPoint)pointBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2 destWeight:(CGFloat)destWeight {
    CGFloat sourceWeight = 1 - destWeight;

    return CGPointMake(
        point1.x * sourceWeight + point2.x * destWeight,
        point1.y * sourceWeight + point2.y * sourceWeight
    );
}

+ (CGPoint)projectPoint:(CGPoint)point ontoLine:(GridLine *)line {
    return [GridMath projectPoint:point ontoLineWithStartPoint:line.start endPoint:line.end];
}

+ (CGPoint)projectPoint:(CGPoint )point ontoLineWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {

    CGFloat segmentLengthSquared = [GridMath squaredDistanceBetweenPoint:startPoint andPoint:endPoint];
    if (segmentLengthSquared == 0) {
        return startPoint;
    }

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

+ (BOOL)isPoint:(CGPoint)point withinSectorOfArc:(GridArc *)arc {

    GridCircle *circle = arc.circle;

    // check if the point is within the radius of the circle of the arc
    if (![GridMath isPoint:point withinCircle:circle]) {
        return NO;
    }

    CGFloat dist = [GridMath squaredDistanceBetweenPoint:point andPoint:circle.center];
    if (dist == 0) {
        return YES;
    }

    CGFloat angle = [GridMath angleOfPoint:point aroundCircle:circle];
    while (angle < arc.startAngle) {
        angle += 2 * M_PI;
    }

    return angle >= arc.startAngle && angle <= arc.endAngle;

    // return ![self isPoint:point clockwiseToPoint:&arc->startPoint] && [self isPoint:point clockwiseToPoint:&arc->endPoint];
}

+ (NSArray *)intersectionPointsBetweenCircle:(GridCircle *)circle1 andCircle:(GridCircle *)circle2 {

    CGFloat centerDist = [GridMath distanceBetweenPoint:circle1.center andPoint:circle2.center];
    CGFloat a = (circle1.radius*circle1.radius - circle2.radius*circle2.radius + centerDist*centerDist) / (2 * centerDist);
    CGFloat h = sqrtf(circle1.radius*circle1.radius - a*a);

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
            @"angle": @([self angleOfPoint:centersMidPoint aroundCircle:circle1]),
            @"otherCircle": circle2,
            @"circle": circle1
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

    CGFloat p1Angle = [self angleOfPoint:p1 aroundCircle:circle1];
    CGFloat p2Angle = [self angleOfPoint:p2 aroundCircle:circle1];

    NSValue *p1Value = [NSValue valueWithCGPoint:p1];
    NSValue *p2Value = [NSValue valueWithCGPoint:p2];
    
    NSDictionary *point1Data = @{
        @"point": p1Value,
        @"angle": @(p1Angle),
        @"circle": circle1,
        @"otherCircle": circle2,
        @"pointPair": p2Value
    };
    NSDictionary *point2Data = @{
        @"point": p2Value,
        @"angle": @(p2Angle),
        @"circle": circle1,
        @"otherCircle": circle2,
        @"pointPair": p1Value
    };

    // [Logger logStringWithFormat:@"calculated intersection points for c1: %ld, c2: %ld, p1: (%lf, %lf) angle: %lf, p2: (%lf, %lf) angle: %lf",
    //                     circle1Index, circle2Index, p1.x, p1.y, p1Angle, p2.x,p2.y,p2Angle];

    return @[point1Data, point2Data];
}

// - (CGPoint)pointFrom3dPoint:(Grid3dPoint *)point3d {
//     CGPoint point = CGPointMake(point3d->x, point3d->y);
//     return point;
// }

// - (Grid3dPoint)point3dFromPoint:(CGPoint *)point {
//     Grid3dPoint point3d;
//     point3d.x = point->x;
//     point3d.y = point->y;
//     point3d.z = 0;
//     return point3d;
// }

// - (BOOL)is3dPoint:(Grid3dPoint *)point containedInSphere:(GridCircle *)sphereDef {

//     CGFloat xDiff = point->x - sphereDef->center.x;
//     CGFloat yDiff = point->y - sphereDef->center.y;
//     CGFloat zDiff = point->z - sphereDef->z;

//     CGFloat distSquared = xDiff*xDiff + yDiff*yDiff + zDiff*zDiff;
//     CGFloat radiusSquared = sphereDef->radius * sphereDef->radius;

//     return distSquared <= radiusSquared;
// }

// - (Grid3dPoint)calculateprojectPoint:(Grid3dPoint *)point ontoSphere:(GridCircle *)sphereDef {

//     Grid3dPoint sphereCenter;
//     sphereCenter.x = sphereDef->center.x;
//     sphereCenter.y = sphereDef->center.y;
//     sphereCenter.z = sphereDef->z;

//     CGFloat xDiff = point->x - sphereCenter.x;
//     CGFloat yDiff = point->y - sphereCenter.y;
//     CGFloat zDiff = point->z - sphereCenter.z;

//     CGFloat dist = sqrtf(xDiff*xDiff + yDiff*yDiff + zDiff*zDiff);
//     CGFloat scaleMult = sphereDef->radius / dist;

//     Grid3dPoint res;
//     res.x = sphereCenter.x + xDiff * scaleMult;
//     res.y = sphereCenter.y + yDiff * scaleMult;
//     res.z = sphereCenter.z + zDiff * scaleMult;

//     return res;
// }

// - (CGFloat)calculateDistanceBetween3dPoint:(Grid3dPoint *)point1 and3dPoint:(Grid3dPoint *)point2 {

//     CGFloat xDiff = point1->x - point2->x;
//     CGFloat yDiff = point1->y - point2->y;
//     CGFloat zDiff = point1->z - point2->z;

//     return sqrtf(xDiff*xDiff + yDiff*yDiff + zDiff*zDiff);
// }

// - (Grid3dPoint)calculate3dPointBetween3dPoint:(Grid3dPoint *)point1 and3dPoint:(Grid3dPoint *)point2 destWeight:(CGFloat)destWeight {
    
//     Grid3dPoint res;
//     CGFloat sourceWeight = 1 - destWeight;

//     res.x = point1->x * sourceWeight + point2->x * destWeight;
//     res.y = point1->y * sourceWeight + point2->y * sourceWeight;
//     res.z = point1->z * sourceWeight + point2->z * destWeight;

//     return res;
// }
@end