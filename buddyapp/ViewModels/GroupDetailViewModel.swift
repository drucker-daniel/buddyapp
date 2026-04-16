import Foundation
import FirebaseFirestore

@Observable
final class GroupDetailViewModel {
    var group: Group?
    var events: [Event] = []
    var members: [AppUser] = []
    var sentInvites: [Invite] = []
    var userSearchResults: [AppUser] = []
    var userSearchQuery = ""
    var isLoading = false
    var error: Error?

    private let service = FirebaseService.shared
    private var groupListener: ListenerRegistration?
    private var eventsListener: ListenerRegistration?
    private var searchTask: Task<Void, Never>?

    func loadGroup(id: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            group = try await service.fetchGroup(id: id)
            await loadMembers()
            await loadSentInvites(currentUserID: "")
        } catch {
            self.error = error
        }
    }

    func startListening(groupID: String) {
        groupListener = service.listenToGroup(id: groupID) { [weak self] updated in
            if let updated {
                self?.group = updated
                Task { await self?.loadMembers() }
            }
        }
        eventsListener = service.listenToGroupEvents(groupID: groupID) { [weak self] events in
            self?.events = events
        }
    }

    func stopListening() {
        groupListener?.remove()
        eventsListener?.remove()
        groupListener = nil
        eventsListener = nil
    }

    func loadMembers() async {
        guard let memberIDs = group?.memberIDs else { return }
        var loaded: [AppUser] = []
        for id in memberIDs {
            if let user = try? await service.fetchUser(id: id) {
                loaded.append(user)
            }
        }
        members = loaded
    }

    func loadSentInvites(currentUserID: String) async {
        guard let groupID = group?.id, !currentUserID.isEmpty else { return }
        do {
            sentInvites = try await service.fetchSentInvites(by: currentUserID, for: groupID)
        } catch {
            self.error = error
        }
    }

    func searchUsers(query: String, currentUserID: String) {
        searchTask?.cancel()
        userSearchQuery = query
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            userSearchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            do {
                let rawResults = try await service.searchUsers(query: query)
                // Filter out existing members and self
                let existingIDs = Set((group?.memberIDs ?? []) + [currentUserID])
                let results = rawResults.filter { user in
                    guard let id = user.id else { return false }
                    return !existingIDs.contains(id)
                }
                await MainActor.run { self.userSearchResults = results }
            } catch {
                await MainActor.run { self.error = error }
            }
        }
    }

    func inviteUser(_ user: AppUser, invitedByUser: AppUser) async throws {
        guard let groupID = group?.id,
              let invitedUserID = user.id,
              let inviterID = invitedByUser.id,
              let groupName = group?.name else { return }

        // Check if already a member
        if group?.memberIDs.contains(invitedUserID) == true {
            throw AppError.alreadyMember
        }

        let invite = try await service.createInvite(
            groupID: groupID,
            groupName: groupName,
            invitedUserID: invitedUserID,
            invitedByUserID: inviterID,
            invitedByDisplayName: invitedByUser.displayName
        )
        sentInvites.append(invite)
        userSearchResults = []
        userSearchQuery = ""
    }

    func cancelInvite(_ invite: Invite) async throws {
        guard let inviteID = invite.id else { return }
        try await service.cancelInvite(inviteID: inviteID)
        sentInvites.removeAll { $0.id == inviteID }
    }

    func removeMember(memberID: String, groupID: String) async throws {
        try await service.removeMember(groupID: groupID, memberID: memberID)
        members.removeAll { $0.id == memberID }
        group?.memberIDs.removeAll { $0 == memberID }
    }

    func deleteGroup(groupID: String) async throws {
        try await service.deleteGroup(groupID: groupID)
    }

    func leaveGroup(groupID: String, userID: String) async throws {
        try await service.leaveGroup(groupID: groupID, userID: userID)
    }

    func hasPendingInvite(for userID: String) -> Bool {
        sentInvites.contains { $0.invitedUserID == userID }
    }
}
