
#import <UIKit/UIKit.h>
#import "hooks.h"
#import "../objc/objc_classes.h"
#import "../interfaces/interfaces.h"

// hooks focused on customizing the layout of the music app
%group LayoutGroup

// customize the appearance of album cells in various collection views
%hook AlbumCell
%property(strong, nonatomic) AlbumCellTextView *customTextView;
%property(assign, nonatomic) BOOL shouldApplyCornerRadius;
%property(assign, nonatomic) BOOL shouldHideText;
%property(assign, nonatomic) BOOL shouldChangeFontSize;

// initialize the album cell
- (id)initWithFrame:(CGRect)arg1 {

    id orig = %orig;

    [orig setShouldApplyCornerRadius:NO];
    [orig setShouldHideText:NO];
    [orig setShouldChangeFontSize:NO];

    return self;
}

// set various settings which describe how the album cell will be displayed
%new
- (void)applyDisplayDict:(NSDictionary *)arg1 {
    
    if (arg1[@"shouldApplyCornerRadius"]) {
        [self setShouldApplyCornerRadius:[arg1[@"shouldApplyCornerRadius"] boolValue]];
    }

    if (arg1[@"shouldHideText"]) {
        [self setShouldHideText:[arg1[@"shouldHideText"] boolValue]];
    }

    if (arg1[@"shouldChangeFontSize"]) {
        [self setShouldChangeFontSize:[arg1[@"shouldChangeFontSize"] boolValue]];
    }
}

// lays out subviews
- (void)layoutSubviews {

    %orig;

    MeloManager *meloManager = [MeloManager sharedInstance];

    // set custom corner radius if applicable
    if ([self shouldApplyCornerRadius]) {

        UIView *artworkView = MSHookIvar<UIView *>(MSHookIvar<id>(self, "artworkComponent"), "imageView");
        CGFloat radius = [meloManager prefsFloatForKey:@"customAlbumCellCornerRadius"] / 100 * [self frame].size.width;

        [artworkView setClipsToBounds:YES];
        [[artworkView layer] setCornerRadius:radius];
        //[[self layer] setContinuousCorners:YES];
    }

    // hide text if applicable
    if ([self shouldHideText]) {
        [self setTextAndBadgeHidden:YES];
        [self setCustomTextViewHidden:YES];

    // change font size if applicable
    } else if ([self shouldChangeFontSize]) {
        [self setTextAndBadgeHidden:YES];
        [self setCustomTextViewHidden:NO];
        
        AlbumCellTextView *customTextView = [self customTextView];
        UIView *textStackView = MSHookIvar<UIView *>(self, "textStackView");

        if (customTextView && textStackView) {
            customTextView.frame = textStackView.frame;
        }
    } else {
        [self setTextAndBadgeHidden:NO];
        [self setCustomTextViewHidden:YES];
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

// attempts to show / hide the custom text view
%new
- (void)setCustomTextViewHidden:(BOOL)arg1 {

    AlbumCellTextView *customTextView = [self customTextView];
    if (customTextView) {
        [customTextView setHidden:arg1];
    }
}

// creates a new subview which redraws the album text 
%new
- (void)createCustomTextView {

    MeloManager *meloManager = [MeloManager sharedInstance];
    AlbumCellTextView *customTextView = [self customTextView];
    UIView *textStackView = MSHookIvar<UIView *>(self, "textStackView");

    // ensure this album cell has a custom text view as a subview
    if (!customTextView) {
        customTextView = [AlbumCellTextView new];
        [self addSubview:customTextView];
        [self setCustomTextView:customTextView];
    } else if (![customTextView isDescendantOfView:self]) {
        [customTextView removeFromSuperview];
        [self addSubview:customTextView];
    }

    // set up custom text view values
    [customTextView setTitleText:[self title]];
    [customTextView setArtistText:[self artistName]];
    [customTextView setShouldShowExplicitBadge:[self accessibilityIsExplicit]];
    [customTextView setSpacing:[meloManager albumCellTextSpacing]];
    [customTextView setLabelFontSize:[meloManager prefsIntForKey:@"customAlbumCellFontSize"]];
}

%end

// view controller found by going to the page Full Library > Albums
%hook AlbumsViewController
%property(strong, nonatomic) NSDictionary *albumCellDisplayOptions;

// called once to initialize the view controller
- (id)init {

    id orig = %orig;

    // get options for how the album cell should be displayed
    NSDictionary *albumCellDisplayOptions = [[MeloManager sharedInstance] albumCellDisplayDictForDataSource:self];
    [self setAlbumCellDisplayOptions:albumCellDisplayOptions];

    return orig;
}

// called when the view has been loaded into memory
- (void)viewDidLoad {
    %orig;

    // add an observer for whenever a layout preferences change was detected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLayoutPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_LAYOUT" object:nil];
}

// return the album cell for a given index path
- (UICollectionViewCell *)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    AlbumCell *orig = (AlbumCell *)%orig;

    [orig applyDisplayDict:[self albumCellDisplayOptions]];

    // hide album text and explicit badge if applicable
    if ([meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] && [meloManager prefsBoolForKey:@"textLayoutAffectsOtherAlbumPagesEnabled"]) {
        [orig setTextAndBadgeHidden:YES];
    
    // change the album text font size if applicable
    } else if ([meloManager prefsBoolForKey:@"customAlbumCellFontSizeEnabled"] && [meloManager prefsBoolForKey:@"textLayoutAffectsOtherAlbumPagesEnabled"]) {
        [orig createCustomTextView];
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

// update the view when layout preferences were changed
%new
- (void)handleLayoutPrefsUpdate:(NSNotification *)arg1 {

    // get options for how the album cell should be displayed
    NSDictionary *albumCellDisplayOptions = [[MeloManager sharedInstance] albumCellDisplayDictForDataSource:self];
    [self setAlbumCellDisplayOptions:albumCellDisplayOptions];

    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");
    [collectionView reloadData];
}

%end


// view controller found by going to the page Full Library > Artists > [arbitrary artist]
%hook ArtistViewController
%property(strong, nonatomic) NSDictionary *albumCellDisplayOptions;

// called once to initialize the view controller
- (id)init {

    id orig = %orig;

    // get options for how the album cell should be displayed
    NSDictionary *albumCellDisplayOptions = [[MeloManager sharedInstance] albumCellDisplayDictForDataSource:self];
    [self setAlbumCellDisplayOptions:albumCellDisplayOptions];

    return orig;
}

// called when the view has been loaded into memory
- (void)viewDidLoad {
    %orig;

    // add an observer for whenever a layout preferences change was detected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLayoutPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_LAYOUT" object:nil];
}

// return the album cell for a given index path
- (UICollectionViewCell *)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    AlbumCell *orig = (AlbumCell *)%orig;

    [orig applyDisplayDict:[self albumCellDisplayOptions]];

    // hide album text and explicit badge if applicable
    if ([meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] && [meloManager prefsBoolForKey:@"textLayoutAffectsOtherAlbumPagesEnabled"]) {
        [orig setTextAndBadgeHidden:YES];
    
    // change the album text font size if applicable
    } else if ([meloManager prefsBoolForKey:@"customAlbumCellFontSizeEnabled"] && [meloManager prefsBoolForKey:@"textLayoutAffectsOtherAlbumPagesEnabled"]) {
        [orig createCustomTextView];
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

// update the view when layout preferences were changed
%new
- (void)handleLayoutPrefsUpdate:(NSNotification *)arg1 {

    // get options for how the album cell should be displayed
    NSDictionary *albumCellDisplayOptions = [[MeloManager sharedInstance] albumCellDisplayDictForDataSource:self];
    [self setAlbumCellDisplayOptions:albumCellDisplayOptions];

    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");
    [collectionView reloadData];
}

%end


// main recently added view controller - found by viewing the Full Library
%hook LibraryRecentlyAddedViewController 
%property(strong, nonatomic) NSDictionary *albumCellDisplayOptions;

// called once to initialize the view controller
- (id)init {

    id orig = %orig;

    // get options for how the album cell should be displayed
    NSDictionary *albumCellDisplayOptions = [[MeloManager sharedInstance] albumCellDisplayDictForDataSource:self];
    [self setAlbumCellDisplayOptions:albumCellDisplayOptions];

    return orig;
}

// called when the view has been loaded into memory
- (void)viewDidLoad {
    %orig;

    // add an observer for whenever a layout preferences change was detected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLayoutPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_LAYOUT" object:nil];
}

// return the album cell for a given index path
- (UICollectionViewCell *)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    AlbumCell *orig = (AlbumCell *)%orig;

    [orig applyDisplayDict:[self albumCellDisplayOptions]];

    // hide album text and explicit badge if applicable
    if ([meloManager prefsBoolForKey:@"hideAlbumTextEnabled"]) {
        [orig setTextAndBadgeHidden:YES];
    
    // change the album text font size if applicable
    } else if ([meloManager prefsBoolForKey:@"customAlbumCellFontSizeEnabled"]) {
        [orig createCustomTextView];
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

// update the view when layout preferences were changed
%new
- (void)handleLayoutPrefsUpdate:(NSNotification *)arg1 {
    
    // get options for how the album cell should be displayed
    NSDictionary *albumCellDisplayOptions = [[MeloManager sharedInstance] albumCellDisplayDictForDataSource:self];
    [self setAlbumCellDisplayOptions:albumCellDisplayOptions];

    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");
    [collectionView reloadData];
}

%end


// view controller used when viewing a page of albums / playlists pretty much anywhere other than the Full Library
// however, it's also used for song lists, music video pages, etc which need to be avoided (i.e. they'll crash) when applying the album cell layout
%hook JSGridViewController
%property(assign, nonatomic) BOOL shouldApplyCustomLayout;
%property(strong, nonatomic) NSDictionary *albumCellDisplayOptions;

// default initializer
- (id)init {

    id orig = %orig;

    // by default, assume that custom layout will not be applied
    [orig setShouldApplyCustomLayout:NO];

    // get options for how the album cell should be displayed
    NSDictionary *albumCellDisplayOptions = [[MeloManager sharedInstance] albumCellDisplayDictForDataSource:self];
    [self setAlbumCellDisplayOptions:albumCellDisplayOptions];

    return orig;
}

// return the collection view cell for a given index path
- (UICollectionViewCell *)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {
    
    MeloManager *meloManager = [MeloManager sharedInstance];
    id orig = %orig;

    if ([self shouldApplyCustomLayout] && [orig isKindOfClass:objc_getClass("MusicApplication.AlbumCell")]) {

        [orig applyDisplayDict:[self albumCellDisplayOptions]];

        // hide album text and explicit badge if applicable
        if ([meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] && 
            [meloManager prefsBoolForKey:@"textLayoutAffectsOtherAlbumPagesEnabled"]) {
            
            [orig setTextAndBadgeHidden:YES];
        
        // change the album text font size if applicable
        } else if ([meloManager prefsBoolForKey:@"customAlbumCellFontSizeEnabled"] &&
            [meloManager prefsBoolForKey:@"textLayoutAffectsOtherAlbumPagesEnabled"]) {

            [orig createCustomTextView];
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
    if (![meloManager prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"] && ![meloManager prefsBoolForKey:@"textLayoutAffectsOtherAlbumPagesEnabled"]) {
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

    // observe layout changes if custom layout is applied
    if (isAlbumOrPlaylist) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLayoutPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_LAYOUT" object:nil];
    }
}

// update the view when layout preferences were changed
%new
- (void)handleLayoutPrefsUpdate:(NSNotification *)arg1 {

    // get options for how the album cell should be displayed
    NSDictionary *albumCellDisplayOptions = [[MeloManager sharedInstance] albumCellDisplayDictForDataSource:self];
    [self setAlbumCellDisplayOptions:albumCellDisplayOptions];

    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");
    [collectionView reloadData];
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


// helper debug method to make things easier in flexing
// %hook TextStackView

// %new
// - (id)labelProperties_test:(NSInteger)arg1 {
//     NSArray *orderedComponents = MSHookIvar<NSArray *>(self, "orderedComponents");
//     return MSHookIvar<id>(orderedComponents[arg1], "labelProperties");
// }

// %end

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