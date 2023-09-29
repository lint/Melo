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

        [Logger logStringWithFormat:@"RecentlyAddedManager: %p - init", self];

        _defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.lint.melo.data"];
        _skipLoad = NO;

        _isReadyForUse = NO;

        _attemptedDataLoad = NO;
        _isDownloadedMusic = NO;

        _processedRealAlbumOrder = NO;
        _sections = [NSMutableArray array];

        _albumMap = [NSMutableDictionary dictionary];
        _albumIdentOrder = [NSArray array];

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
    // Album *album = _sections[arg1.section].albums[arg1.item];
    return [album realIndexPath];
}

// determine if data is ready to be injected
- (void)updateIsReadyForUse {

    if (_isDownloadedMusic && !_prefsDownloadedMusicEnabled) {
        _isReadyForUse = NO;
        return;
    }

    _isReadyForUse = _processedRealAlbumOrder && _attemptedDataLoad;
}

// process the real / original order of albums so they can be mapped to new positions
- (void)processRealAlbumOrder:(NSArray *)nextAlbumIdentOrder {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"RecentlyAddedManager: %p - processRealAlbumOrder:(%p)", self, nextAlbumIdentOrder]];

    NSArray *lastAlbumIdentOrder = [self albumIdentOrder];

    // check if the new real album id order is different than the last album id order
    if (![nextAlbumIdentOrder isEqualToArray:lastAlbumIdentOrder]) {
        [[Logger sharedInstance] logString:@"order changed, will process"];

        _processedRealAlbumOrder = NO;
        _albumIdentOrder = nextAlbumIdentOrder;
        Section *recentSection = [self recentSection];

        NSMutableDictionary *diff = [NSMutableDictionary dictionary];

        // add any previously saved album ids to the diff map
        for (NSString *ident in lastAlbumIdentOrder) {
            NSMutableDictionary *entry = [NSMutableDictionary dictionary];
            entry[@"inLast"] = @YES;
            entry[@"inNext"] = @NO;
            diff[ident] = entry;
        }

        NSInteger newAlbumInsertionIndex = 0;

        // update diff map for album ids in the next album id order
        for (NSInteger i = 0; i < [nextAlbumIdentOrder count]; i++) {
            
            NSString *ident = nextAlbumIdentOrder[i];
            NSMutableDictionary *entry = diff[ident];

            if (!entry) {
                entry = [NSMutableDictionary dictionary];
                entry[@"inLast"] = @NO;
                diff[ident] = entry;

                // create a new album object and insert it into the recent section
                Album *album = [Album new];
                album.identifier = ident;
                _albumMap[ident] = album;
                [recentSection insertAlbum:album atIndex:newAlbumInsertionIndex++];
            }

            entry[@"inNext"] = @YES;
            entry[@"realIndex"] = @(i);
        }

        // iterate over the changes to the real album id order
        for (NSString *ident in diff) {
            NSMutableDictionary *entry = diff[ident];
            Album *album = _albumMap[ident];
            
            // remove any albums that no longer appear in the order
            if ([entry[@"inLast"] boolValue] && ![entry[@"inNext"] boolValue]) {
                [album.section removeAlbum:album];
                [_albumMap removeObjectForKey:ident];
            
            // update the real index of any album that will be displayed
            } else {
                album.realIndex = [entry[@"realIndex"] integerValue];
            }
        }
    }

    _processedRealAlbumOrder = YES;
    [self updateIsReadyForUse];
}

// return YES if an album at a given index path is able to be shifted left/right
- (BOOL)canShiftAlbumAtAdjustedIndexPath:(NSIndexPath *)arg1 movingLeft:(BOOL)isMovingLeft {
    [[Logger sharedInstance] logStringWithFormat:@"RecentlyAddedManager: %@ - canShiftAlbumAtAdjustedIndexPath:<%ld-%ld>", self, arg1.section, arg1.item];
    
    Album *album = [self albumAtAdjustedIndexPath:arg1];

    if ([album isFakeAlbum]) {
        return NO;
    }
    
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
    _albumMap = [NSMutableDictionary dictionary];

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
        // create section object for every loaded dictionary
        for (NSInteger i = 0; i < [data count]; i++) {
            Section *section = [[Section alloc] initWithDictionary:data[i]];
            [defaultsSections addObject:section];
        }
    }
    // [[Logger sharedInstance] logStringWithFormat:@"data: %@", data];

    // custom sections are enabled - sync custom sections from prefs and user defaults
    if ([meloManager prefsBoolForKey:@"customSectionsEnabled"]) {

        // [[Logger sharedInstance] logString:@"custom sections are enabled"];

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

        // [[Logger sharedInstance] logString:@"custom sections are disabled"];

        // // create section and album objects
        // if (data) {

        //     // create section object for every loaded dictionary
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

    NSMutableArray *unorderedAlbumIds = [NSMutableArray array];

    for (Section *section in _sections) {
        // TODO: why did i comment this out?
        // remove any fake albums that might've been accidentally saved
        // [section removeAlbumWithIdentifier:@"MELO_ALBUM_WIGGLE_MODE_INSERTION"];
        
        // add all albums to the album map
        for (Album *album in section.albums) {
            _albumMap[album.identifier] = album;
            [unorderedAlbumIds addObject:album.identifier];
        }
    }

    _albumIdentOrder = unorderedAlbumIds;

    _attemptedDataLoad = YES;
    [self updateIsReadyForUse];

    [[Logger sharedInstance] logString:@"done data load"];
}

// adds or removes a fake insertion album in every section for wiggle mode
- (void)updateFakeInsertionAlbums:(BOOL)shouldAdd {

    for (Section *section in _sections) {
        if (shouldAdd) {
            [section addAlbum:[Album createFakeAlbum]];
        } else {
            [section removeAlbumWithIdentifier:@"MELO_ALBUM_WIGGLE_MODE_INSERTION"];
        }
    }
}

// determines if a context menu should be allowed based on the downloaded music settings
- (BOOL)shouldAllowDownloadedMusicContextMenu {

    MeloManager *meloManager = [MeloManager sharedInstance];

    // do not allow if this is downloaded music and pinning is disabled or if it's enabled and syncinging pins is enabled
    return !self.isDownloadedMusic || ([meloManager prefsBoolForKey:@"downloadedPinningEnabled"] && ![meloManager prefsBoolForKey:@"syncLibraryPinsEnabled"]);
}

@end