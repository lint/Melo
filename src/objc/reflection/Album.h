
#import <UIKit/UIKit.h>

// class representing an album / playlist displayed in the recently added section
@interface Album : NSObject
@property(strong, nonatomic) NSString *identifier;
@property(strong, nonatomic) NSString *artist;
@property(strong, nonatomic) NSString *title;
@property(assign, nonatomic) NSInteger realIndex;

- (instancetype)initWithDictionary:(NSDictionary *)arg1;
- (NSIndexPath *)realIndexPath;
- (NSDictionary *)toDictionary;
- (instancetype)copy;
- (BOOL)isEqual:(id)arg1;

@end