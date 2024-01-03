
#import <UIKit/UIKit.h>

@class GridCircle;

@interface GridArc : NSObject
@property(assign, nonatomic) CGFloat startAngle;
@property(assign, nonatomic) CGFloat endAngle;
@property(strong, nonatomic) GridCircle *circle;
- (instancetype)initWithStartAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle circle:(GridCircle *)circle;
- (CGPoint)calculateMidpoint;
@end