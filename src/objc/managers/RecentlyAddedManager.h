
#import <UIKit/UIKit.h>

// forward declarations
@class Album, Section;

// manager class to inject album/section data for each LibraryRecentlyAddedViewController 
@interface RecentlyAddedManager : NSObject
@property(strong, nonatomic) NSMutableArray *sections;
@property(assign, nonatomic) BOOL processedRealAlbumOrder;
@property(strong, nonatomic) NSUserDefaults *defaults;
@property(assign, nonatomic) BOOL attemptedDataLoad;
@property(assign, nonatomic) BOOL isDownloadedMusic;
@property(assign, nonatomic) BOOL skipLoad;
@property(assign, nonatomic) BOOL unhandledDataChangeOccurred;
@property(assign, nonatomic) BOOL isReadyForUse;
@property(assign, nonatomic) BOOL prefsDownloadedMusicEnabled;
// @property(strong, nonatomic) NSLock 

- (instancetype)init;
- (NSIndexPath *)translateIndexPath:(NSIndexPath *)arg1;
- (NSArray *)recreateRealAlbumOrder;
- (void)processRealAlbumOrder:(NSArray *)arg1;
- (void)updateIsReadyForUse;

- (BOOL)canShiftAlbumAtAdjustedIndexPath:(NSIndexPath *)arg1 movingLeft:(BOOL)arg2;
- (void)moveAlbumAtAdjustedIndexPath:(NSIndexPath *)sourceIndexPath toAdjustedIndexPath:(NSIndexPath *)destIndexPath;

- (Section *)sectionAtIndex:(NSInteger)arg1;
- (Section *)sectionWithIdentifier:(NSString *)arg1;
- (Album *)albumWithIdentifier:(NSString *)arg1;
- (Album *)albumAtAdjustedIndexPath:(NSIndexPath *)arg1;
- (NSArray *)pinnedAlbums;
- (void)removeAlbumWithIdentifier:(NSString *)arg1;
- (NSInteger)numberOfSections;
- (NSInteger)numberOfAlbumsInSection:(NSInteger)arg1;
- (NSInteger)numberOfTotalAlbums;
- (NSInteger)sectionIndexForIdentifier:(NSString *)arg1; // TODO: rename this to indexForSectionWithIdentifier?
- (NSString *)userDefaultsKey;
- (void)saveData;
- (void)loadData;
- (void)updateFakeInsertionAlbums:(BOOL)shouldAdd;
- (BOOL)shouldAllowDownloadedMusicContextMenu;
@end