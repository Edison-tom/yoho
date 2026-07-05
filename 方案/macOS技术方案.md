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


> **宠物品种（不可变）**：银渐层 / 布偶 / 泰迪 / 金毛。
> 详见产品方案 §1.3。品种选定后不可更改，本地 `PetBreed` 枚举保持不变。

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
│       │   ├── FloatingWindowView.swift   ← 浮窗主界面
│       │   ├── TreeSwitcherView.swift     ← 多树切换器（≤3 棵缩略卡片 + N）
│       │   ├── TreeDetailPanel.swift      ← 树详情面板（所有树一览/钉选/排序）
│       │   ├── TransitionFlowView.swift   ← 建立恋爱关系过渡流程
│       │   ├── PetView.swift              ← 宠物渲染组件
│       │   ├── TreeView.swift             ← 树渲染组件
│       │   ├── TreeLabelBubble.swift      ← 树冠悬浮气泡
│       │   ├── InteractionMenu.swift      ← 伴侣互动扇形菜单
│       │   ├── CookieFertilizerHUD.swift  ← 饼干/肥料角标
│       │   ├── OnboardingView.swift       ← 首次设定流程
│       │   ├── ForestArchiveView.swift    ← 森林档案
│       │   ├── MemoryCapsuleView.swift    ← 记忆胶囊
│       │   ├── MiniGoalView.swift         ← 个人小目标便签
│       │   ├── SettingsView.swift         ← 设置窗口
│       │   └── DiagnosticView.swift       ← 诊断报告/事件时间线
│       ├── Models/
│       │   ├── User.swift                 ← 用户模型
│       │   ├── Pet.swift                  ← 宠物（品种/动画状态）
│       │   ├── Tree.swift                 ← 树（阶段/肥料数/目标）
│       │   ├── Nickname.swift             ← 昵称（我的昵称 + 称呼Ta）
│       │   ├── Cookie.swift               ← 饼干计数
│       │   ├── Fertilizer.swift           ← 肥料
│       │   ├── Quote.swift                ← 金句
│       │   └── Goal.swift                 ← 目标设定
│       ├── Stores/
│       │   ├── AppState.swift             ← @Observable 全局状态
│       │   ├── GoalConfirmationStore.swift ← 共同目标确认状态管理
│       │   ├── FocusTimer.swift           ← 专注计时器（CGEvent）
│       │   ├── PetStore.swift             ← 宠物状态管理
│       │   ├── TreeStore.swift            ← 树状态管理
│       │   ├── SyncEngine.swift           ← 离线优先同步引擎
│       │   ├── TransitionStore.swift      ← 单身→情侣过渡状态管理
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

### 6.1 宠物渲染：分阶段动画方案

> 详细动画设计见《宠物互动效果设计》（~60 组独立动画，4 品种 × 10+ 场景）。
> 实现策略：先用带透明通道的 MP4/MOV 短片快速落地，后期可选 Spine 2D 骨骼动画优化。

#### 6.1.1 MVP 方案：Alpha MP4 视频精灵

```
// Views/PetView.swift
import SwiftUI
import AVFoundation

struct PetView: View {
    let breed: PetBreed
    let state: PetState
    @State private var player: AVPlayer?

    /// 动画文件命名规则：{breed}_{state}.mp4
    /// 示例：orangeCat_eating.mp4, tabbyCat_idle.mp4
    /// 所有视频带 Alpha 透明通道（HEVC with Alpha / Apple ProRes 4444）

    var body: some View {
        VideoPlayer(player: player)
            .frame(width: state.frameSize.width, height: state.frameSize.height)
            .onAppear { loadAnimation() }
            .onChange(of: state) { _, _ in loadAnimation() }
    }

    private func loadAnimation() {
        let name = "\(breed.rawValue)_\(state.rawValue)"
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else { return }
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.play()
        // 循环播放：注册 AVPlayerItemDidPlayToEndTime 通知后 seek(to: .zero)
    }
}

enum PetState: String {
    case idle, eating, producing, sleeping, wakingUp, runningOut,
         visiting, headPat, excited, concerned, celebrating

    var isLooping: Bool {
        switch self {
        case .idle, .sleeping: return true
        default: return false
        }
    }

    var frameSize: CGSize {
        switch self {
        case .idle, .sleeping: return CGSize(width: 80, height: 80)
        case .eating, .headPat, .excited: return CGSize(width: 100, height: 100)
        default: return CGSize(width: 80, height: 80)
        }
    }
}
```

#### 6.1.2 动画文件清单（按品种 × 场景）

| 场景 | 银渐层 | 布偶 | 泰迪 | 金毛 | 循环 | 时长 |
|:---|:---|:---|:---|:---|:---|:---|
| idle（待机呼吸） | orangeCat_idle | tabbyCat_idle | teddyDog_idle | goldenDog_idle | ✅ | — |
| idle_micro（待机小动作×6） | orangeCat_micro_01~06 | tabbyCat_micro_01~06 | teddyDog_micro_01~06 | goldenDog_micro_01~06 | — | 1.5s |
| headPat（摸摸头） | orangeCat_headPat | tabbyCat_headPat | teddyDog_headPat | goldenDog_headPat | — | 1.5-2s |
| eating（投喂咀嚼） | orangeCat_eating | tabbyCat_eating | teddyDog_eating | goldenDog_eating | — | 2-2.5s |
| producing（排泄肥料） | orangeCat_producing | tabbyCat_producing | teddyDog_producing | goldenDog_producing | — | 2-2.5s |
| wakingUp（每日启动） | orangeCat_wakingUp | tabbyCat_wakingUp | teddyDog_wakingUp | goldenDog_wakingUp | — | 2-3s |
| cookieEarned（饼干通知） | orangeCat_cookieEarned | tabbyCat_cookieEarned | teddyDog_cookieEarned | goldenDog_cookieEarned | — | 1.5-2s |
| fertilizerFull（肥料堆积提醒） | orangeCat_fertilizerFull | tabbyCat_fertilizerFull | teddyDog_fertilizerFull | goldenDog_fertilizerFull | — | 2-3s |
| stageUp（树阶段跃迁） | 5 阶段 × 4 品种 = 20 个文件 | — | 1-2s |
| visiting（串门进出） | sharedPet_leave + sharedPet_arrive（通用） | — | 3s×2 |
| sleeping（伴侣离线/休眠） | pet_sleepingToAwake（含灰色剪影→彩色过渡） | — | 4s |
| celebrating（结果期庆祝） | 全品种通用庆祝跳跃 + 绕树跑 | ✅ | 2s |

> 总计约 70 个 MP4 文件。每个文件 50-200KB，总资源包 < 15MB。

#### 6.1.3 粒子效果（独立于视频，代码实现）

```swift
// 粒子效果叠加在视频之上，SwiftUI 实现
struct ParticleOverlay: View {
    let type: ParticleType  // .hearts / .stars / .crumbs / .sparkles

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(x: particle.x, y: particle.y, width: 8, height: 8)
                context.draw(Image(systemName: particle.icon), in: rect)
            }
        }
        .onAppear { startParticleAnimation() }
    }
}
```

#### 6.1.4 后续优化方向（P2+）

* 当前 MP4 方案：快速落地，美术友好（小云雀直接出 MP4）。
* 挑战：无法实时混合品种差异（如"银渐层+节日帽子"），需每种组合预渲染。
* 可选升级：**Spine 2D 骨骼动画**，支持换装和动画混合，但开发成本高。
* 建议：MP4 方案 ≥ 1.0 上线后，根据用户反馈决定是否升级 Spine。

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

    // 注册（platform 由数据库默认值 'mac' 自动填入）
    func signUp(email: String, password: String) async throws -> User {
        try await supabase.auth.signUp(email: email, password: password)
        // users 表 platform 字段默认 'mac'，Windows 端需显式传 'windows'
    }

    // 登录
    func signIn(email: String, password: String) async throws -> Session {
        try await supabase.auth.signIn(email: email, password: password)
    }

    // 同步事件批量推送
    func pushSyncEvents(_ events: [SyncOperation]) async throws {
        try await supabase.from("sync_events").insert(events).execute()
    }

    // 生成配对码
    func generatePairingCode() async throws -> String {
        try await supabase.from("pairing_codes").insert([
            "user_id": supabase.auth.currentUser!.id,
            "expires_at": Date().addingTimeInterval(24 * 3600)
        ]).select("code").single().execute().value.code
    }

    // 输入配对码完成绑定
    func joinWithCode(_ code: String) async throws -> String {
        try await supabase.rpc("join_couple", params: ["code": code]).execute().value
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
| **P2 宠物** | Alpha MP4 视频精灵渲染 4 品种 × 10+ 场景动画（~70 文件），含待机/摸摸头/投喂/排泄/起床/提醒/跃迁/串门/状态变化 + 代码层粒子效果叠加 | 宠物在窗口中生动呈现，品种差异明显 | 拖拽饼干→品种专属咀嚼动画+粒子；单击→品种专属摸摸头；每 30s 随机微动作 |
| **P3 树** | 种子花盆横截面 → 6 阶段树，CAAnimation 过渡 | 拖拽肥料到树根 → 树长大 | 6 个阶段视觉完整 |
| **P4 认证** | Supabase Auth 邮箱注册/登录，platform 自动区分 Mac/Windows | 注册登录流程完整 | 注册→写 users 表（含 platform）→登录可查 |
| **P5 单身模式** | 目标设定 → 80% 时间倒推 → 结果期 → 海报 | 单人完整闭环 | 设目标→专注→成长→结果→海报 |
| **P6 情侣模式** | 单身→情侣过渡流程 + 配对码绑定 + 专属/共养宠物 + 串门 + 互动 | 情侣完整闭环（含过渡） | 过渡→配对→互喂→串门→共养→同步 |
| **P7 金句** | 内置 200 句，按场景/模式自动匹配 | 完成专注后树冠气泡显示 | 单身/情侣 solo/情侣 together 金句不同 |
| **P8 设置** | 设置窗口：宠物选择/金句频率/隐身模式/诊断 | 完整 Settings 窗口 | 所有设置可调且生效 |
| **P9 更新** | Sparkle 2 自动更新集成 | 版本检测 → 下载 → 安装 | 服务端放新版 → 客户端提示升级 |
| **P10 诊断** | 一键诊断报告 + 静默上报 | 右键菜单 → 导出 txt | 日志含状态+事件+错误+环境 |
| **P11 老铁模式** | 2-10 人组队 + 共享树 + 随机宠物串门 + 组内互动 | — | — |
| **P12 闺蜜模式** | 2-10 人组队 + 共享树 + 随机宠物串门 + 组内互动 | — | — |

### 10.0 多树并行模型

产品方案 §4.0 定义的多关系并行架构，技术要点：

```swift
// Stores/AppState.swift 核心状态
@Observable
final class AppState {
    var user: User
    var pet: Pet                      // 只有 1 只
    var cookies: Int = 0              // 全局饼干数
    var activeTrees: [Tree] = []      // 所有活跃的树
    var pinnedTreeIds: Set<UUID> = []  // 用户钉选的树 ID
    var visibleTrees: [Tree] {         // 窗口内实际显示的树（≤3 棵）
        let pinned = activeTrees.filter { pinnedTreeIds.contains($0.id) }
        let rest = activeTrees.filter { !pinnedTreeIds.contains($0.id) }
            .sorted { $0.daysUntilDeadline < $1.daysUntilDeadline }
        let auto = rest.prefix(3 - pinned.count)
        return Array(pinned + auto).prefix(3).map { $0 }
    }
    var relationships: [Relationship] = []  // 从 couples/teams 表推导
}

enum RelationshipType { case couple, buddy, sis }
struct Relationship: Identifiable {
    let id: UUID
    let type: RelationshipType
    let treeId: UUID
    let memberIds: [UUID]
    let memberNicknames: [UUID: String]
}
```

* 树显示（`TreeSwitcherView` + `TreeDetailPanel`）：
  - `activeTrees` 按截止日期排序，取前 3 棵（含钉选的树）渲染为缩略卡片。
  - `pinnedTreeIds: Set<UUID>` 记录用户手动钉选的树。
  - 超出 3 棵时末尾显示 `+N` 按钮 → 展开 `TreeDetailPanel`（Sheet/overlay）。
  - 树面板中支持拖拽排序和钉选/取消钉选。
* 饼干投喂：拖拽到当前树区域 → 仅影响选中树的肥料数。
* 宠物位置：固定在窗口右下角，不随树切换改变。
* 成员宠物渲染：切换树时，通过 `relationships` 找到对应成员 ID，渲染其宠物在树两侧。

### 10.1 建立恋爱关系过渡流程（P6 子任务）

产品方案 §4.3 定义的单身→情侣过渡，涉及以下技术要点：

```swift
// Stores/TransitionStore.swift
@Observable
final class TransitionStore {
    enum Phase {
        case idle                       // 未触发
        case confirming                 // 前置确认弹窗（告知树将封存）
        case codeGenerated(String)      // 已生成配对码，等待伴侣输入
        case binding                    // 伴侣已输入，正在绑定
        case migrating                  // 树封存/宠物转换中
        case setNickname                // 设置昵称（我的昵称 + 称呼Ta）
        case completed(NicknamePair)    // 昵称确认，进入仪式动画
    }

    var phase = Phase.idle
    var pairingCode: String?
    var myNickname = "主人"       // 默认值
    var partnerNickname = "宝宝"  // 默认值

    /// 发起过渡：封存当前树，生成配对码
    func startTransition(treeStore: TreeStore) async throws {
        phase = .confirming
        // 用户确认后：
        treeStore.archiveCurrentTree(reason: .startedRelationship)
        let code = try await SupabaseClient.shared.generatePairingCode()
        self.pairingCode = code
        phase = .codeGenerated(code)
    }

    /// 伴侣输入配对码后，完成绑定 → 进入昵称设置
    func onPartnerJoined() async throws {
        phase = .migrating
        // 宠物转换：单身宠物 → 专属宠物
        petStore.convertToPersonalPet()
        // 双方共选共养宠物（打开选择面板）
        phase = .setNickname
    }

    /// 确认昵称，写入服务端 + 本地
    func confirmNicknames(my: String, callPartner: String) async throws {
        myNickname = my
        partnerNickname = callPartner
        let pair = NicknamePair(myNickname: my, partnerNickname: callPartner)
        try await SupabaseClient.shared.saveNicknames(pair)
        phase = .completed(pair)
    }
}
```

```swift
// Views/TransitionFlowView.swift
struct TransitionFlowView: View {
    @Environment(AppState.self) var appState
    @State private var transitionStore = TransitionStore()

    var body: some View {
        switch transitionStore.phase {
        case .confirming:
            ConfirmationDialog(store: transitionStore)
        case .codeGenerated(let code):
            ShareCodeView(code: code)
        case .binding:
            ProgressView("正在连接...")
        case .migrating:
            MigrationAnimationView()
        case .setNickname:
            NicknameSetupView(store: transitionStore)  // §4.4.6
        case .completed(let pair):
            // 花瓣汇合动画，文案使用昵称
            PetalMergeAnimation(myName: pair.myNickname, partnerName: pair.partnerNickname) {
                appState.mode = .couple
                appState.myNickname = pair.myNickname
                appState.partnerNickname = pair.partnerNickname
            }
        case .idle:
            EmptyView()
        }
    }
}
```

* 入口：`SettingsView` 中单身用户可见的「开启情侣模式」按钮
* 树封存：`TreeStore.archiveCurrentTree(reason:)` 写入 GRDB，标记 `archived_reason = "started_relationship"`
* 宠物转换：`PetStore.convertToPersonalPet()` 清空饼干/肥料计数，标记 `role = .personal`
* 花瓣动画：两片 `Image` + `offset` 动画，约 3 秒（非阻塞式 overlay）
* 昵称模型（`Models/Nickname.swift`）：

```swift
struct NicknamePair: Codable {
    var myNickname: String      // 我的昵称，默认 "主人"
                                // 单身：宠物用此称呼（如 "主人，来摸摸头吧！"）
                                // 情侣：伴侣界面中显示此称呼
    var partnerNickname: String // 称呼 Ta，默认 "宝宝"，仅情侣模式使用
                                // 本方界面中替代所有 "Ta" 的文案
    // 限制 2-8 中文字符或 4-16 英文字符
}
```

* 昵称存储：
  - 本地 GRDB `user` 表：`my_nickname` 列（单身 & 情侣通用）；`partner_nickname` 列（情侣模式专属，单身模式为 NULL）
  - 服务端 `couples` 表：`nickname_a` / `nickname_b` / `callname_a` / `callname_b`（情侣模式专属）
* 单身模式下的昵称不涉及服务端同步，纯本地存储即可
* 情侣模式下昵称修改后通过 SSE 推送同步到对方客户端，`AppState.partnerNickname` 实时更新
* `SettingsView` 昵称入口：
  - 单身模式：「我的昵称」→ 编辑 `myNickname`
  - 情侣模式：「编辑昵称」→ 编辑 `myNickname` + `partnerNickname`（调用同一 `NicknameSetupView`）
* `PetView` 在单身模式下读取 `AppState.myNickname` 用于对话气泡和摸摸头互动文案

### 10.2 个人小目标与共同目标确认

产品方案 §5.0/§5.6 定义的两层目标体系，技术要点：

```swift
// Models/MiniGoal.swift
struct MiniGoal: Codable {
    var description: String       // "每天背50个单词"
    var unit: String?             // "次" / "天" / "元" / nil（纯文字）
    var target: Int?              // 目标值
    var current: Int = 0          // 当前进度
    var completedAt: Date?        // 达成时间

    var progress: Double {        // 0.0 - 1.0
        guard let target, target > 0 else { return 0 }
        return min(1.0, Double(current) / Double(target))
    }
}
```

* 存储：仅本地 GRDB，不上传服务端。`user` 表无此列，换设备需手动迁移。
* UI：`MiniGoalView` 为宠物身边的便签纸片，悬停展开编辑，点击 `+1` 按钮累进。

```swift
// Stores/GoalConfirmationStore.swift
@Observable
final class GoalConfirmationStore {
    enum Status { case pending, confirmed, rejected }

    var members: [String: Status] = [:]  // userID → 确认状态
    var allConfirmed: Bool { members.values.allSatisfy { $0 == .confirmed } }

    func propose(goal: Goal, to memberIds: [String]) { /* 推送确认弹窗 */ }
    func confirm(userId: String) { /* 标记已确认，全员确认后激活树 */ }
    func suggestChange(userId: String, suggestion: String) { /* 发回发起人 */ }
}
```

* 共同目标确认弹窗通过 SSE 推送到各成员客户端。
* 确认状态显示在树冠气泡区域旁（🟢 全体确认 / 🟡 N 人待确认）。

### 10.3 老铁/闺蜜模式（P11/P12）

产品方案 §4.5/§4.6 定义的老铁/闺蜜模式，当前进入开发阶段。架构设计如下：

#### 10.3.1 数据模型

* `teams` 表已在 Supabase 建好（`id, name, mode, member_ids[], tree_id, goal_confirmed_by[], disbanded_at`）
* `mode` 枚举：`buddy` / `sis`
* 最大成员数 10，由客户端校验（`member_ids` 数组长度 ≤ 10）
* 当前 `couples` 的 `user_a/user_b` 结构不兼容多对多，队伍场景使用 `teams` 表独立管理

#### 10.3.2 宠物串门机制（随机惊喜，全自动）

> 产品方案 §4.5.3/§4.6.3 定义。无共养宠物，但专属宠物会**随机自动串门**，无需手动触发。

**触发逻辑**（客户端本地判断 + SSE 广播）：

```swift
// Stores/RandomVisitEngine.swift（P11 新文件）
@Observable
final class RandomVisitEngine {
    /// 检查是否满足随机串门条件
    func shouldTriggerVisit(for team: Team) -> Bool {
        // 1. 队伍中至少 2 人在线且活跃（过去 30 分钟有专注行为）
        // 2. 距离上次串门 > 2 小时（冷却期）
        // 3. 随机概率：满足条件后 ~30% 概率触发
        // 4. 选中宠物当天串门次数 < 3
    }

    /// 随机选中一只宠物 + 随机选中一名接收成员
    func pickRandomVisit(team: Team) -> (ownerId: String, targetId: String, breed: PetBreed)?

    /// 执行串门：我的宠物走出去 → SSE 通知目标 → 目标屏幕渲染到访宠物
    func dispatchVisit(from ownerId: String, to targetId: String, pet: Pet)
}
```

**串门生命周期**：
1. **随机决策**：客户端每 30 分钟检查一次条件，满足则触发
2. **离开动画**：宠物从发起方屏幕边缘走出（`visiting_leave.mp4`，~2s）
3. **SSE 推送**：`pet_visit_start` 事件（含 petId, breed, ownerName）
4. **到达动画**：宠物从接收方屏幕边缘走入（`visiting_arrive.mp4`，~2s）+ 气泡
5. **停留交互**：接收方可摸摸头/投喂（肥料计入共享树 + 伴手礼返还主人）
6. **自动回家**：10-30 分钟后触发 `pet_visit_end`，宠物自动跑回

```swift
// Models/PetVisit.swift（P11 实现）
struct PetVisit: Codable {
    let id: String
    let petId: String
    let fromUserId: String
    let toUserId: String
    let teamId: String
    let arrivedAt: Date
    let expiresAt: Date        // 随机 10-30 分钟后自动回家
    var dailyVisitCount: Int   // ≤ 3
    let isRandom: Bool = true  // 标记为随机串门
}
```

**同步方式**：
* 串门开始 → SSE 推送 `pet_visit_start` 到目标用户
* 目标用户离线 → 事件写入 `sync_events`，上线后批量回放
* 串门回家 → SSE 推送 `pet_visit_end`

**技术要点**：
* Alpha MP4 动画复用情侣串门的 `visiting_leave` / `visiting_arrive`
* 串门宠物渲染复用 `PetView`，`role` 标记为 `.visiting(fromUserId:)`
* 投喂肥料分配（1 归树 + 1 伴手礼）通过 `sync_events.payload` 区分

#### 10.3.3 交互模型

* 组内成员用统一的 `{sender}` 变量代替情侣的 `{callTa}/{opposite.myName}`
* 互动面板复用情侣模式的扇形菜单，动作映射：
  - 「送爱心」→「拍肩膀」（老铁）/「送小花」（闺蜜）
  - 「送吻」→「喊一嗓子」（组内喇叭）
  - 「摸摸头」→「替 Ta 喂宠物」
* 组内喇叭通过 SSE 的 `group_broadcast` 事件广播，每人每天限 3 次，客户端本地计数

#### 10.3.4 UI 组件规划

* `TeamSetupView`：创建/加入队伍流程（复用 `TransitionFlowView` 的配对码 UI）
* `TeamMemberList`：成员列表（头像 + 宠物品种 + 昵称）
* `PetVisitNotification`：串门到达/离开的浮动通知条
* 树冠气泡：复用 `TreeLabelBubble`，`QuoteService` 已预留 `group_buddy` / `group_sis` 分类键

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

已部署线上版：`https://edison-tom.github.io/yoho/`（密码保护）。
- 核心指标：注册/日活/付费/收入/下载 + Mac/Win 平台区分
- 模式分布：单身/情侣/老铁/闺蜜 + 活跃对数/队伍/配对
- 付费搜索 + 用户管理（编辑用户名/宠物/模式/昵称）
- API: Edge Function `admin`，使用 `admin_stats` SQL 视图

## 十四、开发排障记录

### 14.1 "卡通鼠标"问题（2026-07-04）

**现象**：编译运行 Yoho 后，屏幕中央出现一个无法消失的卡通鼠标图标。

**排查过程**：
1. `pkill -9 Yoho` 杀掉 Yoho，鼠标仍然存在 → 排除 Yoho 自身
2. `ps aux | grep -i "SkyComputerUse\|Software Cursor"` 发现 4 个相关进程：
   - `SkyComputerUseService`（PID 8387）
   - 3 个 `SkyComputerUseClient` 实例
3. 确认根因：这是 **Codex Computer Use 插件的软件光标覆盖层**，位于屏幕坐标 (1197, 395)，与 Yoho 完全无关。
4. 该进程由 Codex app 管理，不能直接 kill（会自动重启）。

**解决方案**：在 Codex 设置中关闭 Computer Use 插件的"软件光标"功能。

**经验教训**：
- Yoho 窗口透明 + 浮窗效果使得桌面上的任何异常元素都很显眼
- 排查问题时应先 `pkill` 确认是否与 Yoho 相关
- Computer Use 插件的软件光标是常见干扰源

### 14.2 "菜单栏不知名图标"问题（2026-07-04）

**现象**：用户报告菜单栏有一个不明图标。

**排查过程**：
1. 确认 Yoho 已退出 → 图标不可能来自 Yoho
2. 检查 Yoho 的 `MenuBarExtra` 代码：仅显示文字 "Yoho" + "退出" 按钮，图标很小且可识别
3. 结论：该图标来自其他应用或系统服务，需用户自行辨认

**Yoho MenuBarExtra 代码**（`Sources/Yoho/App/YohoApp.swift`）：
```swift
MenuBarExtra("Yoho") {
    Button("退出") {
        NSApplication.shared.terminate(nil)
    }
}
```

### 14.3 窗口透明背景不生效（2026-07-04）

**修复**：`FloatingWindowView.swift` 中移除白色 `RoundedRectangle` 背景，确保窗口真正透明，宠物/树内容直接浮于桌面。

### 14.4 App 退出问题（2026-07-04）

**修复**：`AppDelegate.swift` 中 `applicationShouldTerminateAfterLastWindowClosed` 设为 `false`，防止窗口关闭后 App 整个退出。

### 14.5 透明窗口 5 秒后自动淡出（2026-07-04）

**修复**：`FloatingWindowView.swift` 中添加 `.opacity` + `withAnimation`，实现 5 秒空闲后窗口淡出、鼠标移动时重新出现。

### 14.6 宠物渲染方案决策（2026-07-04）

**决策**：MVP 阶段使用 Lottie（Airbnb 开源）加载 JSON 动画，后续替换为带 alpha 通道的 MP4 视频以获得更好的表现力。

**影响**：
- Package.swift 依赖 `airbnb/lottie-ios`
- `PetView.swift` 内部动画状态枚举已预留 `lottie` / `mp4` 两种模式
- 美术资源需同时准备 Lottie JSON（MVP）和透明通道 MP4（后续）
