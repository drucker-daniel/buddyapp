import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Push Notifications", systemImage: "bell.badge")
                    Spacer()
                    notificationStatusBadge
                }
            } footer: {
                Text(footerText)
            }

            if permissionStatus == .denied {
                Section {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundStyle(.accent)
                }
            }

            Section("You'll be notified about") {
                Label("New events in your groups", systemImage: "calendar.badge.plus")
                Label("Group invitations", systemImage: "envelope.badge")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            permissionStatus = settings.authorizationStatus
        }
    }

    @ViewBuilder
    private var notificationStatusBadge: some View {
        switch permissionStatus {
        case .authorized:
            Label("On", systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.green)
                .labelStyle(.titleAndIcon)
        case .denied:
            Label("Off", systemImage: "xmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.red)
                .labelStyle(.titleAndIcon)
        default:
            Text("Unknown")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var footerText: String {
        switch permissionStatus {
        case .authorized:
            return "You'll receive push notifications for events and invites."
        case .denied:
            return "Notifications are disabled. Enable them in Settings to stay up to date."
        default:
            return "Notification status could not be determined."
        }
    }
}
