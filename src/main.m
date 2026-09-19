/*
 * PPC Trackpad Scroll
 * ⌘キーを押しながらのトラックパッド移動をスクロールへ変換する常駐アプリ
 * 対象: Mac OS X 10.4 Tiger / 10.5 Leopard (PowerPC)
 *
 * MainMenu.xib を使わず、コードだけで NSApplication を起動する
 * （Info.plist の LSUIElement によりメニューバー常駐・Dockアイコンなしで動作する）
 */
#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    [NSApplication sharedApplication];

    AppDelegate *delegate = [[AppDelegate alloc] init];
    [NSApp setDelegate:delegate];

    [NSApp run];

    [delegate release];
    [pool release];
    return 0;
}
