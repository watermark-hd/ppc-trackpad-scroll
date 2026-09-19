#import "AppDelegate.h"
#import "ScrollEventTap.h"
#import "SettingsWindowController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // デフォルト設定を登録（感度の除数: 値が大きいほど低感度）
    // 方向はデフォルトで反転（ナチュラル風）にしている。
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults setObject:[NSNumber numberWithDouble:4.0] forKey:@"ScrollSensitivityDivider"];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"InvertScrollDirection"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    // メニューバーアイコン（画像リソースを持たないためテキストタイトルを使用。
    // 矢印などの記号グリフは当時のフォントで幅が正しく取れないことがあるため
    // 確実に表示される ASCII 文字にしている）
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItem setTitle:@"TP"];
    [statusItem setHighlightMode:YES];

    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];

    NSMenuItem *settingsItem = [menu addItemWithTitle:NSLocalizedString(@"menu.settings", nil) action:@selector(showSettings:) keyEquivalent:@""];
    [settingsItem setTarget:self];

    NSMenuItem *accessibilityItem = [menu addItemWithTitle:NSLocalizedString(@"menu.open_accessibility_prefs", nil) action:@selector(openAccessibilityPreferences:) keyEquivalent:@""];
    [accessibilityItem setTarget:self];

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [menu addItemWithTitle:NSLocalizedString(@"menu.quit", nil) action:@selector(quit:) keyEquivalent:@"q"];
    [quitItem setTarget:self];

    [statusItem setMenu:menu];
    [menu release];

    // イベントタップを開始（権限が無ければ案内して再試行する）
    scrollTap = [[ScrollEventTap alloc] init];
    [self tryStartEventTap];
}

- (void)tryStartEventTap
{
    if ([scrollTap start]) {
        if (accessibilityRetryTimer != nil) {
            [accessibilityRetryTimer invalidate];
            accessibilityRetryTimer = nil;
        }
        NSLog(@"%@", NSLocalizedString(@"log.tap_started", nil));
        return;
    }

    NSLog(@"%@", NSLocalizedString(@"log.tap_failed", nil));

    if (accessibilityRetryTimer == nil) {
        int result = NSRunAlertPanel(
            NSLocalizedString(@"alert.accessibility_required.title", nil),
            NSLocalizedString(@"alert.accessibility_required.message", nil),
            NSLocalizedString(@"alert.button.open_prefs", nil),
            NSLocalizedString(@"alert.button.later", nil),
            nil
        );

        if (result == NSAlertDefaultReturn) {
            [self openAccessibilityPreferences:nil];
        }

        accessibilityRetryTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                                     target:self
                                                                   selector:@selector(tryStartEventTap)
                                                                   userInfo:nil
                                                                    repeats:YES];
    }
}

- (void)showSettings:(id)sender
{
    if (settingsWindowController == nil) {
        settingsWindowController = [[SettingsWindowController alloc] initWithScrollTap:scrollTap];
    }
    [settingsWindowController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)openAccessibilityPreferences:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
}

- (void)quit:(id)sender
{
    [NSApp terminate:self];
}

- (void)dealloc
{
    [accessibilityRetryTimer invalidate];
    [scrollTap stop];
    [scrollTap release];
    [settingsWindowController release];
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
    [statusItem release];
    [super dealloc];
}

@end
