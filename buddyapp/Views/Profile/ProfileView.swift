import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @State private var showSignOutConfirm = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    var user: AppUser? { authService.currentUser }

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    HStack(spacing: 16) {
                        AvatarView(
                            displayName: user?.displayName ?? "?",
                            size: 72
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(user?.displayName ?? "")
                                .font(.title3.bold())
                            Text(user?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
                }

                // Stats
                Section {
                    HStack {
                        StatCell(
                            value: "\(user?.groupIDs.count ?? 0)",
                            label: "Groups"
                        )
                        Divider().frame(height: 40)
                        StatCell(
                            value: "\(authService.currentUser?.groupIDs.count ?? 0)",
                            label: "Events"
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                // Account actions
                Section("Account") {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        Label("Edit Profile", systemImage: "pencil")
                    }

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                // Sign out
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func signOut() {
        do {
            try authService.signOut()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
