import SwiftUI

struct RootView: View {
    @State private var downloadsViewModel = DownloadsViewModel(
        downloadRepository: URLSessionDownloadRepository(
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
        NavigationSplitView {
            List {
                NavigationLink("Search", value: AppTab.search)
                NavigationLink("Downloads", value: AppTab.downloads)
            }
        } detail: {
            HomeViewMacOS()
                .environment(downloadsViewModel)
        }
        #endif
    }

}

private enum AppTab {
    case search, downloads
}
