typedef struct GridPoint {
    CGPoint defaultValue;
    CGPoint src;
    CGPoint dst;
    CGPoint cur;
    CGPoint circleApplySrc;
    NSUInteger appliedCirclesMask;
} GridPoint;

typedef struct GridCircle {
    CGPoint normCenter;
    CGPoint center;
    CGFloat radius;
    CGFloat z;
    CGFloat strength;
    NSString *identifier;
    BOOL isContained;
    BOOL isIntersected;
    NSInteger groupIndex;
} GridCircle;

typedef struct GridArc {
    GridCircle *circle;
    CGPoint startPoint;
    CGFloat startAngle;
    GridCircle *startOtherCircle;
    CGPoint startPointPair;
    CGPoint endPoint;
    CGFloat endAngle;
    GridCircle *endOtherCircle;
} GridArc;

typedef struct Grid3dPoint {
    CGFloat x, y, z;
} Grid3dPoint;