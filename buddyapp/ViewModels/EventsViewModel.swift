import Foundation
import FirebaseFirestore

@Observable
final class EventsViewModel {
    var upcomingEvents: [Event] = []
    var isLoading = false
    var error: Error?

    private let service = FirebaseService.shared

    func loadUpcomingEvents(groupIDs: [String]) async {
        guard !groupIDs.isEmpty else {
            upcomingEvents = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            upcomingEvents = try await service.fetchUpcomingEvents(for: groupIDs)
        } catch {
            self.error = error
        }
    }

    func updateRSVP(eventID: String, userID: String, status: RSVPStatus) async {
        do {
            try await service.updateRSVP(eventID: eventID, userID: userID, status: status)
            if let idx = upcomingEvents.firstIndex(where: { $0.id == eventID }) {
                upcomingEvents[idx].rsvps[userID] = status.rawValue
            }
        } catch {
            self.error = error
        }
    }
}

@Observable
final class EventDetailViewModel {
    var event: Event
    var creatorName: String = ""
    var isLoading = false
    var error: Error?

    private let service = FirebaseService.shared

    init(event: Event) {
        self.event = event
    }

    func loadCreator() async {
        do {
            let creator = try await service.fetchUser(id: event.creatorID)
            creatorName = creator.displayName
        } catch {
            self.error = error
        }
    }

    func updateRSVP(userID: String, status: RSVPStatus) async {
        guard let eventID = event.id else { return }
        do {
            try await service.updateRSVP(eventID: eventID, userID: userID, status: status)
            event.rsvps[userID] = status.rawValue
        } catch {
            self.error = error
        }
    }
}

@Observable
final class CreateEventViewModel {
    var title = ""
    var description = ""
    var address = ""
    var dateTime = Date().addingTimeInterval(3600)
    var isLoading = false
    var error: Error?

    private let service = FirebaseService.shared

    func createEvent(groupID: String, groupName: String, creatorID: String) async throws -> Event {
        isLoading = true
        defer { isLoading = false }
        return try await service.createEvent(
            groupID: groupID,
            groupName: groupName,
            creatorID: creatorID,
            title: title,
            description: description,
            address: address,
            dateTime: dateTime
        )
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        dateTime > Date()
    }
}
