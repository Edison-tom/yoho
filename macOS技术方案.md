# Yoho macOS 端技术方案

> 基于产品方案 V3.1 | 2026-07-04
> 目标：原生 SwiftUI + AppKit 混编，macOS 15+


## 一、架构总览

```
┌──────────────────────────────────────────────────┐
│                  Yoho App                         │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ Floating │  │  Pet     │  │  Tree         │  │
│  │ Window   │  │  Render  │  │  Render       │  │
│  │ (AppKit) │  │  (Lottie)│  │  (SwiftUI+CA) │  │
│  └──────────┘  └──────────┘  └───────────────┘  │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ Idle     │  │  Local   │  │  Supabase     │  │
│  │ Monitor  │  │  Store   │  │  Sync         │  │
│  │ (CGEvent)│  │  (GRDB)  │  │  (URLSession) │  │
│  └──────────┘  └──────────┘  └───────────────┘  │
└──────────────────────────────────────────────────┘
```

## 二、技术选型

| 模块 | Yoho 方案原文 | macOS 落地 | 理由 |
|:---|:---|:---|:---|
| UI 框架 | Tauri | **SwiftUI + AppKit 混编** | macOS 原生，零嵌合体，浮窗/透明/置顶天然支持 |
| 自动计时 | CGEventSource（Mac） | 直接用，原生 API | macOS 自带，无需跨平台抽象 |
| 本地存储 | SQLite | **GRDB.swift**（SQLite 封装） | Swift 原生，类型安全，比 Core Data 轻量 |
| 宠物渲染 | Lottie / Spine 2D | **Lottie iOS/macOS**（Airbnb 开源） | 直接加载 After Effects 导出的 JSON 动画 |
| 树渲染 | CSS 关键帧 | **SwiftUI + CAAnimation** | 树的阶段跃迁用 CA 过渡，日常微动用 SwiftUI |
| 网络同步 | SSE + HTTP | **URLSession** + AsyncStream | Swift 原生并发，不引第三方网络库 |
| 加密 | AES-256 | **CryptoKit**（Apple 内置） | 零依赖，硬件加速 |
| 认证 | Supabase Auth | **supabase-swift** SDK | Supabase 官方 Swift 库 |
| 自动更新 | Tauri updater | **Sparkle 2** | macOS 原生更新框架，行业标准 |

## 三、项目结构

遵循 `swiftui-patterns` 的 macOS 文件组织规范：

```
Yoho/
├── Package.swift
├── script/
│   └── build_and_run.sh
├── .codex/
│   └── environments/
│       └── environment.toml
├── Sources/
│   └── Yoho/
│       ├── App/
│       │   ├── YohoApp.swift              ← @main
│       │   └── AppDelegate.swift          ← NSApplicationDelegate
│       ├── Views/
│       │   ├── ContentView.swift          ← 根布局
│       │   ├── FloatingWindowView.swift   ← 浮窗主界面（单身/情侣）
│       │   ├── PetView.swift              ← 宠物渲染组件
│       │   ├── TreeView.swift             ← 树渲染组件
│       │   ├── TreeLabelBubble.swift      ← 树冠悬浮气泡
│       │   ├── InteractionMenu.swift      ← 伴侣互动扇形菜单
│       │   ├── CookieFertilizerHUD.swift  ← 饼干/肥料角标
│       │   ├── OnboardingView.swift       ← 首次设定流程
│       │   ├── ForestArchiveView.swift    ← 森林档案
│       │   ├── MemoryCapsuleView.swift    ← 记忆胶囊
│       │   ├── SettingsView.swift         ← 设置窗口
│       │   └── DiagnosticView.swift       ← 诊断报告/事件时间线
│       ├── Models/
│       │   ├── User.swift                 ← 用户模型
│       │   ├── Pet.swift                  ← 宠物（品种/动画状态）
│       │   ├── Tree.swift                 ← 树（阶段/肥料数/目标）
│       │   ├── Cookie.swift               ← 饼干计数
│       │   ├── Fertilizer.swift           ← 肥料
│       │   ├── Quote.swift                ← 金句
│       │   └── Goal.swift                 ← 目标设定
│       ├── Stores/
│       │   ├── AppState.swift             ← @Observable 全局状态
│       │   ├── FocusTimer.swift           ← 专注计时器（CGEvent）
│       │   ├── PetStore.swift             ← 宠物状态管理
│       │   ├── TreeStore.swift            ← 树状态管理
│       │   ├── SyncEngine.swift           ← 离线优先同步引擎
│       │   └── DatabaseStore.swift        ← GRDB 本地存储
│       ├── Services/
│       │   ├── SupabaseClient.swift       ← Supabase API 封装
│       │   ├── AuthService.swift          ← 登录/注册
│       │   ├── QuoteService.swift         ← 金句管理
│       │   ├── CryptoService.swift        ← CryptoKit 加密
│       │   ├── DiagnosticService.swift    ← 诊断数据收集
│       │   └── UpdateService.swift        ← Sparkle 更新管理
│       ├── Bridges/
│       │   ├── FloatingWindow.swift       ← NSWindow 浮窗（AppKit 桥）
│       │   ├── TransparentWindow.swift    ← 透明/半透明窗口
│       │   ├── MouseTracker.swift         ← 鼠标悬停检测
│       │   └── IdleDetector.swift         ← CGEventSource 空闲检测
│       └── Support/
│           ├── Constants.swift            ← 尺寸/颜色/API 常量
│           ├── DateFormatter+Ext.swift    ← 日期格式化
│           └── Color+Ext.swift            ← 项目色板
└── Tests/
    └── YohoTests/
        ├── FocusTimerTests.swift
        ├── SyncEngineTests.swift
        └── TreeStageCalculationTests.swift
```

## 四、浮窗实现（核心难点 1）

需求：240×320 置顶窗口，80% 透明，无标题栏，不抢焦点。

### 纯 SwiftUI 做不到，必须 AppKit Bridge：

```swift
// Bridges/FloatingWindow.swift
import AppKit
import SwiftUI

final class FloatingWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // 关键属性，对应方案 §3.1
        self.level = .floating              // 置顶
        self.isOpaque = false
        self.backgroundColor = .clear       // 透明背景
        self.alphaValue = 0.8              // 默认 80% 半透明
        self.hasShadow = false
        self.collectionBehavior = [
            .canJoinAllSpaces,             // 跨桌面空间
            .stationary,                   // 不随 Mission Control 移动
            .ignoresCycle                  // 不被 Cmd+Tab 切换
        ]
        self.isMovableByWindowBackground = true  // 拖拽移动

        // 鼠标悬停恢复不透明
        self.acceptsMouseMovedEvents = true
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
```

### 透明度切换（方案 §3.1）：

```swift
// 在 AppDelegate 或 WindowController 中
NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
    guard let win = self?.window else { return event }
    let mouseInWindow = win.contentView?.bounds.contains(
        win.contentView!.convert(event.locationInWindow, from: nil)
    ) ?? false

    NSAnimationContext.runAnimationGroup { ctx in
        ctx.duration = 0.3
        win.animator().alphaValue = mouseInWindow ? 1.0 : 0.8
    }
    return event
}
```

## 五、空闲检测与专注计时（核心难点 2）

需求：检测系统未休眠 + 键鼠空闲 < 5 分钟 → 计时。方案 §2.1。

```swift
// Bridges/IdleDetector.swift
import CoreGraphics
import IOKit

final class IdleDetector {
    /// 返回上次键盘/鼠标事件至今的秒数
    static func secondsSinceLastInput() -> Double {
        CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: ~CGEventType(0)
        )
    }

    /// 系统是否在休眠
    static var isSystemAsleep: Bool {
        // 通过 IOKit 判断电源管理状态
        // 或者检查 NSWorkspace 通知
        false // 简化示例
    }

    /// 双保险判断
    static var isUserActive: Bool {
        !isSystemAsleep && secondsSinceLastInput() < 300  // 5分钟
    }
}
```

### 专注计时器 Store：

```swift
// Stores/FocusTimer.swift
@Observable
final class FocusTimer {
    private(set) var todayMinutes = 0
    private(set) var cookies = 0
    private var accumulatedSeconds = 0
    private var timer: Timer?

    private let dailyMaxCookies = 8  // 方案 §2.1 防卷保护
    private let focusInterval: TimeInterval = 30 * 60  // 30 分钟

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self, IdleDetector.isUserActive else { return }

            self.accumulatedSeconds += 5

            if self.accumulatedSeconds >= self.focusInterval {
                self.accumulatedSeconds = 0
                if self.cookies < self.dailyMaxCookies {
                    self.cookies += 1
                    self.todayMinutes += 30
                }
            }
        }
    }
}
```

## 六、宠物与树渲染（核心难点 3）

### 6.1 宠物：Lottie 动画

```swift
// Views/PetView.swift
import SwiftUI
import Lottie

struct PetView: View {
    let breed: PetBreed       // 橘猫/狸花/泰迪/金毛
    let state: PetState       // idle/eating/sleeping/running/visiting

    var body: some View {
        LottieView(animation: .named(state.animationName(for: breed)))
            .playing(loopMode: state.isLooping ? .loop : .playOnce)
            .animationSpeed(1.0)
            .frame(width: 60, height: 60)
    }
}

enum PetState {
    case idle, eating, producing, sleeping, runningOut, visiting

    func animationName(for breed: PetBreed) -> String {
        "\(breed.rawValue)_\(self.rawValue)"
    }
}
```

### 6.2 树：SwiftUI + CAAnimation 阶段跃迁

```swift
// Views/TreeView.swift
struct TreeView: View {
    let tree: Tree
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // 花盆 + 横截面（种子期）
            if tree.stage == .seed {
                SeedPotView(progress: tree.stageProgress)
            } else {
                // 树干 + 树冠
                Image(tree.stage.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
            }
        }
        .onChange(of: tree.stage) { _, _ in
            withAnimation(.spring(duration: 0.8)) {
                scale = 1.1
            } completion: {
                withAnimation(.spring) { scale = 1.0 }
            }
        }
    }
}

enum TreeStage {
    case seed      // 种子期 0%
    case sprout    // 萌芽期 20%
    case growing   // 成长期 40%
    case lush      // 繁茂期 60%
    case blooming  // 开花期 80%
    case fruiting  // 结果期 100%

    var imageName: String { "tree_\(self.rawValue)" }
    var stageProgress: Double { /* 0-1 区间 */ 0 }
}
```

## 七、离线优先同步引擎

### 操作日志队列（方案 §5.2 情侣同步）：

```swift
// Stores/SyncEngine.swift
@Observable
final class SyncEngine {
    private let db: DatabaseStore
    private let api: SupabaseClient
    private var pendingOps: [SyncOperation] = []

    /// 本地执行，写入操作队列
    func enqueue(_ op: SyncOperation) async {
        await db.write(op)          // 本地 SQLite 先存
        pendingOps.append(op)       // 加入待同步队列
        tryFlush()                  // 尝试推送到服务器
    }

    /// 批量推送到 Supabase
    private func tryFlush() {
        guard !pendingOps.isEmpty else { return }
        Task {
            do {
                try await api.pushSyncEvents(pendingOps)
                pendingOps.removeAll()
            } catch {
                // 失败不丢弃，下次自动重试
                Logger.sync.warning("Sync flush failed, \(pendingOps.count) ops queued")
            }
        }
    }
}

struct SyncOperation: Codable {
    let coupleId: String
    let fromUser: String
    let eventType: String
    let payload: JSON
    let timestamp: Date
}
```

## 八、Supabase 集成

```swift
// Services/SupabaseClient.swift
import Supabase

final class SupabaseClient {
    // 读取 .env 或 Info.plist 中的配置
    static let shared = SupabaseClient(
        supabaseURL: URL(string: Bundle.main.object(
            forInfoDictionaryKey: "SUPABASE_URL") as! String)!,
        supabaseKey: Bundle.main.object(
            forInfoDictionaryKey: "SUPABASE_ANON_KEY") as! String
    )

    // 注册
    func signUp(email: String, password: String) async throws -> User {
        try await supabase.auth.signUp(email: email, password: password)
    }

    // 登录
    func signIn(email: String, password: String) async throws -> Session {
        try await supabase.auth.signIn(email: email, password: password)
    }

    // 同步事件批量推送
    func pushSyncEvents(_ events: [SyncOperation]) async throws {
        try await supabase.from("sync_events").insert(events).execute()
    }

    // 拉取伴侣的待处理事件
    func pullSyncEvents(coupleId: String, since: Date) async throws -> [SyncOperation] {
        try await supabase.from("sync_events")
            .select()
            .eq("couple_id", value: coupleId)
            .gt("created_at", value: since)
            .execute()
            .value
    }
}
```

**Info.plist 配置**：
```xml
<key>SUPABASE_URL</key>
<string>https://uzrqvoftpyjjbbdsqngc.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>eyJhbGciOiJIUzI1NiI...</string>
```

## 九、构建与运行

### 9.1 `script/build_and_run.sh`（遵循 build-run-debug 规范）：

```bash
#!/bin/bash
set -euo pipefail

APP_NAME="Yoho"
BUNDLE_ID="app.yoho.desktop"
BUNDLE_PATH="dist/${APP_NAME}.app"
EXEC_PATH="${BUNDLE_PATH}/Contents/MacOS/${APP_NAME}"

# 1. 杀掉现有进程
pkill -x "$APP_NAME" 2>/dev/null || true

# 2. 构建
swift build -c debug --product "$APP_NAME"

# 3. 创建 .app bundle（SwiftPM GUI 应用规范）
mkdir -p "${BUNDLE_PATH}/Contents/MacOS"
cp ".build/debug/${APP_NAME}" "$EXEC_PATH"

# 4. Info.plist
cat > "${BUNDLE_PATH}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
    <key>CFBundleName</key><string>${APP_NAME}</string>
    <key>LSMinimumSystemVersion</key><string>15.0</string>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
EOF

# 5. 启动
/usr/bin/open -n "$BUNDLE_PATH"
```

### 9.2 `.codex/environments/environment.toml`

```toml
[[actions]]
id = "run"
command = "./script/build_and_run.sh"
description = "Build and launch Yoho"
```

## 十、分阶段实现路径

| 阶段 | 内容 | 交付物 | 验证标准 |
|:---|:---|:---|:---|
| **P0 骨架** | SwiftUI 项目搭建，浮窗显示，透明/置顶，可拖拽 | 一个空的浮动窗口 | 置顶于所有窗口，80% 透明，可拖拽 |
| **P1 计时** | CGEventSource 空闲检测 + 专注计时，饼干生成 | 窗口角标显示饼干数 | 30 分钟专注 → 饼干 +1 |
| **P2 宠物** | Lottie 加载 4 种默认宠物，idle/eating 动画 | 宠物在窗口中动起来 | 点击拖拽饼干到宠物 → 咀嚼动画 |
| **P3 树** | 种子花盆横截面 → 6 阶段树，CAAnimation 过渡 | 拖拽肥料到树根 → 树长大 | 6 个阶段视觉完整 |
| **P4 认证** | Supabase Auth 邮箱注册/登录 | 注册登录流程完整 | 注册→写 users 表→登录可查 |
| **P5 单身模式** | 目标设定 → 80% 时间倒推 → 结果期 → 海报 | 单人完整闭环 | 设目标→专注→成长→结果→海报 |
| **P6 情侣模式** | 配对码 + 专属/共养宠物 + 串门 + 互动 | 情侣完整闭环 | 配对→互喂→串门→共养→同步 |
| **P7 金句** | 内置 200 句，按场景/模式自动匹配 | 完成专注后树冠气泡显示 | 单身/情侣 solo/情侣 together 金句不同 |
| **P8 设置** | 设置窗口：宠物选择/金句频率/隐身模式/诊断 | 完整 Settings 窗口 | 所有设置可调且生效 |
| **P9 更新** | Sparkle 2 自动更新集成 | 版本检测 → 下载 → 安装 | 服务端放新版 → 客户端提示升级 |
| **P10 诊断** | 一键诊断报告 + 静默上报 | 右键菜单 → 导出 txt | 日志含状态+事件+错误+环境 |

## 十一、关键决策记录

| 决策 | 选项 A | 选项 B | 选择 | 理由 |
|:---|:---|:---|:---|:---|
| UI 框架 | Tauri（跨平台） | SwiftUI 原生 | **SwiftUI** | 浮窗/透明/置顶需 AppKit，Tauri 做不到原生体验 |
| 数据库 | Core Data | GRDB (SQLite) | **GRDB** | 轻量，类型安全，离线队列操作更自然 |
| 宠物渲染 | 纯 SwiftUI Canvas | Lottie | **Lottie（MVP）** | 快速可用，美术友好；表现力有限，后续替换为带 alpha 通道的 MP4 |
| 树渲染 | CSS（Tauri 原方案） | SwiftUI + CAAnimation | **SwiftUI+CA** | 6 阶段静态图 + 过渡动画，不需要完整 CSS 引擎 |
| 自动更新 | Tauri updater | Sparkle 2 | **Sparkle 2** | macOS 原生，所有主流 Mac App 标配 |
| 网络层 | Alamofire | URLSession | **URLSession** | 零依赖，async/await 原生支持 |

## 十二、依赖清单

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    .package(url: "https://github.com/groue/GRDB.swift", from: "6.0.0"),
    .package(url: "https://github.com/airbnb/lottie-ios", from: "4.0.0"),  // MVP 临时方案，后续替换为带 alpha 通道 MP4
    .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0"),
]
```

唯一需要自行开发的重量级模块是**浮窗管理**（AppKit 桥）和**空闲检测**（CGEventSource）——但两者代码量都不大，各 50 行以内。


## 十三、管理后台

详见 `/Volumes/file/Codex/Yoho/管理后台方案.md`。
MVP 用 Supabase SQL Editor 直接查统计；后续在 App 内嵌管理窗口。
核心 SQL：`SELECT * FROM admin_stats` 一键返回注册数/DAU/付费/收入。
