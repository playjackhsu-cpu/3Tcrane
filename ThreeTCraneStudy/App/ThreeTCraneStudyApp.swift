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
            let launchArguments = ProcessInfo.processInfo.arguments
            let isUITesting = launchArguments.contains("-ui-testing")
            let container = try LearningPersistence.makeContainer(inMemory: isUITesting)
            let seedsReviewReorder = launchArguments.contains("-ui-seed-wrong-review-reorder")
            let seedsReviewRemoval = launchArguments.contains("-ui-seed-wrong-review-removal")
            if isUITesting && (seedsReviewReorder || seedsReviewRemoval) {
                // 僅在記憶體測試 store 建立兩題錯題：第二題較新，作答第一題時
                // @Query 會重新排序或移除，藉此驗證畫面仍停留在作答的原題。
                let context = container.mainContext
                context.insert(QuestionProgress(
                    questionID: "crane-06100-w01-q001",
                    attemptCount: seedsReviewRemoval ? 3 : 1,
                    correctCount: seedsReviewRemoval ? 2 : 0,
                    lastAnsweredAt: .now.addingTimeInterval(-120),
                    masteryState: seedsReviewRemoval
                        ? MasteryState.reviewRecoveryCorrectOnce.rawValue
                        : MasteryState.needsReview.rawValue
                ))
                context.insert(QuestionProgress(
                    questionID: "crane-06100-w01-q002",
                    attemptCount: 1,
                    correctCount: 0,
                    lastAnsweredAt: .now.addingTimeInterval(-60),
                    masteryState: MasteryState.needsReview.rawValue
                ))
                try context.save()
            }
            modelContainer = container
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
