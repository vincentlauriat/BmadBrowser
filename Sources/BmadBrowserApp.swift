import SwiftUI

@main
struct BmadBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .commands {
            // Conserve « New Window » (⌘N) fourni par WindowGroup, ajoute « Open a Root… ».
            CommandGroup(after: .newItem) {
                OpenRootButton()
            }
        }

        Settings {
            SettingsView()
        }
    }
}

/// Racine d'une fenêtre : possède son propre `AppState` (état indépendant par fenêtre).
struct RootView: View {
    @State private var state = AppState()

    var body: some View {
        ContentView(state: state)
            .frame(minWidth: 800, minHeight: 500)
            .focusedSceneValue(\.appState, state)
    }
}

/// Bouton de menu « Open a Root… » agissant sur la fenêtre active.
private struct OpenRootButton: View {
    @FocusedValue(\.appState) private var appState

    var body: some View {
        Button("Open a Root…") {
            appState?.presentOpenPanel()
        }
        .keyboardShortcut("o", modifiers: .command)
        .disabled(appState == nil)
    }
}

// MARK: - FocusedValue pour atteindre l'AppState de la fenêtre focalisée

private struct AppStateFocusedKey: FocusedValueKey {
    typealias Value = AppState
}

extension FocusedValues {
    var appState: AppState? {
        get { self[AppStateFocusedKey.self] }
        set { self[AppStateFocusedKey.self] = newValue }
    }
}
