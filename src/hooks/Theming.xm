#import <UIKit/UIKit.h>
#import "hooks.h"
#import "../objc/objc_classes.h"
#import "../interfaces/interfaces.h"

%group ThemingGroup 

%hook UIView

// set the tint color of all uiviews 
- (void)setTintColor:(id)arg1 {
    
    MeloManager *meloManager = [MeloManager sharedInstance];
    
    if (arg1 && [meloManager prefsBoolForKey:@"customTintColorEnabled"]) {

        // get names of the pink color and current tint color
        NSString *name = [arg1 accessibilityName];
        NSString *pinkName = [[UIColor systemPinkColor] accessibilityName];

        // check if custom tint color is enabled and the names match
        if (name && [pinkName isEqualToString:name]) {
            
            // set the custom tint color
            UIColor *color = [ColorUtils dictToColor:[meloManager prefsObjectForKey:@"customTintColor"]];

            if (color) {
                %orig(color);
                return;
            }
        }
    }

    // call orig if all conditions were not met
    %orig;
}

%end

%end

// theming hooks constructor
extern "C" void InitTheming() {

    MeloManager *meloManager = [MeloManager sharedInstance];

    if ([meloManager prefsBoolForKey:@"themingHooksEnabled"]) {
        %init(ThemingGroup);
    }
}