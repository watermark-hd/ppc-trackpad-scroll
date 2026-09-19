#import "SettingsWindowController.h"
#import "ScrollEventTap.h"

@implementation SettingsWindowController

- (id)initWithScrollTap:(ScrollEventTap *)tap
{
    NSRect frame = NSMakeRect(0, 0, 380, 170);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:(NSTitledWindowMask | NSClosableWindowMask)
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    [window setTitle:NSLocalizedString(@"settings.window_title", nil)];
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

    // 英語("Scroll Sensitivity"等)でもラベルが収まるよう、日本語版より少し広めにレイアウトしている。
    NSTextField *sensLabel = [self makeLabelWithFrame:NSMakeRect(20, 130, 130, 20) title:NSLocalizedString(@"settings.sensitivity_label", nil)];
    [content addSubview:sensLabel];

    double currentSensitivity = 4.0;
    NSNumber *storedSensitivity = [[NSUserDefaults standardUserDefaults] objectForKey:@"ScrollSensitivityDivider"];
    if (storedSensitivity != nil) {
        currentSensitivity = [storedSensitivity doubleValue];
    }

    sensitivitySlider = [[NSSlider alloc] initWithFrame:NSMakeRect(155, 130, 205, 20)];
    // 除数が小さいほど高感度。スライダーは 1(高感度)〜10(低感度) の範囲とする。
    [sensitivitySlider setMinValue:1.0];
    [sensitivitySlider setMaxValue:10.0];
    [sensitivitySlider setDoubleValue:currentSensitivity];
    [sensitivitySlider setTarget:self];
    [sensitivitySlider setAction:@selector(sensitivityChanged:)];
    [content addSubview:sensitivitySlider];

    BOOL currentInvert = [[NSUserDefaults standardUserDefaults] boolForKey:@"InvertScrollDirection"];

    invertCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(20, 95, 340, 24)];
    [invertCheckbox setButtonType:NSSwitchButton];
    [invertCheckbox setTitle:NSLocalizedString(@"settings.invert_checkbox", nil)];
    [invertCheckbox setState:(currentInvert ? NSOnState : NSOffState)];
    [invertCheckbox setTarget:self];
    [invertCheckbox setAction:@selector(invertChanged:)];
    [content addSubview:invertCheckbox];

    statusLabel = [self makeLabelWithFrame:NSMakeRect(20, 58, 340, 20) title:@""];
    [content addSubview:statusLabel];

    NSButton *accessibilityButton = [[NSButton alloc] initWithFrame:NSMakeRect(20, 20, 280, 26)];
    [accessibilityButton setTitle:NSLocalizedString(@"menu.open_accessibility_prefs", nil)];
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
    // LSUIElement の常駐アプリは強制終了されることもあるため、変更を即座にディスクへ反映する。
    [[NSUserDefaults standardUserDefaults] synchronize];
    // イベントタップ側は起動時に読み込んだ値をキャッシュして使っているため、
    // 変更をその場で反映させる。
    [scrollTap setSensitivityDivider:value];
}

- (void)invertChanged:(id)sender
{
    BOOL invert = ([invertCheckbox state] == NSOnState);
    [[NSUserDefaults standardUserDefaults] setBool:invert forKey:@"InvertScrollDirection"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [scrollTap setInvertDirection:invert];
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
        [statusLabel setStringValue:NSLocalizedString(@"settings.accessibility_enabled", nil)];
    } else {
        [statusLabel setStringValue:NSLocalizedString(@"settings.accessibility_disabled", nil)];
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
