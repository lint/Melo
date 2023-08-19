
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
    return [NSIndexPath indexPathForItem:_realIndex inSection:0];
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

@end
