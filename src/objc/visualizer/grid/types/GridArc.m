
#import "GridArc.h"
#import "GridCircle.h"
#import "../GridMath.h"

@implementation GridArc

- (instancetype)initWithStartAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle circle:(GridCircle *)circle {

    if ((self = [super init])) {

        if (endAngle < startAngle) {
            endAngle += 2 * M_PI;
        }

        _startAngle = startAngle;
        _endAngle = endAngle;
        _circle = circle;
    }

    return self;
}

- (CGPoint)calculateMidpoint {
    CGFloat midpointAngle = (_startAngle + _endAngle) / 2;
    return [GridMath pointOnCircle:_circle withAngle:midpointAngle];
}

@end

