import SwiftUI

struct FloatingWindowView: View {
    @Environment(AppState.self) var appState
    @State private var showBreedPicker = false
    @State private var showPlantSheet = false
    @State private var showPoster = false
    @State private var showSettings = false
    @State private var showForest = false
    @State private var showMemories = false
    @State private var showTransition = false
    @State private var showTeam = false
    @State private var goalTitle = ""
    @State private var goalDate = Date().addingTimeInterval(86400 * 30)

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                // HUD + 多树切换
                HStack {
                    TreeSwitcherView()
                    Spacer()
                    CookieFertilizerHUD(
                        cookieCount: appState.focusTimer.cookies,
                        fertilizerCount: appState.petStore.fertilizerCount
                    )
                }
                .padding(.top, 6)
                .padding(.horizontal, 4)

                // 宠物
                PetView(
                    breed: appState.petStore.pet.breed,
                    state: appState.petStore.pet.state,
                    name: appState.petStore.pet.name,
                    cookieCount: appState.focusTimer.cookies,
                    onFeed: {
                        guard appState.focusTimer.cookies > 0 else { return }
                        appState.focusTimer.consumeCookie()
                        appState.petStore.feed()
                    },
                    onPet: { appState.petStore.petPet() },
                    onLongPress: { showBreedPicker = true }
                )

                Spacer()

                // 树区域
                if let tree = appState.treeStore.currentTree {
                    TreeView(tree: tree, isDragTarget: appState.petStore.fertilizerCount > 0)
                        .dropDestination(for: String.self) { items, _ in
                            guard items.contains("fertilizer"),
                                  appState.petStore.fertilizerCount > 0 else { return false }
                            if appState.treeStore.applyFertilizer() {
                                appState.petStore.fertilizerCount -= 1
                                appState.petStore.pendingFertilizerCount -= 1
                                if appState.treeStore.currentTree?.stage == .fruiting {
                                    showPoster = true
                                }
                            }
                            return true
                        }
                    Spacer()
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                        Button("种一棵树") { showPlantSheet = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.yohoGreen)
                            .controlSize(.small)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }

                // 金句
                if let quote = appState.currentQuote {
                    Text("「\(quote)」")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.opacity)
                }

                // 底部工具栏
                bottomBar
            }
            .padding(.horizontal, 12)
        }
        .frame(width: Constants.windowWidth, height: Constants.windowHeight)
        .sheet(isPresented: $showBreedPicker) {
            BreedPickerView(
                currentBreed: appState.petStore.pet.breed,
                onSelect: { breed in
                    appState.petStore.pet.breed = breed
                    showBreedPicker = false
                }
            )
        }
        .sheet(isPresented: $showPlantSheet) { plantSheet }
        .sheet(isPresented: $showPoster) {
            if let tree = appState.treeStore.currentTree {
                PosterView(
                    tree: tree,
                    todayMinutes: appState.focusTimer.todayMinutes,
                    petName: appState.petStore.pet.name,
                    petBreed: appState.petStore.pet.breed
                )
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showForest) { ForestArchiveView() }
        .sheet(isPresented: $showMemories) { MemoryCapsuleView() }
        .sheet(isPresented: $showTransition) { TransitionFlowView() }
        .sheet(isPresented: $showTeam) { TeamFlowView() }
    }

    private var bottomBar: some View {
        HStack(spacing: 6) {
            MiniGoalView()
            Spacer()

            // 队伍入口
            if appState.hasTeams {
                if let mode = appState.teamInteractionMode {
                    InteractionMenu(mode: mode) { _ in }
                }
                Text("\(appState.teamStore.currentTeam?.memberCount ?? 1)/5")
                    .font(.system(size: 9)).foregroundStyle(.secondary)
            } else if appState.isInCouple {
                InteractionMenu(mode: .couple) { _ in }
            } else {
                // 组队入口
                Button("👊👯") { showTeam = true }
                    .buttonStyle(.plain).font(.system(size: 11))
                // 情侣入口
                Button("💑") { showTransition = true }
                    .buttonStyle(.plain).font(.system(size: 11))
            }

            Button("🌲") { showForest = true }
                .buttonStyle(.plain).font(.system(size: 11))
            Button("💊") { showMemories = true }
                .buttonStyle(.plain).font(.system(size: 11))
            Button("⚙️") { showSettings = true }
                .buttonStyle(.plain).font(.system(size: 11))

            HStack(spacing: 2) {
                Image(systemName: "timer").font(.system(size: 9))
                Text("\(appState.focusTimer.todayMinutes)分")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private var plantSheet: some View {
        VStack(spacing: 12) {
            Text("设定目标").font(.headline)
            TextField("目标名称（如：考研上岸）", text: $goalTitle)
                .textFieldStyle(.roundedBorder).frame(width: 200)
            DatePicker("截止日期", selection: $goalDate, displayedComponents: .date)
                .datePickerStyle(.compact).frame(width: 200)
            HStack(spacing: 16) {
                Button("取消") { showPlantSheet = false }.buttonStyle(.plain)
                Button("开始种植") {
                    let treeRelationship: Tree.RelationshipType = {
                        if appState.isInCouple { return .couple }
                        if appState.isInBuddyTeam { return .buddy }
                        if appState.isInSisTeam { return .sis }
                        return .personal
                    }()
                    let goal = Goal(
                        id: UUID().uuidString,
                        title: goalTitle.isEmpty ? "我的目标" : goalTitle,
                        goalType: .custom,
                        targetDate: goalDate,
                        targetAmount: nil, targetUnit: nil, createdAt: Date()
                    )
                    appState.treeStore.plantTree(
                        name: goalTitle.isEmpty ? "我的目标" : goalTitle,
                        goal: goal,
                        relationshipType: treeRelationship,
                        coupleId: nil,
                        teamId: appState.teamStore.currentTeam?.id
                    )
                    showPlantSheet = false
                }
                .buttonStyle(.borderedProminent).tint(.yohoGreen)
                .disabled(goalTitle.isEmpty)
            }
        }
        .frame(width: 240, height: 200).padding()
    }
}

struct BreedPickerView: View {
    let currentBreed: PetBreed
    let onSelect: (PetBreed) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text("选择你的宠物").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PetBreed.allCases, id: \.self) { breed in
                    VStack(spacing: 6) {
                        PetAnimationView(breed: breed, state: .idle).frame(width: 60, height: 60)
                        Text(breed.rawValue).font(.caption)
                        if breed == currentBreed {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(breed == currentBreed ? Color.yohoGreen.opacity(0.15) : Color.secondary.opacity(0.05)))
                    .onTapGesture { onSelect(breed) }
                }
            }
            .padding(.horizontal)
            Button("取消") { dismiss() }.buttonStyle(.plain).foregroundStyle(.secondary)
        }
        .frame(width: 240, height: 260)
    }
}
