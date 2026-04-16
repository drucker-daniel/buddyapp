import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var profileImageURL: String?
    var fcmToken: String?
    var groupIDs: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case profileImageURL
        case fcmToken
        case groupIDs
    }

    init(id: String? = nil,
         email: String,
         displayName: String,
         profileImageURL: String? = nil,
         fcmToken: String? = nil,
         groupIDs: [String] = []) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.fcmToken = fcmToken
        self.groupIDs = groupIDs
    }
}
