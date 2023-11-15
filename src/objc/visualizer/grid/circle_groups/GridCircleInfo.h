
#import <UIKit/UIKit.h>

@class GridCircle;

@interface GridCircleInfo : NSObject
@property(strong, nonatomic) GridCircle *circle;
@property(strong, nonatomic) NSMutableArray *intersectingCircles;
@property(strong, nonatomic) NSMutableArray *intersectionLines;
@property(strong, nonatomic) NSMutableArray *outerArcs;
@property(strong, nonatomic) NSMutableArray *regionBoundaryLines;
// @property(strong, nonatomic) NS
@end