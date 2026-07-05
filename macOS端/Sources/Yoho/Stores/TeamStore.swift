import Foundation

@MainActor
@Observable
final class TeamStore {
    var teams: [Team] = []
    var currentTeam: Team?

    /// 创建新队伍
    func createTeam(name: String, mode: Team.TeamMode, creatorId: String) -> Team {
        let code = Team.generateInviteCode()
        let team = Team(
            id: UUID().uuidString,
            name: name,
            mode: mode,
            memberIds: [creatorId],
            treeId: nil,
            createdAt: Date(),
            inviteCode: code
        )
        teams.append(team)
        currentTeam = team
        return team
    }

    /// 通过邀请码加入
    func joinTeam(withCode code: String, userId: String) -> Team? {
        guard var team = teams.first(where: { $0.inviteCode == code }),
              team.canInvite,
              !team.memberIds.contains(userId) else { return nil }
        team.memberIds.append(userId)
        if let idx = teams.firstIndex(where: { $0.id == team.id }) {
            teams[idx] = team
        }
        currentTeam = team
        return team
    }

    /// 绑定树到队伍
    func bindTree(_ treeId: String) {
        guard var team = currentTeam else { return }
        team.treeId = treeId
        if let idx = teams.firstIndex(where: { $0.id == team.id }) {
            teams[idx] = team
        }
        currentTeam = team
    }

    /// 离开队伍
    func leaveTeam(_ teamId: String, userId: String) {
        guard var team = teams.first(where: { $0.id == teamId }) else { return }
        team.memberIds.removeAll { $0 == userId }
        if team.memberIds.isEmpty {
            teams.removeAll { $0.id == teamId }
            if currentTeam?.id == teamId { currentTeam = nil }
        } else {
            if let idx = teams.firstIndex(where: { $0.id == team.id }) {
                teams[idx] = team
            }
        }
    }

    /// 获取当前队伍的互动模式
    var interactionMode: InteractionMenu.InteractionMode? {
        guard let team = currentTeam else { return nil }
        switch team.mode {
        case .buddy: return .buddy
        case .sis: return .sis
        }
    }
}
