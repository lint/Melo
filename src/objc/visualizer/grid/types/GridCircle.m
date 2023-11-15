
#import "GridCircle.h"

@implementation GridCircle 

- (instancetype)initWithWithIdentifier:(NSString *)ident normalizedCenter:(CGPoint)center radius:(CGFloat)radius strength:(CGFloat)strength {

    if ((self = [super init])) {

        _identifier = ident;
        _viewNormalizedCenter = center;
        _radius = radius;
        _strength = strength;
    }

    return self;
}

@end