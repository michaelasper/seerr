import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var viewModel = DiscoverViewModel()
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var searchText: String = ""

    var body: some View {
        Group {
            if !settings.isConfigured {
                VStack(spacing: 12) {
                    Text("Connect to Overseerr to browse.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        filters
                        if !searchText.isEmpty {
                            searchResultsSection
                        } else {
                            if viewModel.isLoading {
                                ProgressView("Loading…")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            if let message = viewModel.errorMessage {
                                Text(message)
                                    .foregroundStyle(.secondary)
                            }
                            MediaRowSection(title: "Trending", items: viewModel.trending)
                            MediaRowSection(title: "Popular Movies", items: viewModel.movies)
                            MediaRowSection(title: "Popular Series", items: viewModel.tv)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Discover")
        .searchable(text: $searchText, prompt: "Search movies & TV")
        .onChange(of: searchText) { newValue in
            Task { await searchViewModel.search(query: newValue) }
        }
        .task {
            searchViewModel.updateConfiguration(settings: settings)
            await viewModel.load(using: settings)
        }
        .onChange(of: settings.baseURLString) { _ in
            searchViewModel.updateConfiguration(settings: settings)
        }
        .onChange(of: settings.apiKey) { _ in
            searchViewModel.updateConfiguration(settings: settings)
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Picker("Sort", selection: $viewModel.sortOption) {
                    ForEach(DiscoverViewModel.SortOption.allCases) { sort in
                        Text(sort.label).tag(sort)
                    }
                }
                .pickerStyle(.menu)

                Picker("Trending", selection: $viewModel.trendingPeriod) {
                    ForEach(DiscoverViewModel.TrendingPeriod.allCases) { period in
                        Text(period.label).tag(period)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack {
                TextField("Genre id", text: Binding(
                    get: { viewModel.selectedGenre ?? "" },
                    set: { viewModel.selectedGenre = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

                TextField("Year", text: Binding(
                    get: { viewModel.selectedYear ?? "" },
                    set: { viewModel.selectedYear = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

                Button("Apply") {
                    Task { await viewModel.load(using: settings) }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if searchViewModel.isSearching {
                ProgressView("Searching…")
            }
            if let message = searchViewModel.errorMessage {
                Text(message).foregroundStyle(.secondary)
            }
            if searchViewModel.results.isEmpty && !searchViewModel.isSearching {
                Text("No results")
                    .foregroundStyle(.secondary)
            }
            LazyVStack(spacing: 12) {
                ForEach(searchViewModel.results) { item in
                    NavigationLink {
                        MediaDetailView(mediaType: item.mediaType ?? .movie, tmdbId: item.id, initialDetail: nil)
                    } label: {
                        MediaListRow(item: item)
                    }
                }
            }
        }
    }
}

struct MediaRowSection: View {
    let title: String
    let items: [SearchResult]

    var body: some View {
        if items.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(items) { item in
                            NavigationLink {
                                MediaDetailView(mediaType: item.mediaType ?? .movie, tmdbId: item.id, initialDetail: nil)
                            } label: {
                                MediaCard(item: item)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct MediaCard: View {
    let item: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PosterView(imageURL: item.posterURL())
                .frame(width: 140, height: 210)
            Text(item.displayTitle)
                .font(.subheadline)
                .bold()
                .lineLimit(1)
            if let year = item.displayYear {
                Text(year)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 150, alignment: .leading)
    }
}

struct MediaListRow: View {
    let item: SearchResult

    var body: some View {
        HStack(spacing: 12) {
            PosterView(imageURL: item.posterURL())
                .frame(width: 60, height: 90)
            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayTitle)
                    .font(.headline)
                    .lineLimit(2)
                if let overview = item.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack {
                    Text(item.mediaType?.rawValue.uppercased() ?? "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let year = item.displayYear {
                        Text(year)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
