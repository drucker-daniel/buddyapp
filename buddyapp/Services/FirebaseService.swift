import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirebaseService {
    static let shared = FirebaseService()
    let db = Firestore.firestore()

    private init() {}

    // MARK: - Users

    func fetchUser(id: String) async throws -> AppUser {
        let doc = try await db.collection("users").document(id).getDocument()
        return try doc.data(as: AppUser.self)
    }

    func searchUsers(query: String) async throws -> [AppUser] {
        guard !query.isEmpty else { return [] }
        // Search by displayName prefix
        let snapshot = try await db.collection("users")
            .whereField("displayName", isGreaterThanOrEqualTo: query)
            .whereField("displayName", isLessThan: query + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AppUser.self) }
    }

    // MARK: - Groups

    func fetchGroup(id: String) async throws -> Group {
        let doc = try await db.collection("groups").document(id).getDocument()
        return try doc.data(as: Group.self)
    }

    func fetchGroups(ids: [String]) async throws -> [Group] {
        guard !ids.isEmpty else { return [] }
        var groups: [Group] = []
        // Firestore whereField in supports up to 30 items
        let chunks = stride(from: 0, to: ids.count, by: 30).map {
            Array(ids[$0..<min($0 + 30, ids.count)])
        }
        for chunk in chunks {
            let snapshot = try await db.collection("groups")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            let batch = snapshot.documents.compactMap { try? $0.data(as: Group.self) }
            groups.append(contentsOf: batch)
        }
        return groups
    }

    func searchPublicGroups(query: String) async throws -> [Group] {
        guard !query.isEmpty else { return [] }
        let snapshot = try await db.collection("groups")
            .whereField("visibility", isEqualTo: GroupVisibility.public.rawValue)
            .whereField("name", isGreaterThanOrEqualTo: query)
            .whereField("name", isLessThan: query + "\u{f8ff}")
            .limit(to: 30)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Group.self) }
    }

    func createGroup(name: String, description: String, visibility: GroupVisibility, creatorID: String) async throws -> Group {
        let ref = db.collection("groups").document()
        var group = Group(
            id: ref.documentID,
            name: name,
            description: description,
            visibility: visibility,
            creatorID: creatorID,
            memberIDs: [creatorID],
            createdAt: Date()
        )
        try ref.setData(from: group)
        // Add group to user's groupIDs
        try await db.collection("users").document(creatorID).updateData([
            "groupIDs": FieldValue.arrayUnion([ref.documentID])
        ])
        group.id = ref.documentID
        return group
    }

    func joinPublicGroup(groupID: String, userID: String) async throws {
        let batch = db.batch()
        let groupRef = db.collection("groups").document(groupID)
        let userRef = db.collection("users").document(userID)
        batch.updateData(["memberIDs": FieldValue.arrayUnion([userID])], forDocument: groupRef)
        batch.updateData(["groupIDs": FieldValue.arrayUnion([groupID])], forDocument: userRef)
        try await batch.commit()
    }

    func leaveGroup(groupID: String, userID: String) async throws {
        let batch = db.batch()
        let groupRef = db.collection("groups").document(groupID)
        let userRef = db.collection("users").document(userID)
        batch.updateData(["memberIDs": FieldValue.arrayRemove([userID])], forDocument: groupRef)
        batch.updateData(["groupIDs": FieldValue.arrayRemove([groupID])], forDocument: userRef)
        try await batch.commit()
    }

    func removeMember(groupID: String, memberID: String) async throws {
        try await leaveGroup(groupID: groupID, userID: memberID)
    }

    func deleteGroup(groupID: String) async throws {
        // Delete all events and invites first (in production use a Cloud Function for this)
        let eventsSnapshot = try await db.collection("events")
            .whereField("groupID", isEqualTo: groupID)
            .getDocuments()
        for doc in eventsSnapshot.documents {
            try await doc.reference.delete()
        }
        let invitesSnapshot = try await db.collection("invites")
            .whereField("groupID", isEqualTo: groupID)
            .getDocuments()
        for doc in invitesSnapshot.documents {
            try await doc.reference.delete()
        }
        try await db.collection("groups").document(groupID).delete()
    }

    // MARK: - Invites

    func fetchPendingInvites(for userID: String) async throws -> [Invite] {
        let snapshot = try await db.collection("invites")
            .whereField("invitedUserID", isEqualTo: userID)
            .whereField("status", isEqualTo: InviteStatus.pending.rawValue)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Invite.self) }
    }

    func fetchSentInvites(by userID: String, for groupID: String) async throws -> [Invite] {
        let snapshot = try await db.collection("invites")
            .whereField("groupID", isEqualTo: groupID)
            .whereField("invitedByUserID", isEqualTo: userID)
            .whereField("status", isEqualTo: InviteStatus.pending.rawValue)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Invite.self) }
    }

    func fetchGroupInvites(groupID: String) async throws -> [Invite] {
        let snapshot = try await db.collection("invites")
            .whereField("groupID", isEqualTo: groupID)
            .whereField("status", isEqualTo: InviteStatus.pending.rawValue)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Invite.self) }
    }

    func createInvite(groupID: String, groupName: String, invitedUserID: String, invitedByUserID: String, invitedByDisplayName: String) async throws -> Invite {
        // Check for existing pending invite
        let existing = try await db.collection("invites")
            .whereField("groupID", isEqualTo: groupID)
            .whereField("invitedUserID", isEqualTo: invitedUserID)
            .whereField("status", isEqualTo: InviteStatus.pending.rawValue)
            .getDocuments()
        if !existing.documents.isEmpty {
            throw AppError.inviteAlreadyPending
        }

        let ref = db.collection("invites").document()
        var invite = Invite(
            id: ref.documentID,
            groupID: groupID,
            groupName: groupName,
            invitedUserID: invitedUserID,
            invitedByUserID: invitedByUserID,
            invitedByDisplayName: invitedByDisplayName,
            status: .pending,
            createdAt: Date()
        )
        try ref.setData(from: invite)
        invite.id = ref.documentID
        return invite
    }

    func respondToInvite(invite: Invite, accept: Bool) async throws {
        guard let inviteID = invite.id else { return }
        let newStatus: InviteStatus = accept ? .accepted : .declined
        let inviteRef = db.collection("invites").document(inviteID)

        if accept {
            let batch = db.batch()
            batch.updateData(["status": newStatus.rawValue], forDocument: inviteRef)
            let groupRef = db.collection("groups").document(invite.groupID)
            batch.updateData(["memberIDs": FieldValue.arrayUnion([invite.invitedUserID])], forDocument: groupRef)
            let userRef = db.collection("users").document(invite.invitedUserID)
            batch.updateData(["groupIDs": FieldValue.arrayUnion([invite.groupID])], forDocument: userRef)
            try await batch.commit()
        } else {
            try await inviteRef.updateData(["status": newStatus.rawValue])
        }
    }

    func cancelInvite(inviteID: String) async throws {
        try await db.collection("invites").document(inviteID).delete()
    }

    // MARK: - Events

    func fetchEvents(for groupID: String) async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("groupID", isEqualTo: groupID)
            .order(by: "dateTime", descending: false)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Event.self) }
    }

    func fetchUpcomingEvents(for groupIDs: [String]) async throws -> [Event] {
        guard !groupIDs.isEmpty else { return [] }
        var events: [Event] = []
        let now = Date()
        let chunks = stride(from: 0, to: groupIDs.count, by: 10).map {
            Array(groupIDs[$0..<min($0 + 10, groupIDs.count)])
        }
        for chunk in chunks {
            let snapshot = try await db.collection("events")
                .whereField("groupID", in: chunk)
                .whereField("dateTime", isGreaterThan: now)
                .order(by: "dateTime", descending: false)
                .getDocuments()
            let batch = snapshot.documents.compactMap { try? $0.data(as: Event.self) }
            events.append(contentsOf: batch)
        }
        return events.sorted { $0.dateTime < $1.dateTime }
    }

    func createEvent(groupID: String, groupName: String, creatorID: String, title: String, description: String, address: String, dateTime: Date) async throws -> Event {
        let ref = db.collection("events").document()
        var event = Event(
            id: ref.documentID,
            groupID: groupID,
            groupName: groupName,
            creatorID: creatorID,
            title: title,
            description: description,
            address: address,
            dateTime: dateTime,
            rsvps: [:],
            createdAt: Date()
        )
        try ref.setData(from: event)
        event.id = ref.documentID
        return event
    }

    func updateRSVP(eventID: String, userID: String, status: RSVPStatus) async throws {
        try await db.collection("events").document(eventID).updateData([
            "rsvps.\(userID)": status.rawValue
        ])
    }

    func deleteEvent(eventID: String) async throws {
        try await db.collection("events").document(eventID).delete()
    }

    // MARK: - Listeners

    func listenToGroup(id: String, onChange: @escaping (Group?) -> Void) -> ListenerRegistration {
        db.collection("groups").document(id).addSnapshotListener { snapshot, _ in
            onChange(try? snapshot?.data(as: Group.self))
        }
    }

    func listenToPendingInvites(userID: String, onChange: @escaping ([Invite]) -> Void) -> ListenerRegistration {
        db.collection("invites")
            .whereField("invitedUserID", isEqualTo: userID)
            .whereField("status", isEqualTo: InviteStatus.pending.rawValue)
            .addSnapshotListener { snapshot, _ in
                let invites = snapshot?.documents.compactMap { try? $0.data(as: Invite.self) } ?? []
                onChange(invites)
            }
    }

    func listenToGroupEvents(groupID: String, onChange: @escaping ([Event]) -> Void) -> ListenerRegistration {
        db.collection("events")
            .whereField("groupID", isEqualTo: groupID)
            .order(by: "dateTime", descending: false)
            .addSnapshotListener { snapshot, _ in
                let events = snapshot?.documents.compactMap { try? $0.data(as: Event.self) } ?? []
                onChange(events)
            }
    }
}

// MARK: - App Errors

enum AppError: LocalizedError {
    case inviteAlreadyPending
    case alreadyMember
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .inviteAlreadyPending: return "This user already has a pending invite to this group."
        case .alreadyMember: return "This user is already a member of this group."
        case .unknown(let msg): return msg
        }
    }
}
