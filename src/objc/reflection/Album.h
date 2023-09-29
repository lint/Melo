
#import <UIKit/UIKit.h>

// forward declaration
@class Section;

// class representing an album / playlist displayed in the recently added section
@interface Album : NSObject
@property(strong, nonatomic) NSString *identifier;
@property(strong, nonatomic) NSString *artist;
@property(strong, nonatomic) NSString *title;
@property(assign, nonatomic) NSInteger realIndex;
@property(strong, nonatomic) Section *section;

- (instancetype)initWithDictionary:(NSDictionary *)arg1;
- (NSIndexPath *)realIndexPath;
- (NSDictionary *)toDictionary;
- (instancetype)copy;
- (BOOL)isEqual:(id)arg1;
- (BOOL)isFakeAlbum;
+ (Album *)createFakeAlbum;
@end