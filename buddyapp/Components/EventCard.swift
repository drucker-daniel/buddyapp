import SwiftUI

struct EventCard: View {
    let event: Event
    let currentUserID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Date block
                VStack(spacing: 2) {
                    Text(event.dateTime, format: .dateTime.month(.abbreviated))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.accent)
                        .textCase(.uppercase)
                    Text(event.dateTime, format: .dateTime.day())
                        .font(.title2.bold())
                }
                .frame(width: 44)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.1))
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(event.groupName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(event.dateTime, format: .dateTime.hour().minute())
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)

                    if !event.address.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin")
                                .font(.caption2)
                            Text(event.address)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.leading, 4)

                Spacer()

                if let status = event.rsvpStatus(for: currentUserID) {
                    RSVPBadge(status: status)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct RSVPBadge: View {
    let status: RSVPStatus

    var color: Color {
        switch status {
        case .going: return .green
        case .notGoing: return .red
        case .maybe: return .orange
        }
    }

    var body: some View {
        Image(systemName: status.icon)
            .font(.system(size: 20))
            .foregroundStyle(color)
    }
}
