
#import "Album.h"

@implementation Album

// default initializer
- (instancetype)init {

    self = [super init];

    if (self) {
        _realIndex = -1;
    }

    return self;
}

// initialize with values from a dictionary
- (instancetype)initWithDictionary:(NSDictionary *)arg1 {

    self = [super init];

    if (self) {
        _identifier = arg1[@"identifier"];
        _artist = arg1[@"artist"];
        _title = arg1[@"title"];
        _realIndex = arg1[@"realIndex"] ? [arg1[@"realIndex"] integerValue] : -1;
    }

    return self;
}

// return this album's real index path
- (NSIndexPath *)realIndexPath {
    NSInteger item = [self isFakeAlbum] ? 0 : _realIndex;
    return [NSIndexPath indexPathForItem:item inSection:0];
}

// convert this album into a dictionary
- (NSDictionary *)toDictionary {
    return @{
        @"identifier" : _identifier ?: @"",
        @"artist" : _artist ?: @"",
        @"title" : _title ?: @"",
        @"realIndex" : @(_realIndex),
    };
}

// create a copy of this album object
- (Album *)copy {
    NSDictionary *dataDict = [self toDictionary];
    Album *album = [[Album alloc] initWithDictionary:dataDict];
    return album;
}

// check if this album is equal to another object
- (BOOL)isEqual:(id)arg1 {

    if (![arg1 isKindOfClass:[Album class]]) {
        return NO;
    }

    return [_identifier isEqualToString:[arg1 identifier]] && 
        [_artist isEqualToString:[arg1 artist]] &&
        [_title isEqualToString:[arg1 title]] &&
        _realIndex == [arg1 realIndex];
}

// checks if this album is a fake album injected for use in wiggle mode
- (BOOL)isFakeAlbum {
    return [@"MELO_ALBUM_WIGGLE_MODE_INSERTION" isEqualToString:_identifier];
}

// creates a new album object to be injected for use in wiggle mode
+ (Album *)createFakeAlbum {
    NSDictionary *info = @{
        @"identifier": @"MELO_ALBUM_WIGGLE_MODE_INSERTION"
    };
    return [[Album alloc] initWithDictionary:info];
}

@end
