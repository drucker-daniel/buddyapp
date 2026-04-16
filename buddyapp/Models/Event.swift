import Foundation
import FirebaseFirestore

enum RSVPStatus: String, Codable, CaseIterable {
    case going = "going"
    case notGoing = "not_going"
    case maybe = "maybe"

    var displayName: String {
        switch self {
        case .going: return "Going"
        case .notGoing: return "Not Going"
        case .maybe: return "Maybe"
        }
    }

    var icon: String {
        switch self {
        case .going: return "checkmark.circle.fill"
        case .notGoing: return "xmark.circle.fill"
        case .maybe: return "questionmark.circle.fill"
        }
    }
}

struct Event: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var groupID: String
    var groupName: String
    var creatorID: String
    var title: String
    var description: String
    var address: String
    var dateTime: Date
    var rsvps: [String: String]  // userID: RSVPStatus.rawValue
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case groupID
        case groupName
        case creatorID
        case title
        case description
        case address
        case dateTime
        case rsvps
        case createdAt
    }

    init(id: String? = nil,
         groupID: String,
         groupName: String,
         creatorID: String,
         title: String,
         description: String,
         address: String,
         dateTime: Date,
         rsvps: [String: String] = [:],
         createdAt: Date = Date()) {
        self.id = id
        self.groupID = groupID
        self.groupName = groupName
        self.creatorID = creatorID
        self.title = title
        self.description = description
        self.address = address
        self.dateTime = dateTime
        self.rsvps = rsvps
        self.createdAt = createdAt
    }

    func rsvpStatus(for userID: String) -> RSVPStatus? {
        guard let raw = rsvps[userID] else { return nil }
        return RSVPStatus(rawValue: raw)
    }

    var goingCount: Int { rsvps.values.filter { $0 == RSVPStatus.going.rawValue }.count }
    var maybeCount: Int { rsvps.values.filter { $0 == RSVPStatus.maybe.rawValue }.count }
    var notGoingCount: Int { rsvps.values.filter { $0 == RSVPStatus.notGoing.rawValue }.count }
}
