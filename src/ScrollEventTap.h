#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

/*
 * ⌘キー押下中のトラックパッド（マウス）移動を検知し、
 * ScrollWheel イベントへ変換して送出するイベントタップのコントローラ。
 */
@interface ScrollEventTap : NSObject
{
    CFMachPortRef eventTap;
    CFRunLoopSourceRef runLoopSource;
    NSTimer *postTimer;
    double accumulatedDelta;
    double sensitivityDivider;
    BOOL invertDirection;
}

// イベントタップを開始する。Universal Access が無効な場合などは NO を返す。
- (BOOL)start;

// イベントタップを停止する。
- (void)stop;

- (BOOL)isRunning;

// 設定変更を即座に反映する（イベントコールバック内で毎回 NSUserDefaults を
// 読みに行かずに済むよう、値はイベントタップ側で保持しておく）。
- (void)setSensitivityDivider:(double)divider;
- (void)setInvertDirection:(BOOL)invert;

@end
