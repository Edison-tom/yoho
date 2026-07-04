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
| **P2 宠物** | Lottie 加载 4 种默认宠物，idle/eating 动画 | 宠物在窗口中动起来 | 点击拖拽饼干到宠物 → 咀嚼动画 |
| **P3 树** | 种子花盆横截面 → 6 阶段树，CAAnimation 过渡 | 拖拽肥料到树根 → 树长大 | 6 个阶段视觉完整 |
| **P4 认证** | Supabase Auth 邮箱注册/登录 | 注册登录流程完整 | 注册→写 users 表→登录可查 |
| **P5 单身模式** | 目标设定 → 80% 时间倒推 → 结果期 → 海报 | 单人完整闭环 | 设目标→专注→成长→结果→海报 |
| **P6 情侣模式** | 单身→情侣过渡流程 + 配对码绑定 + 专属/共养宠物 + 串门 + 互动 | 情侣完整闭环（含过渡） | 过渡→配对→互喂→串门→共养→同步 |
| **P7 金句** | 内置 200 句，按场景/模式自动匹配 | 完成专注后树冠气泡显示 | 单身/情侣 solo/情侣 together 金句不同 |
| **P8 设置** | 设置窗口：宠物选择/金句频率/隐身模式/诊断 | 完整 Settings 窗口 | 所有设置可调且生效 |
| **P9 更新** | Sparkle 2 自动更新集成 | 版本检测 → 下载 → 安装 | 服务端放新版 → 客户端提示升级 |
| **P10 诊断** | 一键诊断报告 + 静默上报 | 右键菜单 → 导出 txt | 日志含状态+事件+错误+环境 |
| **P11 老铁模式** | 3-5 人组队 + 共享树 + 组内互动（暂不开发） | — | — |
| **P12 闺蜜模式** | 3-5 人组队 + 共享树 + 组内互动（暂不开发） | — | — |

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

### 10.3 老铁/闺蜜模式技术预留（P11/P12，暂不开发）

产品方案 §4.5/§4.6 定义的老铁/闺蜜模式，当前标记「暂不开发」。但架构上做了最低限度的预留：

* 数据模型：`couples` 表可扩展为 `teams` 表（`id, name, mode, member_ids[], tree_id, created_at`）。当前 `couples` 的 `user_a/user_b` 结构不兼容多对多，届时需迁移。
* 交互模型：组内成员用统一的 `{sender}` 变量代替情侣的 `{callTa}/{opposite.myName}`，避免每人一套昵称的复杂度。
* 宠物：每人一只专属宠物（复用现有 Pet 模型），无共养宠物，简化实现。
* UI：组内互动面板可复用情侣模式的扇形菜单，将「送爱心」「送吻」替换为「拍肩膀」「送小花」等组专属动作。
* 金句：在现有 `QuoteService` 中预留 `group_buddy` / `group_sis` 两个分类键。

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
