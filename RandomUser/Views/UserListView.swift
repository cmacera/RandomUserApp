//
//  UserListView.swift
//  RandomUser
//

import SwiftUI
import SwiftData

/// Main screen: a deduplicated, persisted list of random users with infinite scroll,
/// search, swipe-to-delete, and navigation to detail. Reads come from `@Query` (the
/// store is the source of truth); the view model owns the search term and commands.
struct UserListView: View {
    @Query(sort: [SortDescriptor(\UserModel.sortOrder)]) private var users: [UserModel]
    @State private var viewModel: UserListViewModel

    init(repository: UserRepositoryProtocol) {
        _viewModel = State(initialValue: UserListViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            let visible = viewModel.filtered(users)
            List {
                ForEach(visible) { user in
                    NavigationLink(value: user) {
                        UserRow(user: user)
                    }
                    .onAppear { loadMoreIfNearEnd(at: user, in: visible) }
                }
                .onDelete { offsets in
                    for index in offsets { viewModel.delete(visible[index]) }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Users")
            .navigationDestination(for: UserModel.self) { user in
                UserDetailView(user: user)
            }
            .searchable(text: $viewModel.searchText, prompt: "Name, surname or email")
            .overlay { emptyState(visible) }
            .safeAreaInset(edge: .bottom) { loadingBar }
            .task { await viewModel.loadInitialIfNeeded(currentCount: users.count) }
        }
    }

    /// Loading bar pinned below the list via `safeAreaInset` — stays visible while a
    /// page loads, unlike an in-list footer that scrolls with the content and gets
    /// pushed off as new rows arrive.
    @ViewBuilder
    private var loadingBar: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
    }

    /// Infinite scroll: load the next page when any of the last few rows appears.
    /// `.onAppear` is attached to every row, but `List` is lazy — it only fires for the
    /// cells actually on screen. Triggering on the last *five* (not just the last) is
    /// both a prefetch and a safety net against `onAppear` not firing for the very last
    /// row. Suppressed while searching, where the user filters the already-loaded set.
    private func loadMoreIfNearEnd(at user: UserModel, in visible: [UserModel]) {
        guard viewModel.searchTerm.isEmpty,
              let index = visible.firstIndex(where: { $0.uuid == user.uuid }),
              index >= visible.count - 5
        else { return }
        Task { await viewModel.loadMore() }
    }

    @ViewBuilder
    private func emptyState(_ visible: [UserModel]) -> some View {
        if visible.isEmpty && !viewModel.isLoading {
            if viewModel.searchTerm.isEmpty {
                ContentUnavailableView("No users yet", systemImage: "person.3")
            } else {
                ContentUnavailableView.search(text: viewModel.searchTerm)
            }
        }
    }
}

#if DEBUG
#Preview("Seeded") {
    let container = previewContainer()
    UserListView(repository: previewRepository(container))
        .modelContainer(container)
}

#Preview("Empty") {
    let container = previewContainer([])
    UserListView(repository: previewRepository(container))
        .modelContainer(container)
}
#endif
