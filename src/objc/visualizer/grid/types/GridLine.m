
#import "GridLine.h"

@implementation GridLine

- (instancetype)initWithStartPoint:(CGPoint)start endPoint:(CGPoint)end {

    if ((self = [super init])) {
        _start = start;
        _end = end;
    }

    return self;
}

// TOOD: define length here? calculate it when initialized?

- (CGPoint)calculateMidpoint {
    return CGPointMake((_start.x + _end.x) / 2, (_start.y + _end.y) / 2);
}



@end

