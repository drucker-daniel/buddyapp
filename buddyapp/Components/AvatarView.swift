import SwiftUI

struct AvatarView: View {
    let displayName: String
    let size: CGFloat
    var imageURL: String? = nil

    private var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2, let f = parts.first?.first, let l = parts.last?.first {
            return "\(f)\(l)".uppercased()
        } else if let first = displayName.first {
            return String(first).uppercased()
        }
        return "?"
    }

    private var backgroundColor: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .teal, .indigo]
        let index = abs(displayName.hashValue) % colors.count
        return colors[index]
    }

    var body: some View {
        Circle()
            .fill(backgroundColor.gradient)
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }
}
