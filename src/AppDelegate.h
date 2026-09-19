#import <Cocoa/Cocoa.h>

@class ScrollEventTap;
@class SettingsWindowController;

@interface AppDelegate : NSObject
{
    NSStatusItem *statusItem;
    ScrollEventTap *scrollTap;
    SettingsWindowController *settingsWindowController;
    NSTimer *accessibilityRetryTimer;
}

- (void)tryStartEventTap;
- (void)showSettings:(id)sender;
- (void)openAccessibilityPreferences:(id)sender;
- (void)quit:(id)sender;

@end
