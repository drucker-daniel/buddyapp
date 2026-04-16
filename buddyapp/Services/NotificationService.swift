import Foundation
import UserNotifications
import FirebaseMessaging
import UIKit

@Observable
final class NotificationService: NSObject {
    var pendingDeepLink: DeepLink?

    enum DeepLink: Equatable {
        case event(groupID: String, eventID: String)
        case invite(inviteID: String)
        case group(groupID: String)
    }

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    func handleNotificationUserInfo(_ userInfo: [AnyHashable: Any]) {
        if let eventID = userInfo["eventID"] as? String,
           let groupID = userInfo["groupID"] as? String {
            pendingDeepLink = .event(groupID: groupID, eventID: eventID)
        } else if let inviteID = userInfo["inviteID"] as? String {
            pendingDeepLink = .invite(inviteID: inviteID)
        } else if let groupID = userInfo["groupID"] as? String {
            pendingDeepLink = .group(groupID: groupID)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        return [.banner, .badge, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse) async {
        handleNotificationUserInfo(response.notification.request.content.userInfo)
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        NotificationCenter.default.post(
            name: Notification.Name("FCMTokenRefreshed"),
            object: token
        )
    }
}
