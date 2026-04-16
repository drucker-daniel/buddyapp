import SwiftUI
import FirebaseCore
import FirebaseMessaging

@main
struct BuddyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appDelegate.authService)
                .environment(appDelegate.notificationService)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    let authService: AuthService
    let notificationService: NotificationService

    override init() {
        FirebaseApp.configure()
        authService = AuthService()
        notificationService = NotificationService()
        super.init()
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Messaging.messaging().delegate = notificationService
        UNUserNotificationCenter.current().delegate = notificationService

        NotificationCenter.default.addObserver(
            forName: Notification.Name("FCMTokenRefreshed"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let token = notification.object as? String else { return }
            Task { await self?.authService.updateFCMToken(token) }
        }

        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for notifications: \(error)")
    }
}
