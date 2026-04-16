import SwiftUI

struct ResetPasswordView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var sent = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: sent ? "checkmark.circle.fill" : "envelope.badge")
                        .font(.system(size: 64))
                        .foregroundStyle(sent ? .green : .accent)
                        .animation(.spring(response: 0.4), value: sent)

                    Text(sent ? "Check your email" : "Reset password")
                        .font(.title.bold())

                    Text(sent
                         ? "We've sent a reset link to \(email)"
                         : "Enter your email and we'll send you a reset link.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 48)

                if !sent {
                    AuthTextField(
                        icon: "envelope",
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        isSecure: false
                    )
                    .padding(.horizontal, 24)

                    PrimaryButton(title: "Send Reset Link", isLoading: isLoading) {
                        await sendReset()
                    }
                    .padding(.horizontal, 24)
                } else {
                    PrimaryButton(title: "Done", isLoading: false) {
                        dismiss()
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func sendReset() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.resetPassword(email: email)
            withAnimation { sent = true }
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
