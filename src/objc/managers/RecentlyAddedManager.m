#import <UIKit/UIKit.h>
#import "RecentlyAddedManager.h"
#import "HBLog.h"
#import "../reflection/reflection.h"
#import "../utilities/utilities.h"
#import "MeloManager.h"

// should i synchronize access to the albums array with a mutex?

@implementation RecentlyAddedManager

// default initializer
- (instancetype)init {
    
    if ((self = [super init])) {

        _defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.lint.melo.data"];
        _skipLoad = NO;

        _attemptedDataLoad = NO;
        _isDownloadedMusic = NO;

        _processedRealAlbumOrder = NO;
        _sections = [NSMutableArray array];

        // adding two sections for now...
        [_sections addObject:[Section emptyPinnedSection]];
        [_sections addObject:[Section emptyRecentSection]];

        [[MeloManager sharedInstance] addRecentlyAddedManager:self];

        _prefsDownloadedMusicEnabled = [[MeloManager sharedInstance] prefsBoolForKey:@"downloadedPinningEnabled"];

        // [self loadData];
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

    if (_isDownloadedMusic && !_prefsDownloadedMusicEnabled) {
        return NO;
    }

    return _processedRealAlbumOrder && _attemptedDataLoad;
    // return _processedRealAlbumOrder;
}

// return an array of Album objects in their real order
- (NSArray *)recreateRealAlbumOrder {
    [[Logger sharedInstance] logStringWithFormat:@"RecentlyAddedManager:%p - recreateAlbumOrder", self];

    NSInteger numberOfTotalAlbums = [self numberOfTotalAlbums];
    [[Logger sharedInstance] logStringWithFormat:@"numberOfTotalAlbums: %li", numberOfTotalAlbums];
    NSMutableArray *realAlbumOrder = [NSMutableArray arrayWithCapacity:numberOfTotalAlbums];

    // albums will not be inserted properly if attempting to recreate the original order before data has been processed 
    if (_processedRealAlbumOrder) {
        [[Logger sharedInstance] logString:@"has previously processed real album order, recreating it..."];
        
        // fill the array with null values
        for (int i = 0; i < numberOfTotalAlbums; i++) {
            [realAlbumOrder addObject:[NSNull null]];
        }

        // insert every album into the array at its real index
        for (Section *section in _sections) {

            [[Logger sharedInstance] logStringWithFormat:@"inserting albums from section: %@ to real order", section];

            for (Album *album in section.albums) {
                [[Logger sharedInstance] logStringWithFormat:@"inserting album: %@", album];
                realAlbumOrder[album.realIndex] = album;
            }
        }
    } else {
        [[Logger sharedInstance] logString:@"has NOT previously processed real album order, just adding albums to array"];

        // insert every album into the array
        for (Section *section in _sections) {

            [[Logger sharedInstance] logStringWithFormat:@"inserting albums from section: %@ to real order", section];

            for (Album *album in section.albums) {
                [[Logger sharedInstance] logStringWithFormat:@"inserting album: %@", album];
                [realAlbumOrder addObject:album];
            }
        }
    }

    return realAlbumOrder;
}

// process the real / original order of albums so they can be mapped to new positions
- (void)processRealAlbumOrder:(NSArray *)realAlbumOrder {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"RecentlyAddedManager: %p - processRealAlbumOrder:(%p)", self, realAlbumOrder]];

    NSArray *recreatedAlbumOrder = [self recreateRealAlbumOrder];

    // create arrays of just the ids of each of the albums
    NSMutableArray *recreatedAlbumIdentOrder = [NSMutableArray array];
    NSMutableArray *realAlbumIdentOrder = [NSMutableArray array];

    [[Logger sharedInstance] logString:@"here pre array compare"];
    
    for (Album *album in recreatedAlbumOrder) {
        [[Logger sharedInstance] logString:[NSString stringWithFormat:@"orig order album: %@", album]];
        [recreatedAlbumIdentOrder addObject:album.identifier];
    }

    for (Album *album in realAlbumOrder) {
        [[Logger sharedInstance] logString:[NSString stringWithFormat:@"new order album: %@", album]];
        [realAlbumIdentOrder addObject:album.identifier];
    }

    [[Logger sharedInstance] logString:@"here post array compare"];

    // process the new order if it has changed
    if (![realAlbumIdentOrder isEqualToArray:recreatedAlbumIdentOrder]) {
        _processedRealAlbumOrder = NO;

        [[Logger sharedInstance] logString:@"order changed, will process"];

        // remove any album that is not in the real order
        for (NSString *albumID in recreatedAlbumIdentOrder) {

            if (![realAlbumIdentOrder containsObject:albumID]) {
                [[Logger sharedInstance] logString:[NSString stringWithFormat:@"found album to be removed: %@", albumID]];
                [self removeAlbumWithIdentifier:albumID];
            }
        }
        // [[Logger sharedInstance] logStringWithFormat:@"%ld", [_sections count]];

        // remove all non pinned albums 
        Section *recentSection = [self recentSection];
        [recentSection removeAllAlbums];

        NSArray *pinnedAlbums = [self pinnedAlbums];
        int count = 0;

        for (Album *album in realAlbumOrder) {

            BOOL foundMatch = NO;
            
            // see if the given album is a pinned album
            for (Album *pinnedAlbum in pinnedAlbums) {
                if ([album.identifier isEqualToString:pinnedAlbum.identifier]) {

                    [[Logger sharedInstance] logStringWithFormat:@"matched album in pinned section, album ident: %@", [album identifier]];

                    // update the pinned album object
                    pinnedAlbum.artist = album.artist;
                    pinnedAlbum.title = album.title;
                    pinnedAlbum.realIndex = album.realIndex;

                    foundMatch = YES;
                    break;
                }
            }

            // add any non pinned album to the recent section in the real order
            if (!foundMatch) {
                [[Logger sharedInstance] logStringWithFormat:@"adding album to recently added section, album ident: %@", [album identifier]];
                [recentSection addAlbum:album];
            }
        }

        // check every album in the new album order
        // for (Album *album in realAlbumOrder) {
            
        //     // add any new albums to the recently added section
        //     if (![recreatedAlbumIdentOrder containsObject:album.identifier]) {
        //         [[Logger sharedInstance] logString:[NSString stringWithFormat:@"add new album to recent section: %@", [album identifier]]];

                
        //         // [_sections[0] addAlbum:album];
        //         // if (count++ == 0 || count == 6) {
        //         //     [_sections[0] addAlbum:album];
        //         // } else {
        //             [recentSection addAlbum:album];
        //         // }
        //     }

        //     // update any existing album information that might have changed
        //     Album *originalAlbum = [self albumWithIdentifier:album.identifier];
        //     originalAlbum.artist = album.artist;
        //     originalAlbum.title = album.title;
        //     originalAlbum.realIndex = album.realIndex;
        // }
    }

    _processedRealAlbumOrder = YES;

    // save data here??
    if (_attemptedDataLoad) {
        [self saveData];
    }
}

// return YES if an album at a given index path is able to be shifted left/right
- (BOOL)canShiftAlbumAtAdjustedIndexPath:(NSIndexPath *)arg1 movingLeft:(BOOL)isMovingLeft {
    [[Logger sharedInstance] logStringWithFormat:@"RecentlyAddedManager: %@ - canShiftAlbumAtAdjustedIndexPath:<%ld-%ld>", self, arg1.section, arg1.item];
    
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
    [self saveData];

    [[MeloManager sharedInstance] dataChangeOccurred:self];
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

// returns an array of all pinned albums
- (NSArray *)pinnedAlbums {

    NSMutableArray *albums = [NSMutableArray array];

    // iterate over every section except for the recent section (last in the array)
    for (NSInteger i = 0; i < [self numberOfSections] - 1; i++) {
        Section *section = [self sectionAtIndex:i];

        albums = [albums arrayByAddingObjectsFromArray:[section albums]];
    }

    return albums;
}

// return the section at the given index
- (Section *)sectionAtIndex:(NSInteger)arg1 {
    return _sections[arg1];
}

// return the total number of albums 
- (NSInteger)numberOfTotalAlbums {
    [[Logger sharedInstance] logStringWithFormat:@"RecentlyAddedManager: %p - numberOfTotalAlbums", self];
    
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

// returns the index of a section that matches the given identifier
- (NSInteger)sectionIndexForIdentifier:(NSString *)arg1 {

    [[Logger sharedInstance] logStringWithFormat:@"RecentlyAddedManager sectionIndexForIdentifier:%@", arg1];
    
    for (int i = 0; i < [self numberOfSections]; i++) {

        if ([[_sections[i] identifier] isEqualToString:arg1]) {
            return i;
        }
    }

    return -1;
}


// returns the data key to load from user defaults
- (NSString *)userDefaultsKey {

    if (_isDownloadedMusic) {
        return @"MELO_DATA_DOWNLOADED";
    } else {
        return @"MELO_DATA_LIBRARY";
    }
}

// save the current section data to user defaults
- (void)saveData {
    [[Logger sharedInstance] logStringWithFormat:@"RecentlyAddedManager: %p - saveData", self];
    [[Logger sharedInstance] logStringWithFormat:@"user defaults key: %@", [self userDefaultsKey]];

    NSMutableArray *data = [NSMutableArray array];

    // iterate over every section except the recent section
    for (int i = 0; i < [self numberOfSections] - 1; i++) {
        Section *section = _sections[i];
        [data addObject:[section toDictionary]];
        [[Logger sharedInstance] logStringWithFormat:@"section: %@", [section toDictionary]];
    }

    [_defaults setObject:data forKey:[self userDefaultsKey]];
}

// load section data from user defaults
- (void)loadData {
    [[Logger sharedInstance] logStringWithFormat:@"RecentlyAddedManager: %p - loadData", self];
    [[Logger sharedInstance] logStringWithFormat:@"user defaults key: %@", [self userDefaultsKey]];

    // clear any current data
    if (!_skipLoad) {

        _sections = [NSMutableArray array];
        _processedRealAlbumOrder = NO;

        NSString *userDefaultsKey = [self userDefaultsKey];

        if ([[MeloManager sharedInstance] prefsBoolForKey:@"syncLibraryPinsEnabled"]) {
            userDefaultsKey = @"MELO_DATA_LIBRARY";
        }

        // load the data from user defaults
        NSMutableArray *data = [_defaults objectForKey:userDefaultsKey];

        [[Logger sharedInstance] logStringWithFormat:@"data: %@", data];

        // create section and album objects
        if (data) {

            // create section object for every loaded dictioanry
            for (int i = 0; i < [data count]; i++) {
                Section *section = [[Section alloc] initWithDictionary:data[i]];
                [_sections addObject:section];
            }

            // create empty recent section
            Section *recentSection = [Section emptyRecentSection];
            [_sections addObject:recentSection];
        } else {

            // adding two sections for now...
            [_sections addObject:[Section emptyPinnedSection]];
            [_sections addObject:[Section emptyRecentSection]];
        }
    }

    _attemptedDataLoad = YES;
}

@end