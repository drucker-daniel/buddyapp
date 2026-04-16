import SwiftUI

struct GroupsTabView: View {
    @Environment(AuthService.self) private var authService
    @Bindable var viewModel: GroupsViewModel

    @State private var showCreateGroup = false
    @State private var showInvitations = false
    @State private var isSearching = false
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Pending invitations banner
                    if !viewModel.pendingInvites.isEmpty {
                        invitationsBanner
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    // Search results or my groups
                    if isSearching && !viewModel.searchQuery.isEmpty {
                        searchResultsSection
                    } else {
                        myGroupsSection
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.searchQuery,
                isPresented: $isSearching,
                prompt: "Search public groups"
            )
            .onChange(of: viewModel.searchQuery) { _, _ in
                viewModel.searchPublicGroups()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateGroup = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .refreshable {
                if let user = authService.currentUser {
                    await viewModel.loadMyGroups(groupIDs: user.groupIDs)
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView { group in
                    viewModel.myGroups.append(group)
                }
            }
            .sheet(isPresented: $showInvitations) {
                InvitationsView(invites: viewModel.pendingInvites) { invite, accept in
                    try await viewModel.respondToInvite(invite: invite, accept: accept)
                    // Refresh groups if accepted
                    if accept, let user = authService.currentUser {
                        await viewModel.loadMyGroups(groupIDs: user.groupIDs)
                    }
                }
            }
        }
    }

    // MARK: - Invitations Banner

    private var invitationsBanner: some View {
        Button {
            showInvitations = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "envelope.badge.fill")
                    .font(.title3)
                    .foregroundStyle(.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("You have \(viewModel.pendingInvites.count) pending \(viewModel.pendingInvites.count == 1 ? "invitation" : "invitations")")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Tap to view")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.bottom, 8)
    }

    // MARK: - My Groups Section

    private var myGroupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
            } else if viewModel.myGroups.isEmpty {
                EmptyStateView(
                    icon: "person.3",
                    title: "No groups yet",
                    message: "Create a group or search for public groups to join.",
                    actionTitle: "Create Group"
                ) {
                    showCreateGroup = true
                }
                .frame(height: 400)
            } else {
                Text("My Groups")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                ForEach(viewModel.myGroups) { group in
                    NavigationLink(value: group) {
                        GroupCard(group: group, isMember: true)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(for: Group.self) { group in
            GroupDetailView(group: group)
        }
    }

    // MARK: - Search Results Section

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Public Groups")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            if viewModel.searchResults.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No results",
                    message: "No public groups match \"\(viewModel.searchQuery)\"."
                )
                .frame(height: 300)
            } else {
                ForEach(viewModel.searchResults) { group in
                    let isMember = viewModel.myGroups.contains { $0.id == group.id }
                    GroupCard(group: group, isMember: isMember) {
                        if let uid = authService.currentUser?.id {
                            try? await viewModel.joinPublicGroup(group: group, userID: uid)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}
