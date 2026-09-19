# 仕様書（spec.md）の骨子案

## 1. 概要 (Overview)

- **目的**: iBook / PowerBook 等のレガシーMacにおいて、⌘ (Command) キーを押しながらトラックパッドを上下移動させた際に、画面スクロール（ScrollWheel Event）へと変換する常駐アプリ。
- **対象OS**: OS X 10.4 Tiger / OS X 10.5 Leopard (PowerPC / Universal)
- **開発環境**: Xcode 2.5 / C & Cocoa (Objective-C)

## 2. コアロジック (Core Logic)

- **イベントフック**: `CGEventTapCreate` を使用し、`kCGHeadInsertEventTap` にてグローバルイベントを監視。
- **監視イベント**:
  - `kCGEventFlagsChanged`（修飾キーの状態監視）
  - `kCGEventMouseMoved`（トラックパッド/マウス移動の監視）
- **判定と変換アルゴリズム**:
  - `CGEventGetFlags` で `kCGEventFlagMaskCommand`（⌘キー）がオンになっているか確認。
  - ⌘ ＝ OFF: 通常のマウス移動としてスルー。
  - ⌘ ＝ ON:
    - 現在の `kCGEventMouseMoved` を握りつぶす（`return NULL` でカーソル移動をキャンセル）。
    - ΔY（上下の移動ピクセル）を取得。
    - 感度調整用ディバイダー（例: ΔY/N）を適用。
    - `CGEventCreateScrollWheelEvent` でスクロールイベントを生成し、`CGEventPost` で送信。

## 3. 左右の⌘キー（JIS/US）対応

- 右⌘キー（Right Command）と左⌘キー（Left Command）のどちらが押されていても動作するよう、`kCGEventFlagMaskCommand` フラグ全体を判定対象とする。

## 4. GUI & 設定項目 (UI & Preferences)

- **常駐形態**: メニューバー常駐（NSStatusItem）で軽量動作。
- **設定UI**:
  - スクロール感度（Slider）
  - スクロール方向の反転（Checkbox: 通常 / ナチュラル風）
  - 補助装置（Universal Access）の有効化チェック＆誘導ボタン
