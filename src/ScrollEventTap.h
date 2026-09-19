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
    double accumulatedDelta;
}

// イベントタップを開始する。Universal Access が無効な場合などは NO を返す。
- (BOOL)start;

// イベントタップを停止する。
- (void)stop;

- (BOOL)isRunning;

@end
