import SwiftUI
import FirebaseFirestore

struct EditProfileView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var isLoading = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        Form {
            Section("Display Name") {
                TextField("Display name", text: $displayName)
                    .autocorrectionDisabled()
            }

            Section {
                Button("Save Changes") {
                    Task { await save() }
                }
                .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            displayName = authService.currentUser?.displayName ?? ""
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func save() async {
        guard let uid = authService.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await Firestore.firestore().collection("users").document(uid).updateData([
                "displayName": displayName
            ])
            authService.currentUser?.displayName = displayName
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
