import Foundation
import FirebaseFirestore

@Observable
final class GroupsViewModel {
    var myGroups: [Group] = []
    var searchResults: [Group] = []
    var pendingInvites: [Invite] = []
    var searchQuery = ""
    var isLoading = false
    var error: Error?

    private let service = FirebaseService.shared
    private var inviteListener: ListenerRegistration?
    private var searchTask: Task<Void, Never>?

    func loadMyGroups(groupIDs: [String]) async {
        isLoading = true
        defer { isLoading = false }
        do {
            myGroups = try await service.fetchGroups(ids: groupIDs)
        } catch {
            self.error = error
        }
    }

    func listenToPendingInvites(userID: String) {
        inviteListener?.remove()
        inviteListener = service.listenToPendingInvites(userID: userID) { [weak self] invites in
            self?.pendingInvites = invites
        }
    }

    func stopListening() {
        inviteListener?.remove()
        inviteListener = nil
    }

    func searchPublicGroups() {
        searchTask?.cancel()
        let query = searchQuery
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            do {
                let results = try await service.searchPublicGroups(query: query)
                await MainActor.run { self.searchResults = results }
            } catch {
                await MainActor.run { self.error = error }
            }
        }
    }

    func createGroup(name: String, description: String, visibility: GroupVisibility, creatorID: String) async throws -> Group {
        let group = try await service.createGroup(
            name: name,
            description: description,
            visibility: visibility,
            creatorID: creatorID
        )
        await MainActor.run { myGroups.append(group) }
        return group
    }

    func joinPublicGroup(group: Group, userID: String) async throws {
        guard let groupID = group.id else { return }
        try await service.joinPublicGroup(groupID: groupID, userID: userID)
        if !myGroups.contains(where: { $0.id == groupID }) {
            let joined: Group = {
                var g = group
                if !g.memberIDs.contains(userID) {
                    g.memberIDs.append(userID)
                }
                return g
            }()
            await MainActor.run { myGroups.append(joined) }
        }
    }

    func respondToInvite(invite: Invite, accept: Bool) async throws {
        try await service.respondToInvite(invite: invite, accept: accept)
        await MainActor.run {
            pendingInvites.removeAll { $0.id == invite.id }
        }
    }

    var pendingInviteCount: Int { pendingInvites.count }
}
