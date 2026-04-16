import SwiftUI

struct CreateGroupView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    var onCreate: (Group) -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var visibility: GroupVisibility = .public
    @State private var isLoading = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Visibility picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Group Type")
                            .font(.headline)

                        HStack(spacing: 12) {
                            VisibilityOptionCard(
                                isSelected: visibility == .public,
                                icon: "globe",
                                title: "Public",
                                description: "Anyone can discover and join"
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    visibility = .public
                                }
                            }

                            VisibilityOptionCard(
                                isSelected: visibility == .private,
                                icon: "lock.fill",
                                title: "Private",
                                description: "Invite-only, not searchable"
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    visibility = .private
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Fields
                    VStack(spacing: 16) {
                        FormField(label: "Group Name") {
                            TextField("e.g. Weekend Hikers", text: $name)
                                .autocorrectionDisabled()
                        }

                        FormField(label: "Description") {
                            TextField("What's this group about?", text: $description, axis: .vertical)
                                .lineLimit(3...5)
                        }
                    }
                    .padding(.horizontal, 20)

                    PrimaryButton(title: "Create Group", isLoading: isLoading) {
                        await create()
                    }
                    .padding(.horizontal, 20)
                    .disabled(!isValid)
                }
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func create() async {
        guard let uid = authService.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let service = FirebaseService.shared
            let group = try await service.createGroup(
                name: name,
                description: description,
                visibility: visibility,
                creatorID: uid
            )
            await MainActor.run {
                onCreate(group)
                dismiss()
            }
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

// MARK: - Supporting Views

struct VisibilityOptionCard: View {
    let isSelected: Bool
    let icon: String
    let title: String
    let description: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .accent : .secondary)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .accent : .primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color(.separator), lineWidth: isSelected ? 2 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            content
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
        }
    }
}
