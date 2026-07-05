import Foundation

enum DiagnosticReport {
    static func generate() -> String {
        var lines: [String] = []
        let now = Date()

        lines.append("=== Yoho 诊断报告 ===")
        lines.append("生成时间: \(now.ISO8601Format())")
        lines.append("")

        // 系统信息
        let processInfo = ProcessInfo.processInfo
        lines.append("【系统信息】")
        lines.append("macOS: \(processInfo.operatingSystemVersionString)")
        lines.append("主机名: \(processInfo.hostName)")
        lines.append("处理器数: \(processInfo.processorCount)")
        lines.append("物理内存: \(processInfo.physicalMemory / 1024 / 1024) MB")
        lines.append("")

        // App 信息
        lines.append("【App 信息】")
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            lines.append("版本: \(version)")
        }
        lines.append("运行时长: \(String(format: "%.0f", processInfo.systemUptime)) 秒(系统)")
        lines.append("")

        // Supabase
        lines.append("【Supabase 状态】")
        if let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String {
            lines.append("URL: \(url)")
        } else {
            lines.append("URL: 未配置")
        }
        lines.append("")

        // 空闲检测
        lines.append("【空闲检测】")
        let idleSec = IdleDetector.secondsSinceLastInput()
        lines.append("距上次输入: \(String(format: "%.0f", idleSec)) 秒")
        lines.append("用户活跃: \(IdleDetector.isUserActive ? "是" : "否")")
        lines.append("")

        // 文件大小
        lines.append("【资源文件】")
        lines.append("报告生成时间: \(now.formatted())")

        return lines.joined(separator: "\n")
    }
}
