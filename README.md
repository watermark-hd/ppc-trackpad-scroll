# PPC Trackpad Scroll

iBook / PowerBook など、2本指スクロールに対応していないレガシーMac（PowerPC）のトラックパッド用に、
**⌘（Command）キーを押しながらトラックパッドを上下に動かすと、画面がスクロールする**ようにする常駐アプリです。

A menu-bar background app for legacy PowerPC Macs (iBook / PowerBook, etc.) whose trackpads don't support
two-finger scrolling. **Hold the ⌘ (Command) key and move the trackpad up/down to scroll the screen.**

メニューバーに常駐し（Dockアイコンなし）、⌘＋トラックパッド移動を検知してスクロールホイールイベントに変換します。
It runs as a menu-bar item (no Dock icon), detecting ⌘+trackpad movement and converting it into scroll wheel events.

---

## 日本語

### 動作環境

- Mac OS X 10.4 Tiger / 10.5 Leopard（PowerPC）
- Universal Access（アクセシビリティ）へのアクセスが有効になっていること
  - 「システム環境設定 > Universal Access」の「補助装置にアクセスできるようにする」
  - 無効な場合、初回起動時にアプリがダイアログで案内します（有効化後は自動的に再試行します）

### インストール

1. `PPCTrackpad.app` を好きな場所（アプリケーションフォルダなど）に置く
2. ダブルクリックで起動（メニューバーに `TP` と表示されます）
3. Universal Access が無効な場合はダイアログの案内に従って有効化する

アプリはOS標準フレームワークのみに依存しているため、フォルダを移動しても問題なく動作します（zip単体で配布・実行可能）。

### 使い方

- ⌘キーを押しながらトラックパッドを上下に動かす → スクロール
- メニューバーの `TP` → 「設定...」から以下を変更可能
  - スクロール感度（スライダー）
  - スクロール方向の反転（デフォルトで反転＝ナチュラル風が有効）
  - アクセシビリティの状態確認・環境設定を開く

### 仕組み

- `CGEventTapCreate` でシステム全体の `kCGEventFlagsChanged` / `kCGEventMouseMoved` を監視
- ⌘キーが押されている間の `kCGEventMouseMoved` のみを検知し、カーソル移動をキャンセルしてスクロールイベントに変換して送出
- 監視対象は「ボタンを押していない移動」のみのため、クリックドラッグやタップロックドラッグ（⌘＋ファイルのドラッグ移動など）とは競合しません
- 送出するスクロールイベントは修飾キーフラグを明示的に取り除いているため、⌘＋スクロール＝拡大縮小という一般的な規約と衝突しません（下記Aquafoxの注意点を除く）

### Aquafox（TenFourFox系ブラウザ）をお使いの方へ

Aquafoxなど Gecko 系ブラウザには、`⌘＋ホイール＝ページ拡大縮小` という独自の挙動があります。
特に [DoubleCommand](http://actinicsoft.com/doublecommand/) 等で右Enterキーなどを⌘キーに割り当てている場合、
本来のスクロール操作が拡大縮小として認識されてしまうことがあります（Finderなど他のアプリでは発生しません）。

改善するには、Aquafoxのアドレスバーに `about:config` と入力し、以下の設定を `0` に変更してください。

- `mousewheel.with_meta.action`
- （必要であれば）`mousewheel.with_control.action`

これで⌘（または割り当てたキー）＋トラックパッドでも正常にスクロールするようになります。

### ビルド方法

Xcode（xcodebuild）ではなく `gcc` を直接使う `Makefile` でビルドします。10.4u SDK が入った環境（実機のPowerPC Mac、Tiger/Leopard）を想定しています。

```sh
make        # PPCTrackpad.app をビルド
make debug  # フォアグラウンドで実行し、ログを確認しながらテスト
make run    # open でアプリを起動
make clean  # ビルド成果物を削除
```

### 既知の制限

- PowerPC専用ビルドです（Intel Macでは動作しません）
- スクロール量は感度設定と実際のトラックパッドの移動量に依存するため、機種や個人の操作感に応じて調整が必要な場合があります
- 動作確認は iBook G4 / Mac OS X 10.4.11 で行っています

### ライセンス

MIT License. `LICENSE` ファイルを参照してください。

---

## English

### Requirements

- Mac OS X 10.4 Tiger / 10.5 Leopard (PowerPC)
- Universal Access must be enabled
  - System Preferences > Universal Access > "Enable access for assistive devices"
  - If it isn't enabled, the app shows a dialog on first launch and automatically retries once you turn it on

### Installation

1. Put `PPCTrackpad.app` anywhere you like (e.g. the Applications folder)
2. Double-click to launch (a `TP` label appears in the menu bar)
3. If Universal Access is disabled, follow the dialog to enable it

The app links only against standard OS frameworks, so moving the folder around does not break it —
it's safe to distribute and run as a standalone zip.

### Usage

- Hold ⌘ and move the trackpad up/down to scroll
- Click `TP` in the menu bar → "設定..." (Settings) to change:
  - Scroll sensitivity (slider)
  - Invert scroll direction (inverted / "natural" style is enabled by default)
  - Check Universal Access status / open the preference pane

### How it works

- Uses `CGEventTapCreate` to watch system-wide `kCGEventFlagsChanged` / `kCGEventMouseMoved` events
- Only intercepts `kCGEventMouseMoved` while ⌘ is held: it cancels the cursor movement and posts a synthetic scroll wheel event instead
- Only "button-up" movement is watched, so click-drags and tap-lock drags (e.g. ⌘+dragging a file) are never touched, since those are delivered as a different event type
- The synthetic scroll event has its modifier flags explicitly cleared, so it won't collide with the common "⌘+scroll = zoom" convention (see the Aquafox note below for one exception)

### Note for Aquafox (TenFourFox-family browser) users

Gecko-based browsers such as Aquafox implement their own `⌘+wheel = page zoom` behavior.
In particular, if you use [DoubleCommand](http://actinicsoft.com/doublecommand/) or similar to map a key
such as the right Enter key to ⌘, a normal scroll gesture may be misinterpreted as a zoom
(this does not happen in Finder or other apps).

To fix it, open `about:config` in Aquafox's address bar and set the following to `0`:

- `mousewheel.with_meta.action`
- `mousewheel.with_control.action` (if needed)

This makes scrolling work correctly with ⌘ (or whichever key you've mapped) + trackpad.

### Building

This builds with a plain `gcc`-based `Makefile`, not `xcodebuild`. It assumes an environment with the
10.4u SDK (i.e. a real PowerPC Mac running Tiger or Leopard).

```sh
make        # build PPCTrackpad.app
make debug  # run in the foreground so you can watch the log output
make run    # launch the app with `open`
make clean  # remove build artifacts
```

### Known limitations

- PowerPC-only build (won't run on Intel Macs)
- Scroll amount depends on the sensitivity setting and actual trackpad movement, so it may need tuning per machine/preference
- Tested on an iBook G4 / Mac OS X 10.4.11

### License

MIT License. See `LICENSE`.
