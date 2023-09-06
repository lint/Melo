
#import "Section.h"
#import "Album.h"
#import "../utilities/utilities.h"

@implementation Section

// default initializer
- (instancetype)init {

    self = [super init];

    if (self) {
        _albums = [NSMutableArray array];
        _visible = YES;
        _collapsed = NO;
    }

    return self;
}

// initialize with values from a dictionary
- (instancetype)initWithDictionary:(NSDictionary *)arg1 {

    self = [super init];

    [[Logger sharedInstance] logStringWithFormat:@"Section: %p - initWithDictionary: %@", self, arg1];

    if (self) {
        _identifier = arg1[@"identifier"];
        _title = arg1[@"title"];
        _subtitle = arg1[@"subtitle"];
        _visible = arg1[@"visible"] ? [arg1[@"visible"] boolValue] : YES;
        _collapsed = arg1[@"collapsed"] ? [arg1[@"collapsed"] boolValue] : NO;

        _albums = [NSMutableArray array];

        for (NSDictionary *albumDict in arg1[@"albums"]) {
            Album *album = [[Album alloc] initWithDictionary:albumDict];
            [[Logger sharedInstance] logStringWithFormat:@"adding album%@", arg1];
            [_albums addObject:album];
        }
    }

    return self;
}

// initialize with values provided through arguments
- (instancetype)initWithIdentifier:(NSString *)arg1 title:(NSString *)arg2 subtitle:(NSString *)arg3 {

    self = [super init];

    if (self) {
        _identifier = arg1;
        _title = arg2;
        _subtitle = arg3;

        _albums = [NSMutableArray array];
        _visible = YES;
        _collapsed = NO;
    }

    return self;
}

// returns the number of albums in the section
- (NSInteger)numberOfAlbums {
    return [_albums count];
}

// returns a given album's index in the section
- (NSInteger)indexOfAlbum:(Album *)arg1 {
    return [_albums indexOfObject:arg1];
}

// returns the album at a given index in the section
- (Album *)albumAtIndex:(NSInteger)arg1 {
    return _albums[arg1];
}

// returns the album with the given identifier in the section
- (Album *)albumWithIdentifier:(NSString *)arg1 {
    
    for (Album *album in _albums) {
        if ([album.identifier isEqualToString:arg1]) {
            return album;
        }
    }

    return nil;
}

// removes a given album from the section
- (void)removeAlbum:(Album *)arg1 {
    [_albums removeObject:arg1];
}

// removes the album at the given index from the section
- (void)removeAlbumAtIndex:(NSInteger)arg1 {
    [_albums removeObjectAtIndex:arg1];
}

// removes the album with the given identifier from the section (returns YES if successful)
- (BOOL)removeAlbumWithIdentifier:(NSString *)arg1 {

    for (NSInteger i = 0; i < [self numberOfAlbums]; i++) {
        if ([_albums[i].identifier isEqualToString:arg1]) {
            [self removeAlbumAtIndex:i];
            return YES;
        }
    }

    return NO;
}

// removes all albums in the section
- (void)removeAllAlbums {
    _albums = [NSMutableArray array];
}

// add a given album to the end of the section
- (void)addAlbum:(Album *)arg1 {
    [_albums addObject:arg1];
}

// add a given album to a given index in the section
- (void)insertAlbum:(Album *)arg1 atIndex:(NSInteger)arg2 {
    [_albums insertObject:arg1 atIndex:arg2];
}

// swap the position of two albums in the section
- (void)swapAlbumAtIndex:(NSInteger)arg1 withAlbumAtIndex:(NSInteger)arg2 {
    [_albums exchangeObjectAtIndex:arg1 withObjectAtIndex:arg2];
}

// move an album at a given index to another index in the section
- (void)moveAlbumAtIndex:(NSInteger)arg1 toIndex:(NSInteger)arg2 {
    Album *album = [self albumAtIndex:arg1];
    [self removeAlbumAtIndex:arg1];
    [self insertAlbum:album atIndex:arg2];
}

// return YES if the section does not contain any albums
- (BOOL)isEmpty {
    return [_albums count] == 0;
}

// returns a copy of the section
- (Section *)copy {
    NSDictionary *data = [self toDictionary];
    Section *section = [[Section alloc] initWithDictionary:data];
    return section;
}

// convert the section's values to a dictionary
- (NSDictionary *)toDictionary {

    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:@{
        @"identifier" : _identifier ?: @"",
        @"title" : _title ?: @"",
        @"subtitle" : _subtitle ?: @"",
        @"visible" : @(_visible),
        @"collapsed" : @(_collapsed),
    }];

    NSMutableArray *albums = [NSMutableArray array];

    for (Album *album in _albums) {
        [albums addObject:[album toDictionary]];
    }

    data[@"albums"] = albums;

    return data;
}

// creates a section with no albums for the recently added section
+ (instancetype)emptyRecentSection {
    return [[Section alloc] initWithIdentifier:@"MELO_RECENTLY_ADDED_SECTION" title:@"Recently Added" subtitle:nil];
}

// creates a "pinned" section with no albums
+ (instancetype)emptyPinnedSection {
    return [[Section alloc] initWithIdentifier:@"MELO_PINNED_SECTION" title:@"Pinned" subtitle:nil];
}

@end
