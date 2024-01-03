
#import <UIKit/UIKit.h>

@interface GridLine : NSObject
@property(assign, nonatomic) CGPoint start;
@property(assign, nonatomic) CGPoint end;
- (instancetype)initWithStartPoint:(CGPoint)start endPoint:(CGPoint)end;
- (CGPoint)calculateMidpoint;
@end