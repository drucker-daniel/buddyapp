import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
final class AuthService {
    var currentUser: AppUser?
    var firebaseUser: FirebaseAuth.User?
    var isLoading = false

    private let db = Firestore.firestore()
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenToAuthState()
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var isAuthenticated: Bool { firebaseUser != nil }

    private func listenToAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.firebaseUser = user
            if let user {
                Task { await self?.fetchCurrentUser(uid: user.uid) }
            } else {
                self?.currentUser = nil
            }
        }
    }

    private func fetchCurrentUser(uid: String) async {
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            currentUser = try doc.data(as: AppUser.self)
        } catch {
            print("Error fetching current user: \(error)")
        }
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = result.user.uid

        let user = AppUser(id: uid, email: email, displayName: displayName)
        try db.collection("users").document(uid).setData(from: user)

        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func updateFCMToken(_ token: String) async {
        guard let uid = firebaseUser?.uid else { return }
        do {
            try await db.collection("users").document(uid).updateData(["fcmToken": token])
            currentUser?.fcmToken = token
        } catch {
            print("Error updating FCM token: \(error)")
        }
    }
}
