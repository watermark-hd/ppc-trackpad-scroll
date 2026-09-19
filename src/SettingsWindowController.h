#import <Cocoa/Cocoa.h>

@class ScrollEventTap;

/*
 * 設定パネル（感度スライダー／方向反転／アクセシビリティ状態表示）
 * Interface Builder の nib を使わず、コードのみでウィンドウを構築する。
 */
@interface SettingsWindowController : NSWindowController
{
    ScrollEventTap *scrollTap;
    NSSlider *sensitivitySlider;
    NSButton *invertCheckbox;
    NSTextField *statusLabel;
}

- (id)initWithScrollTap:(ScrollEventTap *)tap;

- (void)sensitivityChanged:(id)sender;
- (void)invertChanged:(id)sender;
- (void)openAccessibilityPreferences:(id)sender;
- (void)refreshAccessibilityStatus;

@end
