#import "AppDelegate.h"
#import "ScrollEventTap.h"
#import "SettingsWindowController.h"

// gcc 4.0.1 (Tiger付属) は @"..." リテラル中のUTF-8日本語を正しく扱えず
// 文字化けするため、C文字列からUTF-8として明示的にデコードする。
#define J(cstr) [NSString stringWithUTF8String:(cstr)]

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

    NSMenuItem *settingsItem = [menu addItemWithTitle:J("設定...") action:@selector(showSettings:) keyEquivalent:@""];
    [settingsItem setTarget:self];

    NSMenuItem *accessibilityItem = [menu addItemWithTitle:J("アクセシビリティ環境設定を開く") action:@selector(openAccessibilityPreferences:) keyEquivalent:@""];
    [accessibilityItem setTarget:self];

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [menu addItemWithTitle:J("終了") action:@selector(quit:) keyEquivalent:@"q"];
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
        NSLog(@"%@", J("PPCTrackpad: イベントタップを開始しました"));
        return;
    }

    NSLog(@"%@", J("PPCTrackpad: アクセシビリティ権限がないためイベントタップを開始できません"));

    if (accessibilityRetryTimer == nil) {
        int result = NSRunAlertPanel(
            J("アクセシビリティ権限が必要です"),
            J("「システム環境設定 > Universal Access」で「補助装置にアクセスできるようにする」を有効にしてください。有効化後、自動的に再試行します。"),
            J("環境設定を開く"),
            J("後で"),
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
    [statusItem release];
    [super dealloc];
}

@end
