import SwiftUI

struct RootView: View {
    @State private var downloadsViewModel = DownloadsViewModel(
        downloadRepository: BackendDownloadRepository(
            storageRepository: FileManagerStorageRepository()
        ),
        storageRepository: FileManagerStorageRepository()
    )

    var body: some View {
        #if os(iOS)
        TabView {
            HomeViewIOS()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .environment(downloadsViewModel)

            DownloadsViewIOS(viewModel: downloadsViewModel)
                .tabItem { Label("Downloads", systemImage: "arrow.down.circle") }
        }
        .tint(Color.ytAccent)
        #elseif os(macOS)
        MacRootView(downloadsViewModel: downloadsViewModel)
        #endif
    }
}

#if os(macOS)
private struct MacRootView: View {
    let downloadsViewModel: DownloadsViewModel
    @State private var selectedTab: AppTab = .search

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Search", systemImage: "magnifyingglass")
                    .tag(AppTab.search)
                Label("Downloads", systemImage: "arrow.down.circle")
                    .tag(AppTab.downloads)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
            .listStyle(.sidebar)
        } detail: {
            switch selectedTab {
            case .search:
                HomeViewMacOS()
                    .environment(downloadsViewModel)
            case .downloads:
                DownloadsViewMacOS(viewModel: downloadsViewModel)
            }
        }
    }
}
#endif

private enum AppTab: Hashable {
    case search, downloads
}
