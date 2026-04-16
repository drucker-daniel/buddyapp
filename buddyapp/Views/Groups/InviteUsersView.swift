import SwiftUI

struct InviteUsersView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: GroupDetailViewModel
    var currentUser: AppUser?

    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search by name or email", text: $viewModel.userSearchQuery)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.userSearchQuery) { _, query in
                            viewModel.searchUsers(query: query, currentUserID: currentUser?.id ?? "")
                        }

                    if !viewModel.userSearchQuery.isEmpty {
                        Button {
                            viewModel.userSearchQuery = ""
                            viewModel.userSearchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .padding(16)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Pending invites section
                        if !viewModel.sentInvites.isEmpty {
                            pendingInvitesSection
                        }

                        // Search results
                        if viewModel.userSearchQuery.isEmpty {
                            EmptyStateView(
                                icon: "person.badge.plus",
                                title: "Find people",
                                message: "Search for users by their display name to invite them."
                            )
                            .frame(height: 300)
                        } else if viewModel.userSearchResults.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "No results",
                                message: "No users found for \"\(viewModel.userSearchQuery)\"."
                            )
                            .frame(height: 200)
                        } else {
                            ForEach(viewModel.userSearchResults) { user in
                                UserInviteRow(
                                    user: user,
                                    hasPendingInvite: viewModel.hasPendingInvite(for: user.id ?? "")
                                ) {
                                    guard let inviter = currentUser else { return }
                                    do {
                                        try await viewModel.inviteUser(user, invitedByUser: inviter)
                                    } catch {
                                        alertMessage = error.localizedDescription
                                        showAlert = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Invite to \(viewModel.group?.name ?? "Group")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var pendingInvitesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Pending Invites")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            ForEach(viewModel.sentInvites) { invite in
                HStack(spacing: 12) {
                    AvatarView(displayName: invite.invitedUserID, size: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(invite.invitedUserID)
                            .font(.subheadline.weight(.medium))
                        Text("Invite pending")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Spacer()

                    Button("Cancel") {
                        Task {
                            try? await viewModel.cancelInvite(invite)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                Divider().padding(.leading, 72)
            }
        }
    }
}

struct UserInviteRow: View {
    let user: AppUser
    let hasPendingInvite: Bool
    let onInvite: () async -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(displayName: user.displayName, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.subheadline.weight(.medium))
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if hasPendingInvite {
                Text("Invited")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12), in: Capsule())
            } else {
                Button {
                    Task { await onInvite() }
                } label: {
                    Text("Invite")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.accent, in: Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)

        Divider().padding(.leading, 76)
    }
}
