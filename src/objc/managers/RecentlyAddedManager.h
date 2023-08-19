
#import <UIKit/UIKit.h>

// forward declarations
@class Album, Section;

// manager class to inject album/section data for each LibraryRecentlyAddedViewController 
@interface RecentlyAddedManager : NSObject
@property(strong, nonatomic) NSMutableArray *sections;
@property(assign, nonatomic) BOOL processedRealAlbumOrder;
// @property(strong, nonatomic) NSLock 

- (instancetype)init;
- (NSIndexPath *)translateIndexPath:(NSIndexPath *)arg1;
- (NSArray *)recreateRealAlbumOrder;
- (void)processRealAlbumOrder:(NSArray *)arg1;
- (BOOL)isReadyForUse;

- (BOOL)canShiftAlbumAtAdjustedIndexPath:(NSIndexPath *)arg1 movingLeft:(BOOL)arg2;
- (void)moveAlbumAtAdjustedIndexPath:(NSIndexPath *)sourceIndexPath toAdjustedIndexPath:(NSIndexPath *)destIndexPath;

- (Section *)sectionAtIndex:(NSInteger)arg1;
- (Album *)albumWithIdentifier:(NSString *)arg1;
- (Album *)albumAtAdjustedIndexPath:(NSIndexPath *)arg1;
- (void)removeAlbumWithIdentifier:(NSString *)arg1;
- (NSInteger)numberOfSections;
- (NSInteger)numberOfAlbumsInSection:(NSInteger)arg1;
- (NSInteger)numberOfTotalAlbums;

@end