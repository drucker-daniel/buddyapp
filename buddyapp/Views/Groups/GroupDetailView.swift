import SwiftUI

struct GroupDetailView: View {
    @Environment(AuthService.self) private var authService
    let group: Group

    @State private var viewModel = GroupDetailViewModel()
    @State private var showInviteUsers = false
    @State private var showCreateEvent = false
    @State private var showMembers = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var showLeaveConfirm = false
    @State private var showDeleteConfirm = false
    @State private var selectedEvent: Event?
    @Environment(\.dismiss) private var dismiss

    var currentUserID: String { authService.currentUser?.id ?? "" }
    var isCreator: Bool { group.creatorID == currentUserID }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Group header
                groupHeader

                // Quick stats
                statsRow

                // Action buttons
                actionButtons

                // Upcoming events
                eventsSection

                // Danger zone (creator only)
                if isCreator {
                    dangerZone
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.group?.name ?? group.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if group.visibility == .private {
                        Button {
                            showInviteUsers = true
                        } label: {
                            Label("Invite People", systemImage: "person.badge.plus")
                        }
                    }
                    Button {
                        showMembers = true
                    } label: {
                        Label("View Members", systemImage: "person.3")
                    }
                    Divider()
                    if !isCreator {
                        Button(role: .destructive) {
                            showLeaveConfirm = true
                        } label: {
                            Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            guard let id = group.id else { return }
            await viewModel.loadGroup(id: id)
            viewModel.startListening(groupID: id)
            await viewModel.loadSentInvites(currentUserID: currentUserID)
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .sheet(isPresented: $showInviteUsers) {
            InviteUsersView(viewModel: viewModel, currentUser: authService.currentUser)
        }
        .sheet(isPresented: $showCreateEvent) {
            CreateEventView(group: viewModel.group ?? group)
        }
        .sheet(isPresented: $showMembers) {
            MembersView(viewModel: viewModel, isCreator: isCreator, currentUserID: currentUserID) { memberID in
                guard let groupID = group.id else { return }
                try await viewModel.removeMember(memberID: memberID, groupID: groupID)
            }
        }
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event)
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog("Leave Group", isPresented: $showLeaveConfirm, titleVisibility: .visible) {
            Button("Leave", role: .destructive) {
                Task { await leaveGroup() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You won't be able to rejoin a private group without an invitation.")
        }
        .confirmationDialog("Delete Group", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { await deleteGroup() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the group and all its events. This cannot be undone.")
        }
    }

    // MARK: - Group Header

    private var groupHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: group.visibility == .public ? "globe" : "lock.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.group?.name ?? group.name)
                    .font(.title2.bold())
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: group.visibility == .public ? "globe" : "lock.fill")
                        .font(.caption2)
                    Text(group.visibility == .public ? "Public Group" : "Private Group")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                if !(viewModel.group?.description ?? group.description).isEmpty {
                    Text(viewModel.group?.description ?? group.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            StatCell(value: "\(viewModel.group?.memberCount ?? group.memberCount)", label: "Members")
            Divider().frame(height: 40)
            StatCell(value: "\(viewModel.events.count)", label: "Events")
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showCreateEvent = true
            } label: {
                Label("New Event", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.accent, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }

            if group.visibility == .private {
                Button {
                    showInviteUsers = true
                } label: {
                    Label("Invite", systemImage: "person.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Events Section

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Events")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 20)

            if viewModel.events.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.plus",
                    title: "No events",
                    message: "Be the first to create an event for this group."
                )
                .frame(height: 200)
            } else {
                ForEach(viewModel.events) { event in
                    NavigationLink(value: event) {
                        EventCard(event: event, currentUserID: currentUserID)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(.headline)
                .foregroundStyle(.red)
                .padding(.horizontal, 20)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete Group", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.red.opacity(0.4), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Actions

    private func leaveGroup() async {
        guard let groupID = group.id else { return }
        do {
            try await viewModel.leaveGroup(groupID: groupID, userID: currentUserID)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func deleteGroup() async {
        guard let groupID = group.id else { return }
        do {
            try await viewModel.deleteGroup(groupID: groupID)
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

struct StatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
