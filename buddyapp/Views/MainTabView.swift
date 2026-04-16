import SwiftUI

struct MainTabView: View {
    @Environment(AuthService.self) private var authService
    @Environment(NotificationService.self) private var notificationService

    @State private var selectedTab = 0
    @State private var groupsViewModel = GroupsViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            GroupsTabView(viewModel: groupsViewModel)
                .tabItem {
                    Label("Groups", systemImage: "person.3")
                }
                .badge(groupsViewModel.pendingInviteCount > 0 ? groupsViewModel.pendingInviteCount : 0)
                .tag(0)

            EventsTabView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
        .tint(.accent)
        .task {
            // Register for notifications
            await notificationService.requestPermission()

            // Load user's groups & listen for invites
            await syncGroupsState(for: authService.currentUser)
        }
        .onChange(of: authService.currentUser?.id) { _, _ in
            Task {
                await syncGroupsState(for: authService.currentUser)
            }
        }
        .onChange(of: notificationService.pendingDeepLink) { _, deepLink in
            guard let deepLink else { return }
            handleDeepLink(deepLink)
            notificationService.pendingDeepLink = nil
        }
        .onDisappear {
            groupsViewModel.stopListening()
        }
    }

    private func handleDeepLink(_ link: NotificationService.DeepLink) {
        switch link {
        case .event:
            selectedTab = 1
        case .invite, .group:
            selectedTab = 0
        }
    }

    private func syncGroupsState(for user: AppUser?) async {
        guard let user else {
            groupsViewModel.myGroups = []
            groupsViewModel.pendingInvites = []
            groupsViewModel.stopListening()
            return
        }

        await groupsViewModel.loadMyGroups(groupIDs: user.groupIDs)

        if let uid = user.id {
            groupsViewModel.listenToPendingInvites(userID: uid)
        }
    }
}
