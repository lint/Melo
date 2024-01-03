
#import <UIKit/UIKit.h>

// forward declarations
@class GridCircle, GridArc, GridLine;

@interface GridMath : NSObject
+ (BOOL)findIntersectionOfLine:(GridLine *)line1 andLine:(GridLine *)line2 solution:(CGPoint *)solPoint;
+ (CGFloat)powerOfPoint:(CGPoint)point aroundCircle:(GridCircle *)circle;
+ (CGFloat)angleOfPoint:(CGPoint)point aroundCircle:(GridCircle *)circle;
+ (CGFloat)distanceBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2;
+ (CGFloat)squaredDistanceBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2;
+ (CGPoint)projectPoint:(CGPoint)point ontoCircle:(GridCircle *)circle;
+ (CGPoint)pointOnCircle:(GridCircle *)circle withAngle:(CGFloat)angle;
+ (BOOL)isPoint:(CGPoint)point withinCircle:(GridCircle *)circle;
+ (BOOL)isPoint:(CGPoint)point1 clockwiseToPoint:(CGPoint)point2;
+ (CGPoint)pointBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2 destWeight:(CGFloat)destWeight;
+ (CGPoint)projectPoint:(CGPoint)point ontoLine:(GridLine *)line;
+ (CGPoint)projectPoint:(CGPoint)point ontoLineWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint;
+ (BOOL)isPoint:(CGPoint)point withinSectorOfArc:(GridArc *)arc;
+ (NSArray *)intersectionPointsBetweenCircle:(GridCircle *)circle1 andCircle:(GridCircle *)circle2;
@end