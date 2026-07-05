import SwiftUI

struct TeamFlowView: View {
    @Environment(AppState.self) var appState
    @Environment(\.dismiss) private var dismiss

    @State private var step: TeamStep = .chooseMode
    @State private var teamName = ""
    @State private var selectedMode: Team.TeamMode = .buddy
    @State private var inviteCode = ""
    @State private var isCreating = true
    @State private var errorMessage: String?
    @State private var createdTeam: Team?

    enum TeamStep {
        case chooseMode      // 选择创建/加入 + 模式
        case createTeam      // 输入队伍名称
        case showCode        // 显示邀请码
        case joinTeam        // 输入邀请码
        case done            // 完成
    }

    var body: some View {
        VStack(spacing: 16) {
            switch step {
            case .chooseMode:
                chooseModeView
            case .createTeam:
                createTeamView
            case .showCode:
                showCodeView
            case .joinTeam:
                joinTeamView
            case .done:
                doneView
            }

            if let error = errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
        .frame(width: 260, height: 300)
        .padding()
    }

    // MARK: - 步骤视图

    private var chooseModeView: some View {
        VStack(spacing: 16) {
            Text(isCreating ? "创建队伍" : "加入队伍")
                .font(.headline)

            Picker("模式", selection: $selectedMode) {
                ForEach(Team.TeamMode.allCases, id: \.self) { mode in
                    Text("\(mode.emoji) \(mode.label)").tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Toggle(isCreating ? "创建新队伍" : "加入已有队伍", isOn: $isCreating.animation())
                .font(.caption)

            HStack(spacing: 12) {
                Button("取消") { dismiss() }.buttonStyle(.plain)
                Button("下一步") {
                    if isCreating { step = .createTeam }
                    else { step = .joinTeam }
                }
                .buttonStyle(.borderedProminent)
                .tint(selectedMode == .buddy ? .blue : .pink)
            }
        }
    }

    private var createTeamView: some View {
        VStack(spacing: 12) {
            Text("\(selectedMode.emoji) 创建\(selectedMode.label)队伍")
                .font(.headline)

            TextField("队伍名称", text: $teamName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)

            HStack(spacing: 12) {
                Button("上一步") { step = .chooseMode }.buttonStyle(.plain)
                Button("创建") {
                    guard !teamName.isEmpty else {
                        errorMessage = "请输入队伍名称"
                        return
                    }
                    let team = appState.teamStore.createTeam(
                        name: teamName,
                        mode: selectedMode,
                        creatorId: appState.myNickname
                    )
                    createdTeam = team
                    // 同时创建队伍共享树
                    let goal = Goal(
                        id: UUID().uuidString,
                        title: "\(team.name)的目标",
                        goalType: .custom,
                        targetDate: Date().addingTimeInterval(86400 * 30),
                        targetAmount: nil, targetUnit: nil, createdAt: Date()
                    )
                    appState.treeStore.plantTree(
                        name: "\(selectedMode.emoji) \(team.name)",
                        goal: goal,
                        relationshipType: selectedMode == .buddy ? .buddy : .sis,
                        teamId: team.id
                    )
                    if let treeId = appState.treeStore.allTrees.last?.id {
                        appState.teamStore.bindTree(treeId)
                    }
                    appState.activeRelationships.append(
                        selectedMode == .buddy ? .buddy : .sis
                    )
                    appState.teamIds.append(team.id)
                    step = .showCode
                }
                .buttonStyle(.borderedProminent)
                .tint(selectedMode == .buddy ? .blue : .pink)
                .disabled(teamName.isEmpty)
            }
        }
    }

    private var showCodeView: some View {
        VStack(spacing: 12) {
            Text("\(selectedMode.emoji) 队伍已创建！")
                .font(.headline)

            Text("邀请码")
                .font(.caption).foregroundStyle(.secondary)

            Text(createdTeam?.inviteCode ?? "------")
                .font(.system(size: 32, design: .monospaced))
                .fontWeight(.bold)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

            Text("分享此码给队友，3-5人组队")
                .font(.caption).foregroundStyle(.secondary)

            Button("完成") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(selectedMode == .buddy ? .blue : .pink)
        }
    }

    private var joinTeamView: some View {
        VStack(spacing: 12) {
            Text("\(selectedMode.emoji) 加入\(selectedMode.label)队伍")
                .font(.headline)

            TextField("输入6位邀请码", text: $inviteCode)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .font(.system(.body, design: .monospaced))

            HStack(spacing: 12) {
                Button("上一步") { step = .chooseMode }.buttonStyle(.plain)
                Button("加入") {
                    guard inviteCode.count == 6 else {
                        errorMessage = "邀请码为6位"
                        return
                    }
                    if let team = appState.teamStore.joinTeam(
                        withCode: inviteCode.uppercased(),
                        userId: appState.myNickname
                    ) {
                        createdTeam = team
                        appState.activeRelationships.append(
                            selectedMode == .buddy ? .buddy : .sis
                        )
                        appState.teamIds.append(team.id)
                        step = .done
                    } else {
                        errorMessage = "邀请码无效或队伍已满"
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(selectedMode == .buddy ? .blue : .pink)
                .disabled(inviteCode.count != 6)
            }
        }
    }

    private var doneView: some View {
        VStack(spacing: 12) {
            Text("\(selectedMode.emoji)").font(.system(size: 36))
            Text("加入成功！")
                .font(.headline)
            Text(createdTeam?.name ?? "")
                .font(.body)
            Text("和\(createdTeam?.memberCount ?? 1)位队友一起加油")
                .font(.caption).foregroundStyle(.secondary)
            Button("完成") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(selectedMode == .buddy ? .blue : .pink)
        }
    }
}
