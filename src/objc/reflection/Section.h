
#import <UIKit/UIKit.h>

// forward declarations
@class Album;

// represents an individual section of albums in the recently added area
@interface Section : NSObject
@property(strong, nonatomic) NSString *identifier;
@property(strong, nonatomic) NSString *title;
@property(strong, nonatomic) NSString *subtitle;
@property(strong, nonatomic) NSMutableArray<Album *> *albums;
@property(assign, nonatomic, getter=isCollapsed) BOOL collapsed;
@property(assign, nonatomic, getter=isVisible) BOOL visible; // TODO: remove this

- (instancetype)init;
- (instancetype)initWithDictionary:(NSDictionary *)arg1;
- (instancetype)initWithIdentifier:(NSString *)arg1 title:(NSString *)arg2 subtitle:(NSString *)arg3;
- (NSInteger)numberOfAlbums;
- (NSInteger)indexOfAlbum:(Album *)arg1;
- (Album *)albumAtIndex:(NSInteger)arg1;
- (Album *)albumWithIdentifier:(NSString *)arg1;
- (void)removeAlbum:(Album *)arg1;
- (void)removeAlbumAtIndex:(NSInteger)arg1;
- (BOOL)removeAlbumWithIdentifier:(NSString *)arg1;
- (void)removeAllAlbums;
- (void)addAlbum:(Album *)arg1;
- (void)insertAlbum:(Album *)arg1 atIndex:(NSInteger)arg2;
- (void)swapAlbumAtIndex:(NSInteger)arg1 withAlbumAtIndex:(NSInteger)arg2;
- (void)moveAlbumAtIndex:(NSInteger)arg1 toIndex:(NSInteger)arg2;
- (BOOL)isEmpty;
- (Section *)copy;
- (NSDictionary *)toDictionary;
- (NSString *)displayTitle;

+ (instancetype)emptyRecentSection;
+ (instancetype)emptyPinnedSection;
@end
