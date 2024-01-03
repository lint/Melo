
#import "GridPoint.h"

@implementation GridPoint

- (instancetype)initWithDefaultValue:(CGPoint)defaultValue {

    if ((self = [super init])) {

        _defaultValue = defaultValue;
        _src = defaultValue;
        _cur = defaultValue;
        _dst = defaultValue;
    }

    return self;
}

@end