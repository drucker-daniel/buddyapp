import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @Binding var showSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var showResetPassword = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.accent)
                        .padding(.top, 48)

                    Text("Welcome back")
                        .font(.largeTitle.bold())

                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Fields
                VStack(spacing: 16) {
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
                }
                .padding(.horizontal, 24)

                // Actions
                VStack(spacing: 16) {
                    PrimaryButton(
                        title: "Sign In",
                        isLoading: authService.isLoading
                    ) {
                        await signIn()
                    }
                    .padding(.horizontal, 24)

                    Button("Forgot password?") {
                        showResetPassword = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.accent)

                    Divider().padding(.horizontal, 24)

                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(.secondary)
                        Button("Sign up") {
                            withAnimation { showSignUp = true }
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
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordView()
        }
    }

    private func signIn() async {
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
