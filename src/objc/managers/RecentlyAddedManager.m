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

            // [[Logger sharedInstance] logStringWithFormat:@"inserting albums from section: %@ to real order", section];

            for (Album *album in section.albums) {
                // [[Logger sharedInstance] logStringWithFormat:@"inserting album: %@", album];
                realAlbumOrder[album.realIndex] = album;
            }
        }
    } else {
        [[Logger sharedInstance] logString:@"has NOT previously processed real album order, just adding albums to array"];

        // insert every album into the array
        for (Section *section in _sections) {

            // [[Logger sharedInstance] logStringWithFormat:@"inserting albums from section: %@ to real order", section];

            for (Album *album in section.albums) {
                // [[Logger sharedInstance] logStringWithFormat:@"inserting album: %@", album];
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

    // [[Logger sharedInstance] logString:@"here pre array compare"];
    
    for (Album *album in recreatedAlbumOrder) {
        // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"orig order album: %@", album]];
        [recreatedAlbumIdentOrder addObject:album.identifier];
    }

    for (Album *album in realAlbumOrder) {
        // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"new order album: %@", album]];
        [realAlbumIdentOrder addObject:album.identifier];
    }

    // [[Logger sharedInstance] logString:@"here post array compare"];

    // process the new order if it has changed
    if (![realAlbumIdentOrder isEqualToArray:recreatedAlbumIdentOrder]) {
        _processedRealAlbumOrder = NO;

        [[Logger sharedInstance] logString:@"order changed, will process"];

        // remove any album that is not in the real order
        for (NSString *albumID in recreatedAlbumIdentOrder) {

            if (![realAlbumIdentOrder containsObject:albumID]) {
                // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"found album to be removed: %@", albumID]];
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

                    // [[Logger sharedInstance] logStringWithFormat:@"matched album in pinned section, album ident: %@", [album identifier]];

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
                // [[Logger sharedInstance] logStringWithFormat:@"adding album to recently added section, album ident: %@", [album identifier]];
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

// return the section with the given identifier
- (Section *)sectionWithIdentifier:(NSString *)arg1 {
    
    for (Section *section in _sections) {
        if ([section.identifier isEqualToString:arg1]) {
            return section;
        }
    }

    return nil;
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

    NSString *key;

    if (_isDownloadedMusic) {
        key = @"MELO_DATA_DOWNLOADED";
    } else {
        key = @"MELO_DATA_LIBRARY";
    }

    if ([[MeloManager sharedInstance] prefsBoolForKey:@"customSectionsEnabled"]) {
        key = [key stringByAppendingString:@"_CUSTOM_SECTIONS"];
    }

    return key;
}

// save the current section data to user defaults
- (void)saveData {
    [[Logger sharedInstance] logStringWithFormat:@"RecentlyAddedManager: %p - saveData", self];
    [[Logger sharedInstance] logStringWithFormat:@"user defaults key: %@", [self userDefaultsKey]];

    NSMutableArray *data = [NSMutableArray array];
    NSInteger numberOfSections = [self numberOfSections];

    // iterate over every section
    for (NSInteger i = 0; i < numberOfSections ; i++) {
        Section *section = _sections[i];
        NSMutableDictionary *sectionDict = [NSMutableDictionary dictionaryWithDictionary:[section toDictionary]];

        // do not save the albums of the recently added section
        if (i == numberOfSections - 1) {
            sectionDict[@"albums"] = @[];
        }

        if (![[MeloManager sharedInstance] prefsBoolForKey:@"preserveCollapsedStateEnabled"]) {
            sectionDict[@"collapsed"] = @NO;
        }

        [data addObject:sectionDict];

        // [[Logger sharedInstance] logStringWithFormat:@"section: %@", [section toDictionary]];
    }

    [_defaults setObject:data forKey:[self userDefaultsKey]];
}

// load section data from user defaults
- (void)loadData {
    [[Logger sharedInstance] logStringWithFormat:@"RecentlyAddedManager: %p - loadData", self];
    [[Logger sharedInstance] logStringWithFormat:@"user defaults key: %@", [self userDefaultsKey]];

    // clear any current data
    // if (!_skipLoad) {

    _sections = [NSMutableArray array];
    _processedRealAlbumOrder = NO;

    NSString *userDefaultsKey = [self userDefaultsKey];
    MeloManager *meloManager = [MeloManager sharedInstance];

    // NSBundle *bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] bundlePath], @"/Frameworks/MusicApplication.framework"]];
    // NSString *localizedRecentlyAddedTitle = NSLocalizedStringFromTableInBundle(@"RECENTLY_ADDED_VIEW_TITLE", @"Music", bundle, nil);

    if ([meloManager prefsBoolForKey:@"syncLibraryPinsEnabled"]) {
        userDefaultsKey = @"MELO_DATA_LIBRARY";

        if ([meloManager prefsBoolForKey:@"customSectionsEnabled"]) {
            userDefaultsKey = [userDefaultsKey stringByAppendingString:@"_CUSTOM_SECTIONS"];
        }
    }

    // load the data from user defaults
    NSMutableArray *data = [_defaults objectForKey:userDefaultsKey];

    // load custom section information from preferences
    NSArray *customSectionsInfoFromPrefs = [[MeloManager sharedInstance] prefsObjectForKey:@"customSectionsInfo"] ?: @[];
    NSDictionary *customRecentlyAddedInfoFromPrefs = [[MeloManager sharedInstance] prefsObjectForKey:@"customRecentlyAddedInfo"] ?: @{};

    NSMutableArray *finalSections = [NSMutableArray array];
    NSMutableArray *defaultsSections = [NSMutableArray array];

    // check if data was able to be loaded
    if (data) {
        // create section object for every loaded dictioanry
        for (NSInteger i = 0; i < [data count]; i++) {
            Section *section = [[Section alloc] initWithDictionary:data[i]];
            [defaultsSections addObject:section];
        }
    }
    [[Logger sharedInstance] logStringWithFormat:@"data: %@", data];

    // custom sections are enabled - sync custom sections from prefs and user defaults
    if ([meloManager prefsBoolForKey:@"customSectionsEnabled"]) {

        [[Logger sharedInstance] logString:@"custom sections are enabled"];

        // iterate over every custom section loaded from preferences
        for (NSInteger i = 0; i < [customSectionsInfoFromPrefs count]; i++) {

            NSDictionary *sectionInfo = customSectionsInfoFromPrefs[i];
            BOOL foundSection = NO;
            
            // iterate over every section loaded from defaults until a match is found
            for (Section *section in defaultsSections) {
                if ([section.identifier isEqualToString:sectionInfo[@"identifier"]]) {
                    section.title = sectionInfo[@"title"];
                    section.subtitle = sectionInfo[@"subtitle"];

                    [finalSections addObject:section];
                    foundSection = YES;
                    break;
                }
            }

            // no match found, meaning the section was not previously saved, create a new one
            if (!foundSection) {
                Section *section = [[Section alloc] initWithDictionary:sectionInfo];
                [finalSections addObject:section];
            }
        }

    // custom sections are disabled - check if a pinned section exists
    } else {

        [[Logger sharedInstance] logString:@"custom sections are disabled"];

        // // create section and album objects
        // if (data) {

        //     // create section object for every loaded dictioanry
        //     for (int i = 0; i < [data count]; i++) {
        //         Section *section = [[Section alloc] initWithDictionary:data[i]];
        //         [_sections addObject:section];
        //     }

        //     // create empty recent section
        //     Section *recentSection = [Section emptyRecentSection];
        //     [_sections addObject:recentSection];
        // } else {

        //     // adding two sections for now...
        //     [_sections addObject:[Section emptyPinnedSection]];
        //     [_sections addObject:[Section emptyRecentSection]];
        // }

        NSInteger numNonRecentSections = 0;

        for (Section *section in defaultsSections) {
            if (![@"MELO_RECENTLY_ADDED_SECTION" isEqualToString:section.identifier]) {
                numNonRecentSections++;
            }
        }

        if (numNonRecentSections == 0) {
            [finalSections addObject:[Section emptyPinnedSection]];
        } else {
            [finalSections addObjectsFromArray:defaultsSections];
        }
    }

    // get the section object for the recently added section
    Section *recentSection;

    // try to get the recently added section
    for (Section *section in defaultsSections) {
        if ([@"MELO_RECENTLY_ADDED_SECTION" isEqualToString:section.identifier]) {
            recentSection = section;
            break;
        }
    }

    // create new recently added section if it was not previously saved
    if (!recentSection) {
        recentSection = [Section emptyRecentSection];
    }

    // set custom title and subtitle for recently added section if enabled and found
    if ([meloManager prefsBoolForKey:@"customSectionsEnabled"] && 
        [meloManager prefsBoolForKey:@"renameRecentlyAddedSectionEnabled"] && customRecentlyAddedInfoFromPrefs) {
        
        recentSection.title = customRecentlyAddedInfoFromPrefs[@"title"];
        recentSection.subtitle = customRecentlyAddedInfoFromPrefs[@"subtitle"];
    } else {
        recentSection.title = nil;
        recentSection.subtitle = nil;
    }

    [finalSections addObject:recentSection];
    _sections = finalSections;

    // make sure all sections are not collapsed if it's disabled
    if (![meloManager prefsBoolForKey:@"collapsibleSectionsEnabled"] || ![meloManager prefsBoolForKey:@"preserveCollapsedStateEnabled"]) {
        for (Section *section in _sections) {
            section.collapsed = NO;
        }
    }
        
    // }

    // TODO: (remove this?)
    // first check if custom sections is enabled
    // if not, do what you did above
    // oooo how should I deal with saving and loading and switching between modes...
    // i think i want to save both
    // soo add another suffix to the user defaults key when custom sections is enabled
    // anyway, if custom sections is enabled, load the list of sections from the prefs
    // load the saved albums and sections from user defaults
    // remove any sections that do not appear in the prefs list and also reorder them to match prefs list
    // this can be done by iterating thru prefs list, and adding the saved album to the list 

    _attemptedDataLoad = YES;

    [[Logger sharedInstance] logString:@"done data load"];
}

@end