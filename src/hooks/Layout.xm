
#import <UIKit/UIKit.h>
#import "hooks.h"
#import "../objc/objc_classes.h"
#import "../interfaces/interfaces.h"

// hooks focused on customizing the layout of the music app
%group LayoutGroup

// customize the appearance of album cells in various collection views
%hook AlbumCell

// lays out subviews
- (void)layoutSubviews {
    %orig;

    MeloManager *meloManager = [MeloManager sharedInstance];
    id dataSource = [[self _collectionView] dataSource];

    // check various settings and data sources
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

// attempts to either show / hide the album text and explicit badge
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

// sets the text size of the artist and title labels 
%new
- (void)setTextToPrefsFontSize {
    
    NSInteger fontSize = [[[MeloManager sharedInstance] prefsObjectForKey:@"customAlbumCellFontSize"] integerValue];
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    
    UIView *textStackView = MSHookIvar<UIView *>(self, "textStackView");
    NSDictionary *indexedComponents = MSHookIvar<NSDictionary *>(textStackView, "indexedComponents");
    
    // only need to set one of the components for both to change, as they likely share the labelProperties object
    id artistComponent = indexedComponents[@"artist"];
    id labelProperties = MSHookIvar<id>(artistComponent, "labelProperties");
    
    MSHookIvar<UIFont *>(labelProperties, "_preferredFont") = font;
}

%end


// view controller found by going to the page Full Library > Albums
%hook AlbumsViewController

// return the album cell for a given index path
- (UICollectionViewCell *)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    AlbumCell *orig = (AlbumCell *)%orig;

    // hide album text and explicit badge if applicable
    if ([meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] && [meloManager prefsBoolForKey:@"hideTextAffectsOtherAlbumPagesEnabled"]) {
        [orig setTextAndBadgeHidden:YES];
    
    // change the album text font size if applicable
    } else if ([meloManager prefsBoolForKey:@"customAlbumCellFontSizeEnabled"] && [meloManager prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"]) {
        [orig setTextToPrefsFontSize];
    }

    return orig;
}

// minimum value between successive album cells in row/columns in a section - used to implement custom columns
%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] otherPagesCollectionViewCellSpacing];
}

// minimum value between successive row/columns in a section - used to implement custom columns
%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] otherPagesCollectionViewCellSpacing];
}

// provides the size for album cells - used to implement custom columns
%new
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[MeloManager sharedInstance] otherPagesCollectionViewItemSize];
}

%end


// view controller found by going to the page Full Library > Artists > [arbitrary artist]
%hook ArtistViewController

// return the album cell for a given index path
- (UICollectionViewCell *)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    AlbumCell *orig = (AlbumCell *)%orig;

    // hide album text and explicit badge if applicable
    if ([meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] && [meloManager prefsBoolForKey:@"hideTextAffectsOtherAlbumPagesEnabled"]) {
        [orig setTextAndBadgeHidden:YES];
    
    // change the album text font size if applicable
    } else if ([meloManager prefsBoolForKey:@"customAlbumCellFontSizeEnabled"] && [meloManager prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"]) {
        [orig setTextToPrefsFontSize];
    }

    return orig;
}

// minimum value between successive album cells in row/columns in a section - used to implement custom columns
%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] otherPagesCollectionViewCellSpacing];
}

// minimum value between successive row/columns in a section - used to implement custom columns
%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] otherPagesCollectionViewCellSpacing];
}

// provides the size for album cells - used to implement custom columns
%new
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[MeloManager sharedInstance] otherPagesCollectionViewItemSize];
}

%end


// main recently added view controller - found by viewing the Full Library
%hook LibraryRecentlyAddedViewController 

// return the album cell for a given index path
- (UICollectionViewCell *)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    AlbumCell *orig = (AlbumCell *)%orig;

    // hide album text and explicit badge if applicable
    if ([meloManager prefsBoolForKey:@"hideAlbumTextEnabled"]) {
        [orig setTextAndBadgeHidden:YES];
    
    // change the album text font size if applicable
    } else if ([meloManager prefsBoolForKey:@"customAlbumCellFontSizeEnabled"]) {
        [orig setTextToPrefsFontSize];
    }

    return orig;
}

// minimum value between successive album cells in row/columns in a section - used to implement custom columns
%new 
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] collectionViewCellSpacing];
}

// minimum value between successive row/columns in a section - used to implement custom columns
%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] collectionViewCellSpacing];
}

// provides the size for album cells - used to implement custom columns
%new
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[MeloManager sharedInstance] collectionViewItemSize];
}

%end


// view controller used when viewing a page of albums / playlists pretty much anywhere other than the Full Library
// however, it's also used for song lists, music video pages, etc which need to be avoided (i.e. they'll crash) when applying the album cell layout
%hook JSGridViewController
%property(assign, nonatomic) BOOL shouldApplyCustomLayout;

// default initializer
- (id)init {

    // by default, assume that custom layout will not be applied
    id orig = %orig;
    [orig setShouldApplyCustomLayout:NO];
    return orig;
}

// return the collection view cell for a given index path
- (UICollectionViewCell *)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {
    
    MeloManager *meloManager = [MeloManager sharedInstance];
    id orig = %orig;

    if ([self shouldApplyCustomLayout]) {
        
        // hide album text and explicit badge if applicable
        if ([meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] && 
            [meloManager prefsBoolForKey:@"hideTextAffectsOtherAlbumPagesEnabled"] && 
            [orig isKindOfClass:objc_getClass("AlbumCell")]) {
        
            [orig setTextAndBadgeHidden:YES];
        
        // change the album text font size if applicable
        } else if ([meloManager prefsBoolForKey:@"customAlbumCellFontSizeEnabled"] &&
            [meloManager prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"] &&
            [orig isKindOfClass:objc_getClass("AlbumCell")]) {

            [orig setTextToPrefsFontSize];
        }
    }

    return orig;
}

// minimum value between successive album cells in row/columns in a section - used to implement custom columns
%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] otherPagesCollectionViewCellSpacing];
}

// minimum value between successive row/columns in a section - used to implement custom columns
// %new <- cause of a big headache omg, this method was already implemented so by having %new, my code was never called...
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {    
    
    if ([self shouldApplyCustomLayout]) {
        return [[MeloManager sharedInstance] otherPagesCollectionViewCellSpacing];
    } else {
        return %orig;
    }
}

// provides the size for album cells - used to implement custom columns
// %new <- same thing, it was actually already implemented :p
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self shouldApplyCustomLayout]) {
        return [[MeloManager sharedInstance] otherPagesCollectionViewItemSize];
    } else {
        return %orig;
    }
}

// perform a guarded check of the response data to see if this grid view contains albums and/or playlists
%new
- (void)checkShouldApplyCustomLayout {

    MeloManager *meloManager = [MeloManager sharedInstance];

    // if other pages are not being affected by either setting, custom layout should never be applied
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

    MusicModelGridItem *item = (MusicModelGridItem *)[collection firstItem];
    if (!item) {
        return;
    }

    MPModelStoreBrowseContentItem *contentItem = [item contentItem];
    if (!contentItem) {
        return;
    }

    // if album or playlist is not nil, the grid view is displaying album cells and the layout can be applied
    BOOL isAlbumOrPlaylist = [contentItem album] || [contentItem playlist];
    [self setShouldApplyCustomLayout:isAlbumOrPlaylist];
}

%end


// targeting UICollectionViews of JSGridViewControllers
%hook UICollectionView

// use this hook to check collection view content since it's called after the data load
- (void)reloadData {

    // use loaded data to see if it's a collection view of albums and/or playlists
    id dataSource = [self dataSource];
    if (dataSource && [dataSource isKindOfClass:objc_getClass("MusicApplication.JSGridViewController")]) {
        [dataSource checkShouldApplyCustomLayout];
    }

    %orig;
}

%end

// LayoutGroup end
%end

// layout hooks constructor
extern "C" void InitLayout() {

    MeloManager *meloManager = [MeloManager sharedInstance];

    if ([meloManager prefsBoolForKey:@"layoutHooksEnabled"]) {
        %init(LayoutGroup,
            AlbumCell = objc_getClass("MusicApplication.AlbumCell"),
            AlbumsViewController = objc_getClass("MusicApplication.AlbumsViewController"),
            ArtistViewController = objc_getClass("MusicApplication.ArtistViewController"),
            LibraryRecentlyAddedViewController = objc_getClass("MusicApplication.LibraryRecentlyAddedViewController"),
            JSGridViewController = objc_getClass("MusicApplication.JSGridViewController")
        );
    }
}