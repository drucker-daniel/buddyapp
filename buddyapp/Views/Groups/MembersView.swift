import SwiftUI

struct MembersView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: GroupDetailViewModel
    let isCreator: Bool
    let currentUserID: String
    let onRemove: (String) async throws -> Void

    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var removingID: String? = nil

    var body: some View {
        NavigationStack {
            List(viewModel.members) { member in
                HStack(spacing: 12) {
                    AvatarView(displayName: member.displayName, size: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(member.displayName)
                                .font(.subheadline.weight(.medium))

                            if member.id == viewModel.group?.creatorID {
                                Text("Creator")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.accentColor.opacity(0.1), in: Capsule())
                            }
                        }
                        Text(member.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if isCreator && member.id != currentUserID {
                        if removingID == member.id {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Button(role: .destructive) {
                                guard let memberID = member.id else { return }
                                Task { await remove(memberID: memberID) }
                            } label: {
                                Image(systemName: "person.badge.minus")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
            }
            .listStyle(.plain)
            .navigationTitle("Members")
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

    private func remove(memberID: String) async {
        removingID = memberID
        defer { removingID = nil }
        do {
            try await onRemove(memberID)
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
