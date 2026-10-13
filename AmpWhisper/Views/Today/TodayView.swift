import SwiftUI
import SwiftData

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var recipes: [ToneRecipe] = ResourceStore.loadRecipes()

    var weeklyDrops: [ToneRecipe] { recipes.filter(\.isWeeklyDrop) }
    var hotSongs: [ToneRecipe] { Array(recipes.prefix(40)) }

    var filtered: [ToneRecipe] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return recipes }
        return recipes.filter {
            $0.song.localizedCaseInsensitiveContains(query) || $0.artist.localizedCaseInsensitiveContains(query) || $0.genre.localizedCaseInsensitiveContains(query)
        }
    }
}

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedRecipe: ToneRecipe?
    @State private var showPaywall = false
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var quotaManager = QuotaManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if viewModel.searchText.isEmpty {
                        dropsSection
                    }
                    songGrid
                }
                .padding(.horizontal)
            }
            .background(Color.tolex)
            .searchable(text: $viewModel.searchText, prompt: "Search a song or artist")
            .navigationTitle("Today")
            .navigationDestination(item: $selectedRecipe) { recipe in
                MatchResultView(recipe: recipe)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pick a song, sound like the record.")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.cream)
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .foregroundStyle(Color.amber)
                Text(purchaseManager.isPro || purchaseManager.hasBYOLifetime
                     ? "Pro active — unlimited matches"
                     : "\(max(0, AppConstants.freeMatchesPerDay - quotaManager.matchesToday)) free match today, forever")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.cream.opacity(0.7))
            }
        }
        .padding(.top, 4)
    }

    private var dropsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Weekly Tone Drops")
                    .font(.headline)
                    .foregroundStyle(Color.cream)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.amber)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.weeklyDrops) { recipe in
                        Button {
                            selectedRecipe = recipe
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.song)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color.cream)
                                    .lineLimit(1)
                                Text(recipe.artist)
                                    .font(.caption)
                                    .foregroundStyle(Color.cream.opacity(0.6))
                                    .lineLimit(1)
                            }
                            .padding(12)
                            .frame(width: 200, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.tolexCard))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.amber.opacity(0.4), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Weekly drop: \(recipe.song) by \(recipe.artist)")
                    }
                }
            }
        }
    }

    private var songGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.searchText.isEmpty ? "Hot Songs" : "Results")
                .font(.headline)
                .foregroundStyle(Color.cream)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(viewModel.filtered.prefix(120)) { recipe in
                    Button {
                        selectedRecipe = recipe
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.song)
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.cream)
                                .lineLimit(1)
                            Text(recipe.artist)
                                .font(.caption2)
                                .foregroundStyle(Color.cream.opacity(0.6))
                                .lineLimit(1)
                            Text(recipe.genre.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.amber.opacity(0.8))
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.tolexCard))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Song: \(recipe.song) by \(recipe.artist)")
                }
            }
            if viewModel.filtered.isEmpty {
                Text("No songs match your search. Try another title or artist.")
                    .font(.caption)
                    .foregroundStyle(Color.cream.opacity(0.6))
                    .padding(.vertical, 20)
            }
        }
    }
}
