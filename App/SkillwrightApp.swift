import SwiftUI

@main
struct SkillwrightApp: App {
    @State private var workspace = Workspace()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(workspace)
                .tint(Theme.label)
        }
    }
}

/// Tab bar: Files / Recents / Settings (design spec §2). Recents and Settings are placeholders
/// in this first build.
struct RootView: View {
    var body: some View {
        TabView {
            Tab("Files", systemImage: "folder.fill") {
                NavigationStack { LibraryView(folder: nil) }
            }
            Tab("Recents", systemImage: "clock.fill") {
                NavigationStack { RecentsView() }
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                NavigationStack { SettingsView() }
            }
        }
    }
}
