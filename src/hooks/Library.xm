#import <UIKit/UIKit.h>
#import "hooks.h"
#import "../objc/objc_classes.h"
#import "../interfaces/interfaces.h"

// hooks focused on customizing the library experience
%group LibraryGroup 

%hook LibraryMenuViewController

%new
- (id)dataSource {
    return MSHookIvar<id>(self, "dataSource");
}

- (void)viewWillAppear:(BOOL)arg1 {
    %orig;

    // id dataSource = MSHookIvar<id>(self, "dataSource");
    // id diffDataSource = MSHookIvar<id>(dataSource, "_impl");

    // [diffDataSource appendItemsWithIdentifiers:@[@"test"]];

    // [[self tableView] reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    LibraryMenuDataSource *dataSource = [self dataSource];
    MeloManager *meloManager = [MeloManager sharedInstance];
    
    if (indexPath.row == [dataSource tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {

        UIViewController *lastSongsViewController = meloManager.lastSongsViewController;
        
        [[self navigationController] pushViewController:lastSongsViewController animated:YES];
        [lastSongsViewController.navigationItem setRightBarButtonItems:meloManager.lastSongsNavItem animated:YES];

    } else {
        %orig;
    }
}


%end

%hook LibraryMenuDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return %orig + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {
        // id cell = [[objc_getClass("_TtCC16MusicApplication25LibraryMenuViewController4Cell") alloc] initWithReuseIdentifier:@"LibraryMenuViewController.Cell"];
        id cell = [[objc_getClass("_TtCC16MusicApplication25LibraryMenuViewController4Cell") alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LibraryMenuViewController.Cell"];
        [cell setText:@"Show Last Viewed Album"];

        // UIImageSymbolConfiguration *imageConfig = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightUnspecified scale:UIImageSymbolScaleDefault];
        UIImageSymbolConfiguration *imageConfig = [UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleTitle2 scale:UIImageSymbolScaleMedium];
        UIImage *image = [UIImage systemImageNamed:@"clock.arrow.circlepath" withConfiguration:imageConfig];

        MSHookIvar<UIImage *>(cell, "symbol") = image;
        MSHookIvar<UIImageView *>(cell, "symbolView").image = image;
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

        return cell;
    } else {
        return %orig;
    }
}

%new 
- (id)impl {
    return MSHookIvar<id>(self, "_impl");
}

%end


%hook ContainerDetailSongsViewController

- (void)viewDidAppear:(BOOL)arg1 {
    %orig;

    UIViewController *controller = self;
    UIViewController *parent;
    BOOL foundNavController = NO;

    for (NSInteger i = 0; i < 10; i++) {
        parent = [controller parentViewController];

        if ([parent isKindOfClass:[UINavigationController class]]) {
            
            // NSData *tempArchiveViewController = [NSKeyedArchiver archivedDataWithRootObject:controller];
            // UIViewController *newController = [NSKeyedUnarchiver unarchiveObjectWithData:tempArchiveViewController];

            [MeloManager sharedInstance].lastSongsViewController = controller;
            [MeloManager sharedInstance].lastSongsNavItem = [NSArray arrayWithArray:controller.navigationItem.rightBarButtonItems];
            foundNavController = YES;
            break;
        }

        controller = parent;
    }

    if (!foundNavController) {
        [MeloManager sharedInstance].lastSongsViewController = self;
    }
}

%end


%hook UITabBarController

- (void)transitionFromViewController:(id)arg1 toViewController:(id)arg2 {

    [Logger logStringWithFormat:@"UITabBarController transitionFromViewController:%@ toViewController:%@", arg1, arg2];
    // %orig;

    MeloManager *meloManager = [MeloManager sharedInstance];
    NSMutableArray *data = meloManager.tabsLastControllers;

    if (!arg1) {
        %orig;
        return;
    }

    NSInteger startIndex = [self.viewControllers indexOfObject:arg1];
    NSInteger endIndex = [self.viewControllers indexOfObject:arg2];

    if ([arg1 isKindOfClass:objc_getClass("MusicApplication.NavigationController")]) {
        data[startIndex] = [NSArray arrayWithArray:[arg1 viewControllers]];
    }

    // // data[startIndex] = [NSArray arrayWithArray:((UINavigationController *)arg1).viewControllers];

    if ([arg2 isKindOfClass:objc_getClass("MusicApplication.NavigationController")] && [data[endIndex] count] > 0) {
        [arg2 setViewControllers:data[endIndex] animated:NO];
    }

    %orig;
}


%end


// LibraryGroup end
%end

// theming hooks constructor
extern "C" void InitLibrary() {

    MeloManager *meloManager = [MeloManager sharedInstance];

    if ([meloManager prefsBoolForKey:@"libraryHooksEnabled"]) {
        %init(LibraryGroup,
            LibraryMenuViewController = objc_getClass("MusicApplication.LibraryMenuViewController"),
            LibraryMenuDataSource = objc_getClass("_TtGC5UIKit29UITableViewDiffableDataSourceSSOV9MusicCore11LibraryMenu10Identifier_"),
            ContainerDetailSongsViewController = objc_getClass("MusicApplication.ContainerDetailSongsViewController")
        );
    }
}