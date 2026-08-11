import SwiftData
import SwiftUI

@main
struct ThreeTCraneStudyApp: App {
    private let modelContainer: ModelContainer?
    private let persistenceError: String?
    @StateObject private var contentStore: ContentStore

    init() {
        _contentStore = StateObject(wrappedValue: ContentStore())
        do {
            let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
            modelContainer = try LearningPersistence.makeContainer(inMemory: isUITesting)
            persistenceError = nil
        } catch {
            modelContainer = nil
            persistenceError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                AppShell()
                    .environmentObject(contentStore)
                    .modelContainer(modelContainer)
            } else {
                PersistenceFailureView(message: persistenceError ?? "無法開啟學習紀錄。")
            }
        }
    }
}

private struct PersistenceFailureView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("學習紀錄暫時無法開啟", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("為保護既有紀錄，App 已停止寫入，且不會建立空白資料覆蓋原檔。\n\(message)")
        }
        .padding()
        .accessibilityIdentifier("persistenceFailure")
    }
}
