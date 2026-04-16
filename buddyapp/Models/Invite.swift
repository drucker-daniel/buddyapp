import Foundation
import FirebaseFirestore

enum InviteStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
}

struct Invite: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var groupID: String
    var groupName: String
    var invitedUserID: String
    var invitedByUserID: String
    var invitedByDisplayName: String
    var status: InviteStatus
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case groupID
        case groupName
        case invitedUserID
        case invitedByUserID
        case invitedByDisplayName
        case status
        case createdAt
    }

    init(id: String? = nil,
         groupID: String,
         groupName: String,
         invitedUserID: String,
         invitedByUserID: String,
         invitedByDisplayName: String,
         status: InviteStatus = .pending,
         createdAt: Date = Date()) {
        self.id = id
        self.groupID = groupID
        self.groupName = groupName
        self.invitedUserID = invitedUserID
        self.invitedByUserID = invitedByUserID
        self.invitedByDisplayName = invitedByDisplayName
        self.status = status
        self.createdAt = createdAt
    }
}
