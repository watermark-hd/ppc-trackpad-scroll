#import "ScrollEventTap.h"

static CGEventRef ScrollEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);

@implementation ScrollEventTap

- (id)init
{
    self = [super init];
    if (self != nil) {
        eventTap = NULL;
        runLoopSource = NULL;
        accumulatedDelta = 0.0;

        // AppDelegate が registerDefaults: を済ませた後に生成される前提のため、
        // ここで一度だけ読み込んでおけば以降はイベントコールバック内で
        // NSUserDefaults を毎回引く必要がない。
        NSNumber *sensitivityNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"ScrollSensitivityDivider"];
        sensitivityDivider = (sensitivityNumber != nil) ? [sensitivityNumber doubleValue] : 4.0;
        if (sensitivityDivider <= 0.0) {
            sensitivityDivider = 4.0;
        }
        invertDirection = [[NSUserDefaults standardUserDefaults] boolForKey:@"InvertScrollDirection"];
    }
    return self;
}

- (BOOL)isRunning
{
    return (eventTap != NULL);
}

- (void)setSensitivityDivider:(double)divider
{
    if (divider > 0.0) {
        sensitivityDivider = divider;
    }
}

- (void)setInvertDirection:(BOOL)invert
{
    invertDirection = invert;
}

- (BOOL)start
{
    if (eventTap != NULL) {
        return YES;
    }

    // 監視イベントは FlagsChanged と MouseMoved のみに限定する。
    // ボタンを押した状態での移動（物理クリックドラッグ／タップロックによる
    // ドラッグの両方）は kCGEventLeftMouseDragged 等の別イベント種別で
    // 配信されるため、このマスクには含まれず素通りする。
    // そのため ⌘+ドラッグによるファイル移動やテキスト選択とは競合しない。
    CGEventMask mask = CGEventMaskBit(kCGEventFlagsChanged) | CGEventMaskBit(kCGEventMouseMoved);

    // 10.4u SDK の CGEventTypes.h には kCGEventTapOptionDefault が定義されていないため
    // （kCGEventTapOptionListenOnly = 1 のみ定義）、アクティブなタップを表す 0 を直接指定する。
    //
    // タップの挿入位置は kCGTailAppendEventTap（末尾＝他のタップより後）にしている。
    // DoubleCommand のような修飾キー入れ替えユーティリティが「自分のタップの中で」
    // ⌘フラグを付与している場合、先頭挿入だとそのフラグが付与される前の生イベントを
    // 見てしまい ⌘ 押下を検知できないことがある。末尾に回ることで、他のタップが
    // 解決した後の最終的な修飾キー状態を見てから判定できる。
    eventTap = CGEventTapCreate(
        kCGSessionEventTap,        // 現在のユーザーセッション全体を監視
        kCGTailAppendEventTap,     // 他のイベントタップ（修飾キー入れ替え等）の後に処理させる
        (CGEventTapOptions)0,      // イベントの書き換え・破棄を行うためアクティブなタップにする
        mask,
        ScrollEventTapCallback,
        self
    );

    if (eventTap == NULL) {
        // Universal Access（補助装置へのアクセス）が無効な場合などに NULL が返る
        return NO;
    }

    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);

    accumulatedDelta = 0.0;

    return YES;
}

- (void)stop
{
    if (eventTap == NULL) {
        return;
    }

    CGEventTapEnable(eventTap, false);

    if (runLoopSource != NULL) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        CFRelease(runLoopSource);
        runLoopSource = NULL;
    }

    CFRelease(eventTap);
    eventTap = NULL;
}

- (CGEventRef)handleEvent:(CGEventRef)event type:(CGEventType)type
{
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
        // システムに無効化された場合は再度有効化して監視を継続する
        if (eventTap != NULL) {
            CGEventTapEnable(eventTap, true);
        }
        return event;
    }

    if (type == kCGEventFlagsChanged) {
        // 修飾キーの状態変化はそのまま素通りさせる（他アプリのUI更新等に必要なため）
        return event;
    }

    if (type == kCGEventMouseMoved) {
        CGEventFlags flags = CGEventGetFlags(event);
        BOOL commandDown = (flags & kCGEventFlagMaskCommand) != 0;

        if (!commandDown) {
            accumulatedDelta = 0.0;
            return event;
        }

        int64_t deltaY = CGEventGetIntegerValueField(event, kCGMouseEventDeltaY);

        // 指を上に動かす(deltaY < 0)と上方向にスクロールするのを「通常」とする。
        // 「反転」設定が有効な場合は符号を入れ替える。
        double scroll = (double)(-deltaY) / sensitivityDivider;
        if (invertDirection) {
            scroll = -scroll;
        }

        // 端数を蓄積し、小さい移動でも取りこぼさないようにする
        accumulatedDelta += scroll;
        int32_t wheelDelta = (int32_t)accumulatedDelta;

        // CGEventCreateScrollWheelEvent は 10.4u SDK に存在しないため、
        // 汎用の CGEventCreate + CGEventSetType でスクロールホイールイベントを
        // 手動で組み立てる。値は概ね -10〜+10 程度を想定しているため念のため
        // クランプする。クランプは「送出用の値」にのみ適用し、accumulatedDelta
        // からは実際に送出した分だけを差し引く。先に丸め値そのものを引いてしまうと、
        // 高感度設定で素早くフリックした際に ±10 を超えた分がそのまま消失し、
        // 速く動かすほどスクロールが効かなく感じる不具合になるため。
        int32_t postedDelta = wheelDelta;
        if (postedDelta > 10) {
            postedDelta = 10;
        } else if (postedDelta < -10) {
            postedDelta = -10;
        }
        accumulatedDelta -= postedDelta;

        // 重要: ⌘キーを押したままこのイベントを送出すると、送出イベントにも
        // ⌘フラグが乗ってしまい、Safari/Firefox系ブラウザなどが「⌘+スクロール」
        // を拡大縮小と解釈してしまう（実機で確認した不具合）。そのため
        // CGEventSetFlags(event, 0) で明示的に修飾キーを取り除いてから送出する。
        if (postedDelta != 0) {
            CGEventRef scrollEvent = CGEventCreate(NULL);
            if (scrollEvent != NULL) {
                CGEventSetType(scrollEvent, kCGEventScrollWheel);
                CGEventSetIntegerValueField(scrollEvent, kCGScrollWheelEventDeltaAxis1, postedDelta);
                CGEventSetFlags(scrollEvent, 0);
                CGEventPost(kCGHIDEventTap, scrollEvent);
                CFRelease(scrollEvent);
            }
        }

        // ⌘押下中はカーソル移動そのものを常にキャンセルする
        return NULL;
    }

    return event;
}

- (void)dealloc
{
    [self stop];
    [super dealloc];
}

@end

static CGEventRef ScrollEventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
    ScrollEventTap *tap = (ScrollEventTap *)refcon;
    return [tap handleEvent:event type:type];
}
