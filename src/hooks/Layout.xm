
#import <UIKit/UIKit.h>
#import "hooks.h"
#import "../objc/objc_classes.h"
#import "../interfaces/interfaces.h"

%group LayoutGroup

// doesn't work on iPad I suppose
// %hook UICollectionViewFlowLayout

// // changes the number of columns in UICollectionViews
// - (void)setItemSize:(CGSize)arg1 {

//     MeloManager *meloManager = [MeloManager sharedInstance];

//     // needed to check if the album layout is for certain classes
//     // id dataSource = [[self collectionView] dataSource];

//     // TODO: you can def condense this / just make it better, plus comments ofc

//     // if ([dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")]) {

//         CGSize size;

//         if ([meloManager prefsBoolForKey:@"customNumColumnsEnabled"]) {

//             NSInteger numColumns = [[meloManager prefsObjectForKey:@"customNumColumns"] integerValue];
//             NSInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;

//             float albumWidth = floor((screenWidth - 20 * 2 - [meloManager otherPagesCollectionViewCellSpacing] * (numColumns - 1)) / numColumns);
//             float albumHeight = (albumWidth * 1.5 - albumWidth) > 40 ? floor(albumWidth * 1.5) : albumWidth + 40;

//             size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(albumWidth, albumWidth) : CGSizeMake(albumWidth, albumHeight);
//         } else {
//             size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(arg1.width, arg1.width) : arg1;
//         }

//         %orig(size);
//     // } else if ([meloManager prefsBoolForKey:@"affectAlbumPagesEnabled"] && 
//     //     ([dataSource isKindOfClass:objc_getClass("MusicApplication.AlbumsViewController")] || 
//     //     [dataSource isKindOfClass:objc_getClass("MusicApplication.ArtistViewController")])) {

//     //     CGSize size;

//     //     if ([meloManager prefsBoolForKey:@"customNumColumnsEnabled"]) {

//     //         NSInteger numColumns = [[meloManager prefsObjectForKey:@"customNumColumns"] integerValue];
//     //         NSInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;

//     //         float albumWidth = floor((screenWidth - 20 * 2 - [meloManager otherPagesCollectionViewCellSpacing] * (numColumns - 1)) / numColumns);
//     //         float albumHeight = (albumWidth * 1.5 - albumWidth) > 40 ? floor(albumWidth * 1.5) : albumWidth + 40;

//     //         size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(albumWidth, albumWidth) : CGSizeMake(albumWidth, albumHeight); 
//     //     } else {
//     //         size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(arg1.width, arg1.width) : arg1;
//     //     }

//     //     %orig(size);

//     // } else {
//     //     %orig;
//     // }
// }

// %end

%hook AlbumCell

%new
- (void)setTextAndBadgeHidden:(BOOL)arg1 {

    UIView *textStackView = MSHookIvar<UIView *>(self, "textStackView");
    UIView *badgeView = MSHookIvar<UIView *>(self, "badgeView");

    if (textStackView) {
        [textStackView setHidden:arg1];
    }

    if (badgeView) {
        [badgeView setHidden:arg1];
    }
}

- (void)layoutSubviews {
    %orig;

    MeloManager *meloManager = [MeloManager sharedInstance];
    id dataSource = [[self _collectionView] dataSource];
    
    // BOOL shouldChangeCornerRadius = [meloManager prefsBoolForKey:@"customAlbumCellCornerRadiusEnabled"] && 
    // ([dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")] || 
    // ([meloManager prefsBoolForKey:@"affectAlbumPagesEnabled"] && 
    // ([dataSource isKindOfClass:objc_getClass("MusicApplication.AlbumsViewController")] ||
    // [dataSource isKindOfClass:objc_getClass("MusicApplication.ArtistViewController")])));

    BOOL hideAlbumTextEnabled = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"];
    BOOL customCornerRadiusEnabled = [meloManager prefsBoolForKey:@"customAlbumCellCornerRadiusEnabled"];
    BOOL applyHideTextToOtherPagesEnabled = [meloManager prefsBoolForKey:@"hideTextAffectsOtherAlbumPagesEnabled"];
    BOOL applyMainLayoutToOtherPagesEnabled = [meloManager prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"];
    BOOL dataSourceIsLRAVC = [dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")];
    BOOL dataSourceIsOtherVC = [dataSource isKindOfClass:objc_getClass("MusicApplication.AlbumsViewController")] || 
        [dataSource isKindOfClass:objc_getClass("MusicApplication.AlbumsViewController")] || 
        [dataSource isKindOfClass:objc_getClass("MusicApplication.JSGridViewController")];

    // set custom corner radius if applicable
    if (customCornerRadiusEnabled && (dataSourceIsLRAVC || (dataSourceIsOtherVC && applyMainLayoutToOtherPagesEnabled))) {

        UIView *artworkView = MSHookIvar<UIView *>(MSHookIvar<id>(self, "artworkComponent"), "imageView");
        CGFloat radius = [[meloManager prefsObjectForKey:@"customAlbumCellCornerRadius"] floatValue] / 100 * [self frame].size.width;

        [artworkView setClipsToBounds:YES];
        [[artworkView layer] setCornerRadius:radius];
        //[[self layer] setContinuousCorners:YES];
    }

    // hide text if applicable
    if (hideAlbumTextEnabled && (dataSourceIsLRAVC || (dataSourceIsOtherVC && applyHideTextToOtherPagesEnabled))) {
        [self setTextAndBadgeHidden:YES];
    }
}

%end

%hook AlbumsViewController

- (id)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    id orig = %orig;

    if ([meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] && [meloManager prefsBoolForKey:@"hideTextAffectsOtherAlbumPagesEnabled"]) {
        [orig setTextAndBadgeHidden:YES];
    }

    if ([meloManager prefsBoolForKey:@"customAlbumCellFontSizeEnabled"] && [meloManager prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"]) {

        NSInteger fontSize = [[meloManager prefsObjectForKey:@"customAlbumCellFontSize"] integerValue];
        UIFont *font = [UIFont systemFontOfSize:fontSize];
        
        // TODO: give these proper types?
        id textStackView = MSHookIvar<id>(orig, "textStackView");
        id indexedComponents = MSHookIvar<id>(textStackView, "indexedComponents");
        id artistComponent = [indexedComponents objectForKey:@"artist"];
        id labelProperties = MSHookIvar<id>(artistComponent, "labelProperties");
        
        MSHookIvar<id>(labelProperties, "_preferredFont") = font;
    }

    return orig;
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] otherPagesCollectionViewCellSpacing];
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] otherPagesCollectionViewCellSpacing];
}

%new
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[MeloManager sharedInstance] otherPagesCollectionViewItemSize];
}

%end


%hook ArtistViewController

- (id)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {
    
    MeloManager *meloManager = [MeloManager sharedInstance];
    id orig = %orig;

    if ([meloManager prefsBoolForKey:@"customAlbumCellFontSizeEnabled"] && [meloManager prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"]) {

        NSInteger fontSize = [[meloManager prefsObjectForKey:@"customAlbumCellFontSize"] integerValue];
        UIFont *font = [UIFont systemFontOfSize:fontSize];
        
        // TODO: give these proper types?
        id textStackView = MSHookIvar<id>(orig, "textStackView");
        id indexedComponents = MSHookIvar<id>(textStackView, "indexedComponents");
        id artistComponent = [indexedComponents objectForKey:@"artist"];
        id labelProperties = MSHookIvar<id>(artistComponent, "labelProperties");
        
        MSHookIvar<id>(labelProperties, "_preferredFont") = font;
    }

    return orig;
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] otherPagesCollectionViewCellSpacing];
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] otherPagesCollectionViewCellSpacing];
}

%new
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[MeloManager sharedInstance] otherPagesCollectionViewItemSize];
}

%end


%hook LibraryRecentlyAddedViewController 

- (id)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    id orig = %orig;

    if ([meloManager prefsBoolForKey:@"hideAlbumTextEnabled"]) {
        [orig setTextAndBadgeHidden:YES];
    } else {
        
        if ([meloManager prefsBoolForKey:@"customAlbumCellFontSizeEnabled"]) {

            NSInteger fontSize = [[meloManager prefsObjectForKey:@"customAlbumCellFontSize"] integerValue];
            UIFont *font = [UIFont systemFontOfSize:fontSize];
            
            // TODO: give these proper types?
            id textStackView = MSHookIvar<id>(orig, "textStackView");
            id indexedComponents = MSHookIvar<id>(textStackView, "indexedComponents");
            id artistComponent = [indexedComponents objectForKey:@"artist"];
            id labelProperties = MSHookIvar<id>(artistComponent, "labelProperties");
            
            MSHookIvar<id>(labelProperties, "_preferredFont") = font;
        }
    }

    return orig;
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] collectionViewCellSpacing];
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] collectionViewCellSpacing];
}

%new
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[MeloManager sharedInstance] collectionViewItemSize];
}

%end


%hook JSGridViewController
%property(assign, nonatomic) BOOL shouldApplyCustomLayout;

- (id)init {
    id orig = %orig;
    [orig setShouldApplyCustomLayout:NO];
    return orig;
}

%new
- (void)checkShouldApplyCustomLayout {
    // TODO: better way of doing this? or is this fine

    MeloManager *meloManager = [MeloManager sharedInstance];

    if (![meloManager prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"] && ![meloManager prefsBoolForKey:@"hideTextAffectsOtherAlbumPagesEnabled"]) {
        [self setShouldApplyCustomLayout:NO];
        return;
    }
    
    MPModelResponse *response = MSHookIvar<MPModelResponse *>(self, "_modelResponse");
    
    if (!response) {
        return;
    }
    
    MPSectionedCollection *collection = [response results];

    if (!collection) {
        return;
    }

    MusicModelGridItem *item = (MPModelObject *)[collection firstItem];

    if (!item) {
        return;
    }

    MPModelStoreBrowseContentItem *contentItem = [item contentItem];

    if (!contentItem) {
        return;
    }

    BOOL isAlbumOrPlaylist = [contentItem album] || [contentItem playlist];
    [self setShouldApplyCustomLayout:isAlbumOrPlaylist];
}

// - (void)viewDidLoad {
//     %orig;
//     // [self checkShouldApplyCustomLayout];
// }

// - (void)viewWillAppear:(BOOL)arg1 {
//     %orig;
//     // [self checkShouldApplyCustomLayout];
// }

// - (void)viewDidAppear:(BOOL)arg1 {
//     %orig;
//     // [self checkShouldApplyCustomLayout];
// } 

- (id)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {
    
    MeloManager *meloManager = [MeloManager sharedInstance];
    id orig = %orig;

    if ([self shouldApplyCustomLayout]) {

        if ([meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] && 
            [meloManager prefsBoolForKey:@"hideTextAffectsOtherAlbumPagesEnabled"] && 
            [orig isKindOfClass:objc_getClass("AlbumCell")]) {
        
            [orig setTextAndBadgeHidden:YES];
        }

        if ([meloManager prefsBoolForKey:@"customAlbumCellFontSizeEnabled"] &&
            [meloManager prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"] &&
            [orig isKindOfClass:objc_getClass("AlbumCell")]) {

            NSInteger fontSize = [[meloManager prefsObjectForKey:@"customAlbumCellFontSize"] integerValue];
            UIFont *font = [UIFont systemFontOfSize:fontSize];
            
            // TODO: give these proper types?
            id textStackView = MSHookIvar<id>(orig, "textStackView");
            id indexedComponents = MSHookIvar<id>(textStackView, "indexedComponents");
            id artistComponent = [indexedComponents objectForKey:@"artist"];
            id labelProperties = MSHookIvar<id>(artistComponent, "labelProperties");
            
            MSHookIvar<id>(labelProperties, "_preferredFont") = font;
        }
    }

    return orig;
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] otherPagesCollectionViewCellSpacing];
}

// %new <- cause of a big headache omg, this method was already implemented so by having %new, my code was never called...
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {    
    
    if ([self shouldApplyCustomLayout]) {
        return [[MeloManager sharedInstance] otherPagesCollectionViewCellSpacing];
    } else {
        return %orig;
    }
}

// %new
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self shouldApplyCustomLayout]) {
        return [[MeloManager sharedInstance] otherPagesCollectionViewItemSize];
    } else {
        return %orig;
    }
}

%end

%hook SocialProfilesFlowCollectionViewLayout

// - (void)prepareLayout {

//     %orig;

//     // uint16_t test = MSHookIvar<uint16_t>(self, "_gridLayoutFlags");

//     // void *test = MSHookIvar<void *>(self, "_gridLayoutFlags");
//     // uint8_t *test2 = (uint8_t *)test;
//     // [Logger logStringWithFormat:@"i mean maybe: %p", test];
//     // [Logger logStringWithFormat:@"%X", *test2];
 
//     // uint16_t test1 = 1;
//     // [Logger logStringWithFormat:@"%X", test1];
//     // uint16_t test = MSHookIvar<uint16_t>(self, "_gridLayoutFlags");
//     // [Logger logStringWithFormat:@"%X", test];

//     // MSHookIvar<uint16_t>(self, "_gridLayoutFlags") = (uint16_t)0xFFFF;

//     // uint16_t test3 = MSHookIvar<uint16_t>(self, "_gridLayoutFlags");
//     // [Logger logStringWithFormat:@"%X", test3];
// }

%end

// TODO: does this conflict with UICollectionView reloadData in Pinning.xm?
%hook UICollectionView

- (void)reloadData {
    // TODO: need to consider where %orig is placed?

    id dataSource = [self dataSource];
    if (dataSource && [dataSource isKindOfClass:objc_getClass("MusicApplication.JSGridViewController")]) {
        [dataSource checkShouldApplyCustomLayout];
    }

    %orig;
    //%orig;
}

%end

%end

// layout hooks constructor
extern "C" void InitLayout() {

    MeloManager *meloManager = [MeloManager sharedInstance];

    if ([meloManager prefsBoolForKey:@"layoutHooksEnabled"]) {
        %init(LayoutGroup,
            AlbumsViewController = objc_getClass("MusicApplication.AlbumsViewController"),
            ArtistViewController = objc_getClass("MusicApplication.ArtistViewController"),
            LibraryRecentlyAddedViewController = objc_getClass("MusicApplication.LibraryRecentlyAddedViewController"),
            AlbumCell = objc_getClass("MusicApplication.AlbumCell"),
            JSGridViewController = objc_getClass("MusicApplication.JSGridViewController"),
            SocialProfilesFlowCollectionViewLayout = objc_getClass("MusicApplication.SocialProfilesFlowCollectionViewLayout")
        );
    }
}