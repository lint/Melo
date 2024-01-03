#import <UIKit/UIKit.h>

@class GridCircle, GridLine, GridArc, GridCircleInfo;

typedef enum : NSInteger {
    GRID_CIRCLE_GROUP_ADDITION_STATUS_SUCCESSFUL,
    GRID_CIRCLE_GROUP_ADDITION_STATUS_CONTAINED,
    GRID_CIRCLE_GROUP_ADDITION_STATUS_FAILURE,
} NewCircleAdditionStatus;

@interface GridCircleGroup : NSObject
@property(strong, nonatomic) NSMutableArray *circles;
@property(strong, nonatomic) NSMutableDictionary *circleInfoMap;
@property(strong, nonatomic) NSMutableString *testString;
@property(strong, nonatomic) NSMutableArray *edges;

- (GridCircle *)circleWithIdentifier:(NSString *)ident;
- (void)removeCircleWithIdentifier:(NSString *)ident;
- (void)removeCirclesInArray:(NSArray *)circlesToRemove;
- (void)addNewCircle:(GridCircle *)circle;
- (NewCircleAdditionStatus)attemptCircleAddition:(GridCircle *)newCircle;
- (void)calculateShape;
- (void)calculateTriangulation;
- (CGPoint)calculateClosestPointToShapeFromPoint:(CGPoint)point;
- (void)calculateRegionBoundariesForCircle:(GridCircle *)circle;
- (NSArray *)circlesWithRegionContainingPoint:(CGPoint)point;
- (NSInteger)numCirclesWithRegionContainingPoint:(CGPoint)point;
// - (BOOL)findIntersectionOfLine:(GridLine *)line1 andLine:(GridLine *)line2 solution:(CGPoint *)solPoint;
- (void)calculateIntersectionsForCircle:(GridCircle *)circle;
- (BOOL)isArcGroupOuterEdge:(GridArc *)arc;
- (GridCircleInfo *)circleInfoForCircle:(GridCircle *)circle;
- (BOOL)circlesContainPoint:(CGPoint)point;

@end