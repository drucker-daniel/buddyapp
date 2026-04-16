import SwiftUI

struct GroupCard: View {
    let group: Group
    let isMember: Bool
    var onJoin: (() async -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                // Visibility icon
                Image(systemName: group.visibility == .public ? "globe" : "lock.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(group.visibility == .public ? Color.accentColor : .secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(group.visibility == .public
                                  ? Color.accentColor.opacity(0.12)
                                  : Color(.tertiarySystemFill))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(memberLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !isMember, let onJoin {
                    Button {
                        Task { await onJoin() }
                    } label: {
                        Text("Join")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.accent, in: Capsule())
                    }
                }
            }

            if !group.description.isEmpty {
                Text(group.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var memberLabel: String {
        let count = group.memberCount
        return "\(count) \(count == 1 ? "member" : "members")"
    }
}
