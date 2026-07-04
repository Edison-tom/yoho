import SwiftUI

@MainActor
@Observable
final class AppState {
    var mode: User.Mode = .single
    var isFirstLaunch = true

    // 子系统
    var focusTimer = FocusTimer()
    var petStore = PetStore()
    var treeStore = TreeStore()
}
