
#import <UIKit/UIKit.h>

@interface GridPoint : NSObject

@property(assign, nonatomic) CGPoint defaultValue;
@property(assign, nonatomic) CGPoint src;
@property(assign, nonatomic) CGPoint dst;
@property(assign, nonatomic) CGPoint cur;

- (instancetype)initWithDefaultValue:(CGPoint)defaultValue;

@end