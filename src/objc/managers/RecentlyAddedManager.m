#import <UIKit/UIKit.h>
#import "RecentlyAddedManager.h"
#import "HBLog.h"
#import "../reflection/reflection.h"
#import "../utilities/utilities.h"

// should i synchronize access to the albums array with a mutex?

@implementation RecentlyAddedManager

// default initializer
- (instancetype)init {
    
    if ((self = [super init])) {

        _processedRealAlbumOrder = NO;
        _sections = [NSMutableArray array];

        // try to load saved albums on initialization?

        // adding two sections for now...
        [_sections addObject:[[Section alloc] initWithIdentifier:@"PINNED_SECTION" title:@"Pinned" subtitle:nil]];
        [_sections addObject:[[Section alloc] initWithIdentifier:@"RECENTLY_ADDED_SECTION" title:@"Recently Added" subtitle:nil]];
    }

    return self;
}

// convert an album's adjusted index path (which was injected into the collection view) to it's original index path
- (NSIndexPath *)translateIndexPath:(NSIndexPath *)arg1 {

    Section *section = _sections[arg1.section];
    Album *album = [section albumAtIndex:arg1.item];

    return [album realIndexPath];
}

// determine if data is ready to be injected
- (BOOL)isReadyForUse {
    return _processedRealAlbumOrder;
}

// return an array of Album objects in their real order
- (NSArray *)recreateRealAlbumOrder {

    NSInteger numberOfTotalAlbums = [self numberOfTotalAlbums];
    NSMutableArray *RealAlbumOrder = [NSMutableArray arrayWithCapacity:numberOfTotalAlbums];

    // fill the array with null values
    for (int i = 0; i < numberOfTotalAlbums; i++) {
        [RealAlbumOrder addObject:[NSNull null]];
    }

    // insert every album into the array at its real index
    for (Section *section in _sections) {
        for (Album *album in section.albums) {
            RealAlbumOrder[album.realIndex] = album;
        }
    }

    return RealAlbumOrder;
}

// process the real / original order of albums so they can be mapped to new positions
- (void)processRealAlbumOrder:(NSArray *)realAlbumOrder {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"RecentlyAddedManager: %p - processRealAlbumOrder:(%p)", self, realAlbumOrder]];

    NSArray *recreatedAlbumOrder = [self recreateRealAlbumOrder];

    // create arrays of just the ids of each of the albums
    NSMutableArray *recreatedAlbumIdentOrder = [NSMutableArray array];
    NSMutableArray *realAlbumIdentOrder = [NSMutableArray array];
    
    for (Album *album in recreatedAlbumOrder) {
        // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"orig order album: %@", album]];
        [recreatedAlbumIdentOrder addObject:album.identifier];
    }

    for (Album *album in realAlbumOrder) {
        // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"new order album: %@", album]];
        [realAlbumIdentOrder addObject:album.identifier];
    }

    // process the new order if it has changed
    if (![realAlbumIdentOrder isEqualToArray:recreatedAlbumIdentOrder]) {
        _processedRealAlbumOrder = NO;

        // remove any album that is not in the real order
        for (NSString *albumID in recreatedAlbumIdentOrder) {

            if (![realAlbumIdentOrder containsObject:albumID]) {
                [[Logger sharedInstance] logString:[NSString stringWithFormat:@"found album to be removed: %@", albumID]];
                [self removeAlbumWithIdentifier:albumID];
            }
        }

        Section *recentSection = [self recentSection];
        // int count = 0;

        // check every album in the new album order
        for (Album *album in realAlbumOrder) {
            
            // add any new albums to the recently added section
            if (![recreatedAlbumIdentOrder containsObject:album.identifier]) {
                [[Logger sharedInstance] logString:[NSString stringWithFormat:@"add new album to recent section: %@", [album identifier]]];

                [recentSection addAlbum:album];
            }

            // update any existing album information that might have changed
            Album *originalAlbum = [self albumWithIdentifier:album.identifier];
            originalAlbum.artist = album.artist;
            originalAlbum.title = album.title;
            originalAlbum.realIndex = album.realIndex;
        }
    }

    _processedRealAlbumOrder = YES;

    // save data here??
}

// return YES if an album at a given index path is able to be shifted left/right
- (BOOL)canShiftAlbumAtAdjustedIndexPath:(NSIndexPath *)arg1 movingLeft:(BOOL)isMovingLeft {
    [[Logger sharedInstance] logStringWithFormat:@"%@RecentlyAddedManager: %@ - canShiftAlbumAtAdjustedIndexPath:<%ld-%ld>", self, arg1.section, arg1.item];
    
    // only allow the album to be shifted if it is not in the recently added section
    Section *recentSection = [self recentSection];
    Section *targetSection = [self sectionAtIndex:arg1.section];

    if (targetSection == recentSection) {
        return NO;
    }

    NSInteger numAlbumsInSection = [self numberOfAlbumsInSection:arg1.section];

    // check if there are no other albums to shift with
    if ([self numberOfTotalAlbums] <= 1) {
        return NO;
    }

    // check if target album is at the leftmost/rightmost edge of the section
    if ((isMovingLeft && arg1.item == 0) || (!isMovingLeft && arg1.item == numAlbumsInSection - 1)) {
        return NO;
    }

    return YES;
}

// move the album at the given source index path to the given destination index path
- (void)moveAlbumAtAdjustedIndexPath:(NSIndexPath *)sourceIndexPath toAdjustedIndexPath:(NSIndexPath *)destIndexPath {
    [[Logger sharedInstance] logStringWithFormat:@"RecentlyAddedManager: %@ - moveAlbumAtAdjustedIndexPath:%@ toAdjustedIndexPath:%@", self, sourceIndexPath, destIndexPath];

    Section *sourceSection = [self sectionAtIndex:sourceIndexPath.section];
    Section *destSection = [self sectionAtIndex:destIndexPath.section];

    Album *album = [sourceSection albumAtIndex:sourceIndexPath.item];

    [sourceSection removeAlbum:album];
    [destSection insertAlbum:album atIndex:destIndexPath.item];

    // [self checkSectionVisibility];
    // [self saveData];
}

// removes an album with the given identifier from its section
- (void)removeAlbumWithIdentifier:(NSString *)arg1 {

    for (Section *section in _sections) {        
        if ([section removeAlbumWithIdentifier:arg1]) {
            return;
        }
    }
}

// return the album object with the given id
- (Album *)albumWithIdentifier:(NSString *)arg1 {
    
    for (Section *section in _sections) {

        Album *album = [section albumWithIdentifier:arg1];
        if (album) {
            return album;
        }
    }

    return nil;
}

// return the album object at the given adjusted index path
- (Album *)albumAtAdjustedIndexPath:(NSIndexPath *)arg1 {
    Section *section = [self sectionAtIndex:arg1.section];
    return [section albumAtIndex:arg1.item];
}

// return the section at the given index
- (Section *)sectionAtIndex:(NSInteger)arg1 {
    return _sections[arg1];
}

// return the total number of albums 
- (NSInteger)numberOfTotalAlbums {
    
    NSInteger totalAlbums = 0;
    for (Section *section in _sections) {
        totalAlbums += [section numberOfAlbums];
    }

    return totalAlbums;
}

// return the recent section object
- (Section *)recentSection {
    return _sections[[_sections count] - 1];
}

// return the total number of sections
- (NSInteger)numberOfSections {
    return [_sections count];
}

// return the number of albums in a given section
- (NSInteger)numberOfAlbumsInSection:(NSInteger)arg1 {
    return [_sections[arg1] numberOfAlbums];
}

@end