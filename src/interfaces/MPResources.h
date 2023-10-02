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

@interface MPModelStoreBrowseContentItem : MPModelObject
@property(assign, nonatomic) NSUInteger itemType;
@property(assign, nonatomic) NSInteger detailedItemType;
@property(strong, nonatomic) MPModelAlbum *album;
@property(strong, nonatomic) MPModelPlaylist *playlist;
@end

@interface MusicModelGridItem : MPModelObject
@property(strong, nonatomic) MPModelStoreBrowseContentItem *contentItem;
@end

@interface MPSectionedCollection : NSObject
@property(strong, nonatomic) id firstItem;
- (NSArray *)allItems;
- (NSInteger)numberOfSections;
@end

@interface MPMediaLibraryConnectionAssertation : NSObject
@property(strong, nonatomic) NSString *identifier;
@end

@interface MPModelResponse : NSObject
@property(strong, nonatomic) MPSectionedCollection *results;
@end

@interface MPModelLibraryResponse : MPModelResponse
@property(strong, nonatomic) MPMediaLibraryConnectionAssertation *libraryAssertion;
@end

@interface MPUFontDescriptor : NSObject
@property(strong, nonatomic) UIFont *defaultFont;
@property(strong, nonatomic) UIFont *preferredFont;
@property(assign, nonatomic) CGFloat preferredFontLineHeight;
@property(assign, nonatomic) CGFloat preferredFontAscender;
+ (id)fontDescriptorWithSystemFontSize:(CGFloat)arg1;
+ (id)fontDescriptorWithTextStyle:(NSInteger)arg1;

// custom elements
@property(assign, nonatomic) BOOL shouldOverrideLeading;
@property(assign, nonatomic) CGFloat overrideLeadingValue;
@property(assign, nonatomic) BOOL test;
@end

@interface MPUMutableFontDescriptor : MPUFontDescriptor
- (void)setWeight:(NSInteger)arg1;
- (void)setTextStyle:(NSInteger)arg1;
- (void)setSystemFontSize:(CGFloat)arg1;
- (void)setDefaultPointSizeAdjustment:(CGFloat)arg1;
- (void)setUsesItalic:(BOOL)arg1;
- (void)setLeadingAdjustment:(NSInteger)arg1;
- (void)setWantsMonospaceNumbers:(BOOL)arg1;
@end

@interface MPVolumeSlider : UISlider
@property(strong, nonatomic) UIView *thumbView;
@end