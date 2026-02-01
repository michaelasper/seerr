import SwiftUI

struct RequestRow: View {
    let request: MediaRequest
    let detail: MediaDetails?
    let onAppear: () -> Void

    private let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PosterView(imageURL: detail?.posterURL())

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(detail?.displayTitle ?? "Request #\(request.id)")
                        .font(.headline)
                        .lineLimit(1)
                    if let year = detail?.displayYear {
                        Text(year)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }

                HStack(spacing: 8) {
                    StatusBadge(status: request.status)
                    if request.is4k == true {
                        Label("4K", systemImage: "4k.tv")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(request.type.rawValue.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if let overview = detail?.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    if let requester = request.requestedBy?.name {
                        Label(requester, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let created = request.createdAt {
                        Label(relativeFormatter.localizedString(for: created, relativeTo: Date()), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .task {
            onAppear()
        }
    }
}

#Preview {
    let media = RequestedMedia(id: 1, mediaType: .movie, tmdbId: 603692, tvdbId: nil, imdbId: nil, status: .pending, status4k: nil, serviceUrl: nil, serviceUrl4k: nil)
    let request = MediaRequest(id: 42, status: .approved, type: .movie, media: media, requestedBy: UserSummary(id: 1, email: "admin@example.com", username: "admin", displayName: "Admin", avatar: nil), modifiedBy: nil, is4k: true, serverId: nil, profileId: nil, rootFolder: nil, createdAt: Date().addingTimeInterval(-3600), updatedAt: nil, seasons: nil)
    let detail = MediaDetails(id: 603692, title: "John Wick: Chapter 4", name: nil, overview: "With the price on his head ever increasing, legendary hit man John Wick takes his fight against the High Table global...", posterPath: "/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg", backdropPath: nil, releaseDate: "2023-03-22", firstAirDate: nil, voteAverage: 7.7, mediaInfo: media)

    RequestRow(request: request, detail: detail, onAppear: {})
        .padding()
}
