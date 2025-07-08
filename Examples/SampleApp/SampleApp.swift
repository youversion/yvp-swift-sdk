import SwiftUI
import YouVersionPlatform

@main
struct SampleApp: App {
    
    @StateObject private var repository = BibleVersionRepository()
    @State private var selectedTab = 0
    
    init() {
        YouVersionPlatform.configure(appId: <#Your App Key#>)
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                BibleView()
                    .tabItem {
                        Label("Bible", systemImage: "book.closed.fill")
                    }
                    .tag(0)
                
                VotdContainerView()
                    .tabItem {
                        Label("VOTD", systemImage: "sun.max.fill")
                    }
                    .tag(1)
                
                VersionView()
                    .tabItem {
                        Label("Versions", systemImage: "books.vertical.fill")
                    }
                    .tag(2)
                
                ContentView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(3)
            }
            .environmentObject(repository)
        }
    }
}
