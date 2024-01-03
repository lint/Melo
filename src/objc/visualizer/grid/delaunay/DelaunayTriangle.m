
#import "DelaunayTriangle.h"
#import "DelaunaySite.h"
#import <math.h>

@implementation DelaunayTriangle

- (instancetype)initWithSite1:(DelaunaySite *)site1 site2:(DelaunaySite *)site2 site3:(DelaunaySite *)site3 {

    if ((self = [super init])) {

        _site1 = site1;
        _site2 = site2;
        _site3 = site3;
    }

    return self;
}

- (CGPoint)calculateCircumcenter {

    // from https://stackoverflow.com/questions/56224824/how-do-i-find-the-circumcenter-of-the-triangle-using-python-without-external-lib

    CGPoint p1 = _site1.coordinates;
    CGPoint p2 = _site2.coordinates;
    CGPoint p3 = _site3.coordinates;

    CGPoint c;

    if (isnan(p1.x) || isnan(p1.y)) {
        c = CGPointMake((p2.x + p3.x) / 2, (p2.y + p3.y) / 2);
    } else if (isnan(p2.x) || isnan(p2.y)) {
        c = CGPointMake((p1.x + p3.x) / 2, (p1.y + p3.y) / 2);
    } else if (isnan(p3.x) || isnan(p3.y)) {
        c = CGPointMake((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
    } else {
        CGFloat d = 2 * (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y));
        c = CGPointMake(
            ((p1.x * p1.x + p1.y * p1.y) * (p2.y - p3.y) + (p2.x * p2.x + p2.y * p2.y) * (p3.y - p1.y) + (p3.x * p3.x + p3.y * p3.y) * (p1.y - p2.y)) / d,
            ((p1.x * p1.x + p1.y * p1.y) * (p3.x - p2.x) + (p2.x * p2.x + p2.y * p2.y) * (p1.x - p3.x) + (p3.x * p3.x + p3.y * p3.y) * (p2.x - p1.x)) / d
        );
    }    

    return c;
}

- (BOOL)isAdjacentToTriangle:(DelaunayTriangle *)triangle {

    NSArray *sites = [self sites];
    NSArray *otherSites = [triangle sites];

    NSInteger numSameSites = 0;

    for (DelaunaySite *site in sites) {
        for (DelaunaySite *otherSite in otherSites) {
            if (site == otherSite) {
                numSameSites++;
            }
        }
    }

    return numSameSites == 2;
}

- (NSArray *)sites {
    return @[_site1, _site2, _site3];
}

@end