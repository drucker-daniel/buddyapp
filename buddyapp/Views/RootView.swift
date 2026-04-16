import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var authService
    @Environment(NotificationService.self) private var notificationService

    var body: some View {
        SwiftUI.Group {
            if authService.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                AuthFlowView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
    }
}
