#import "SettingsWindowController.h"
#import "ScrollEventTap.h"

// gcc 4.0.1 (Tiger付属) は @"..." リテラル中のUTF-8日本語を正しく扱えず
// 文字化けするため、C文字列からUTF-8として明示的にデコードする。
#define J(cstr) [NSString stringWithUTF8String:(cstr)]

@implementation SettingsWindowController

- (id)initWithScrollTap:(ScrollEventTap *)tap
{
    NSRect frame = NSMakeRect(0, 0, 320, 170);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:(NSTitledWindowMask | NSClosableWindowMask)
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    [window setTitle:J("PPC Trackpad 設定")];
    [window setReleasedWhenClosed:NO];
    [window center];

    self = [super initWithWindow:window];
    if (self != nil) {
        scrollTap = [tap retain];
        [window setDelegate:self];
        [self buildContentView];
    }
    [window release];

    return self;
}

- (NSTextField *)makeLabelWithFrame:(NSRect)frame title:(NSString *)title
{
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue:title];
    [label setEditable:NO];
    [label setBordered:NO];
    [label setDrawsBackground:NO];
    [label autorelease];
    return label;
}

- (void)buildContentView
{
    NSView *content = [[self window] contentView];

    NSTextField *sensLabel = [self makeLabelWithFrame:NSMakeRect(20, 130, 90, 20) title:J("スクロール感度")];
    [content addSubview:sensLabel];

    double currentSensitivity = 4.0;
    NSNumber *storedSensitivity = [[NSUserDefaults standardUserDefaults] objectForKey:@"ScrollSensitivityDivider"];
    if (storedSensitivity != nil) {
        currentSensitivity = [storedSensitivity doubleValue];
    }

    sensitivitySlider = [[NSSlider alloc] initWithFrame:NSMakeRect(115, 130, 185, 20)];
    // 除数が小さいほど高感度。スライダーは 1(高感度)〜10(低感度) の範囲とする。
    [sensitivitySlider setMinValue:1.0];
    [sensitivitySlider setMaxValue:10.0];
    [sensitivitySlider setDoubleValue:currentSensitivity];
    [sensitivitySlider setTarget:self];
    [sensitivitySlider setAction:@selector(sensitivityChanged:)];
    [content addSubview:sensitivitySlider];

    BOOL currentInvert = [[NSUserDefaults standardUserDefaults] boolForKey:@"InvertScrollDirection"];

    invertCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(20, 95, 280, 24)];
    [invertCheckbox setButtonType:NSSwitchButton];
    [invertCheckbox setTitle:J("スクロール方向を反転する（ナチュラル風）")];
    [invertCheckbox setState:(currentInvert ? NSOnState : NSOffState)];
    [invertCheckbox setTarget:self];
    [invertCheckbox setAction:@selector(invertChanged:)];
    [content addSubview:invertCheckbox];

    statusLabel = [self makeLabelWithFrame:NSMakeRect(20, 58, 280, 20) title:@""];
    [content addSubview:statusLabel];

    NSButton *accessibilityButton = [[NSButton alloc] initWithFrame:NSMakeRect(20, 20, 220, 26)];
    [accessibilityButton setTitle:J("アクセシビリティ環境設定を開く")];
    [accessibilityButton setBezelStyle:NSRoundedBezelStyle];
    [accessibilityButton setTarget:self];
    [accessibilityButton setAction:@selector(openAccessibilityPreferences:)];
    [content addSubview:accessibilityButton];
    [accessibilityButton release];

    [self refreshAccessibilityStatus];
}

- (void)sensitivityChanged:(id)sender
{
    double value = [sensitivitySlider doubleValue];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:value] forKey:@"ScrollSensitivityDivider"];
}

- (void)invertChanged:(id)sender
{
    BOOL invert = ([invertCheckbox state] == NSOnState);
    [[NSUserDefaults standardUserDefaults] setBool:invert forKey:@"InvertScrollDirection"];
}

- (void)openAccessibilityPreferences:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
    [self performSelector:@selector(refreshAccessibilityStatus) withObject:nil afterDelay:1.0];
}

- (void)refreshAccessibilityStatus
{
    Boolean trusted = AXAPIEnabled();
    if (trusted) {
        [statusLabel setStringValue:J("状態: アクセシビリティ 有効")];
    } else {
        [statusLabel setStringValue:J("状態: アクセシビリティ 無効（要設定）")];
    }
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [self refreshAccessibilityStatus];
}

- (void)dealloc
{
    [scrollTap release];
    [sensitivitySlider release];
    [invertCheckbox release];
    [super dealloc];
}

@end
