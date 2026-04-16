import SwiftUI

struct InvitationsView: View {
    @Environment(\.dismiss) private var dismiss
    let invites: [Invite]
    let onRespond: (Invite, Bool) async throws -> Void

    @State private var respondingID: String? = nil
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            SwiftUI.Group {
                if invites.isEmpty {
                    EmptyStateView(
                        icon: "envelope.open",
                        title: "No invitations",
                        message: "You're all caught up! No pending invites."
                    )
                } else {
                    List(invites) { invite in
                        InviteRow(
                            invite: invite,
                            isResponding: respondingID == invite.id
                        ) { accept in
                            await respond(to: invite, accept: accept)
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Invitations")
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

    private func respond(to invite: Invite, accept: Bool) async {
        respondingID = invite.id
        defer { respondingID = nil }
        do {
            try await onRespond(invite, accept)
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

struct InviteRow: View {
    let invite: Invite
    let isResponding: Bool
    let onRespond: (Bool) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                AvatarView(displayName: invite.invitedByDisplayName, size: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(invite.invitedByDisplayName) invited you")
                        .font(.subheadline.weight(.semibold))

                    Text("to join \(invite.groupName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(invite.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }

            if isResponding {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                HStack(spacing: 12) {
                    Button {
                        Task { await onRespond(false) }
                    } label: {
                        Text("Decline")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.primary)
                    }

                    Button {
                        Task { await onRespond(true) }
                    } label: {
                        Text("Accept")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.accent, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
