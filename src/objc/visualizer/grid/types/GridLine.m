
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



@end

