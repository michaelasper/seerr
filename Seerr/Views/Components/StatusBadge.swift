import SwiftUI

struct StatusBadge: View {
    let status: MediaRequestStatus

    var body: some View {
        Text(status.label)
            .font(.caption2)
            .bold()
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(status.tint.opacity(0.15))
            .foregroundColor(status.tint)
            .clipShape(Capsule())
    }
}

private extension MediaRequestStatus {
    var tint: Color {
        switch self {
        case .pending:
            return .orange
        case .approved:
            return .blue
        case .declined:
            return .red
        case .failed:
            return .pink
        case .completed:
            return .green
        }
    }
}
