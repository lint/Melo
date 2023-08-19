#import <UIKit/UIKit.h>

@interface MPIdentifierSet : NSObject
@property(assign, nonatomic) NSInteger persistentID;
@end

@interface MPModelObject : NSObject
@property(strong, nonatomic) MPIdentifierSet *identifiers;
@property(strong, nonatomic) MPIdentifierSet *originalIdentifierSet;
@end

@interface MPModelPerson : MPModelObject
@property(strong, nonatomic) NSString *name;
@end

@interface MPModelArtist : MPModelPerson
@end

@interface MPModelCurator : MPModelPerson
@end

@interface MPModelAlbum : MPModelObject
@property(strong, nonatomic) NSString *title;
@property(strong, nonatomic) MPModelArtist *artist;
@end

@interface MPModelPlaylist : MPModelObject
@property(strong, nonatomic) NSString *name;
@property(strong, nonatomic) MPModelCurator *curator;
@end

@interface MPModelGenericObject : MPModelObject
@property(strong, nonatomic) MPModelAlbum *album;
@property(strong, nonatomic) MPModelPlaylist *playlist;
@end

@interface MPSectionedCollection : NSObject
- (NSArray *)allItems;
@end

@interface MPModelResponse : NSObject
@property(strong, nonatomic) MPSectionedCollection *results;
@end