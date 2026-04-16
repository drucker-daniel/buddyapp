import Foundation
import FirebaseFirestore

enum GroupVisibility: String, Codable, CaseIterable {
    case `public` = "public"
    case `private` = "private"
}

struct Group: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var visibility: GroupVisibility
    var creatorID: String
    var memberIDs: [String]
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case visibility
        case creatorID
        case memberIDs
        case createdAt
    }

    init(id: String? = nil,
         name: String,
         description: String,
         visibility: GroupVisibility,
         creatorID: String,
         memberIDs: [String] = [],
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.visibility = visibility
        self.creatorID = creatorID
        self.memberIDs = memberIDs
        self.createdAt = createdAt
    }

    var memberCount: Int { memberIDs.count }
}
