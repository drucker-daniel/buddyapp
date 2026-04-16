import SwiftUI

struct SignUpView: View {
    @Environment(AuthService.self) private var authService
    @Binding var showSignUp: Bool

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 72))
                        .foregroundStyle(.accent)
                        .padding(.top, 48)

                    Text("Create account")
                        .font(.largeTitle.bold())

                    Text("Join and connect with friends")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Fields
                VStack(spacing: 16) {
                    AuthTextField(
                        icon: "person",
                        placeholder: "Display name",
                        text: $displayName,
                        keyboardType: .default,
                        isSecure: false
                    )

                    AuthTextField(
                        icon: "envelope",
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        isSecure: false
                    )

                    AuthTextField(
                        icon: "lock",
                        placeholder: "Password",
                        text: $password,
                        keyboardType: .default,
                        isSecure: true
                    )

                    AuthTextField(
                        icon: "lock.fill",
                        placeholder: "Confirm password",
                        text: $confirmPassword,
                        keyboardType: .default,
                        isSecure: true
                    )
                }
                .padding(.horizontal, 24)

                // Actions
                VStack(spacing: 16) {
                    PrimaryButton(
                        title: "Create Account",
                        isLoading: authService.isLoading
                    ) {
                        await signUp()
                    }
                    .padding(.horizontal, 24)
                    .disabled(!isValid)

                    Divider().padding(.horizontal, 24)

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(.secondary)
                        Button("Sign in") {
                            withAnimation { showSignUp = false }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.accent)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var isValid: Bool {
        !displayName.isEmpty && !email.isEmpty &&
        password.count >= 6 && password == confirmPassword
    }

    private func signUp() async {
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            showAlert = true
            return
        }
        do {
            try await authService.signUp(email: email, password: password, displayName: displayName)
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
