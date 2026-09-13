import Foundation
import SwiftData

enum LearningPersistence {
    static let schema = Schema([
        QuestionProgress.self,
        Favorite.self,
        QuestionNote.self,
        ExamAttempt.self,
        AppState.self,
    ])

    static func makeContainer(
        inMemory: Bool = false,
        storeURL: URL? = nil
    ) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(
                "LearningStore",
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        } else {
            let url = try storeURL ?? defaultStoreURL()
            configuration = ModelConfiguration(
                "LearningStore",
                schema: schema,
                url: url,
                allowsSave: true,
                cloudKitDatabase: .none
            )
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func defaultStoreURL(fileManager: FileManager = .default) throws -> URL {
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = applicationSupport
            .appendingPathComponent("ThreeTCraneStudy", isDirectory: true)
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory.appendingPathComponent("LearningStore.store")
    }

    @MainActor
    static func recordAnswer(
        questionID: String,
        selectedIndex: Int,
        correctIndex: Int,
        mode: AnswerRecordingMode = .regular,
        in context: ModelContext,
        answeredAt: Date = .now
    ) throws {
        let stableID = questionID
        let descriptor = FetchDescriptor<QuestionProgress>(
            predicate: #Predicate { $0.questionID == stableID }
        )
        let progress = try context.fetch(descriptor).first
            ?? QuestionProgress(questionID: questionID)
        if progress.modelContext == nil {
            context.insert(progress)
        }
        let previousState = MasteryState(rawValue: progress.masteryState) ?? .new
        let wasLegacyReview = previousState == .learning
            && progress.attemptCount > progress.correctCount
        progress.attemptCount += 1
        if selectedIndex == correctIndex {
            progress.correctCount += 1
            if mode == .wrongAnswerReview, previousState.explicitlyNeedsReview || wasLegacyReview {
                switch previousState {
                case .needsReview:
                    progress.masteryState = MasteryState.reviewCorrectOnce.rawValue
                case .reviewCorrectOnce:
                    progress.masteryState = MasteryState.reviewCorrectTwice.rawValue
                case .learning where wasLegacyReview:
                    progress.masteryState = MasteryState.reviewCorrectOnce.rawValue
                case .reviewCorrectTwice:
                    progress.masteryState = MasteryState.mastered.rawValue
                default:
                    progress.masteryState = MasteryState.reviewCorrectOnce.rawValue
                }
            } else if previousState.explicitlyNeedsReview || wasLegacyReview {
                // 只有「錯題複習」中的連續答對會消除錯題；其他模式答對不會
                // 偷渡累加熟練次數，避免模擬測驗或全題庫練習意外清空錯題。
                progress.masteryState = previousState.rawValue
            } else {
                progress.masteryState = progress.correctCount >= 2
                    ? MasteryState.mastered.rawValue
                    : MasteryState.learning.rawValue
            }
        } else {
            progress.masteryState = MasteryState.needsReview.rawValue
        }
        progress.lastAnswerIndex = selectedIndex
        progress.lastAnsweredAt = answeredAt
        try context.save()
    }

    @MainActor
    @discardableResult
    static func toggleFavorite(
        questionID: String,
        in context: ModelContext,
        at date: Date = .now
    ) throws -> Bool {
        let stableID = questionID
        let descriptor = FetchDescriptor<Favorite>(
            predicate: #Predicate { $0.questionID == stableID }
        )
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
            return false
        }
        context.insert(Favorite(questionID: questionID, createdAt: date))
        try context.save()
        return true
    }

    @MainActor
    static func saveNote(
        questionID: String,
        text: String,
        in context: ModelContext,
        at date: Date = .now
    ) throws {
        let stableID = questionID
        let descriptor = FetchDescriptor<QuestionNote>(
            predicate: #Predicate { $0.questionID == stableID }
        )
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = try context.fetch(descriptor).first {
            if normalizedText.isEmpty {
                context.delete(existing)
            } else {
                existing.text = normalizedText
                existing.updatedAt = date
            }
        } else if !normalizedText.isEmpty {
            context.insert(QuestionNote(questionID: questionID, text: normalizedText, updatedAt: date))
        }
        try context.save()
    }

    @MainActor
    static func saveLastQuestion(
        questionID: String?,
        contentVersion: String,
        appBuild: String,
        stateKey: String = "primary",
        in context: ModelContext
    ) throws {
        let primaryKey = stateKey
        let descriptor = FetchDescriptor<AppState>(
            predicate: #Predicate { $0.key == primaryKey }
        )
        let state = try context.fetch(descriptor).first ?? AppState(key: stateKey)
        if state.modelContext == nil {
            context.insert(state)
        }
        state.lastQuestionID = questionID
        state.lastSeenContentVersion = contentVersion
        state.lastOpenedAppBuild = appBuild
        try context.save()
    }

    @MainActor
    static func startExam(
        questions: [StudyQuestion],
        contentVersion: String,
        timeLimitSeconds: Int,
        in context: ModelContext,
        startedAt: Date = .now
    ) throws -> ExamAttempt {
        let unfinished = try context.fetch(
            FetchDescriptor<ExamAttempt>(predicate: #Predicate { $0.submittedAt == nil })
        )
        unfinished.forEach(context.delete)

        let examQuestions = questions.map { question in
            ExamQuestionSnapshot(question: question)
        }
        let snapshot = ExamSessionSnapshot(
            questions: examQuestions,
            currentIndex: 0,
            timeLimitSeconds: timeLimitSeconds
        )
        let attempt = ExamAttempt(
            contentVersion: contentVersion,
            startedAt: startedAt,
            questionSnapshotData: try encodeExamSnapshot(snapshot)
        )
        context.insert(attempt)
        try context.save()
        return attempt
    }

    @MainActor
    static func updateExam(
        _ attempt: ExamAttempt,
        selectedIndex: Int,
        questionIndex: Int,
        currentIndex: Int,
        in context: ModelContext
    ) throws {
        var snapshot = try decodeExamSnapshot(from: attempt)
        guard snapshot.questions.indices.contains(questionIndex),
              snapshot.questions[questionIndex].options.indices.contains(selectedIndex)
        else { throw ExamSnapshotError.invalidSelection }
        snapshot.questions[questionIndex].selectedIndex = selectedIndex
        snapshot.currentIndex = min(max(0, currentIndex), max(0, snapshot.questions.count - 1))
        attempt.questionSnapshotData = try encodeExamSnapshot(snapshot)
        try context.save()
    }

    @MainActor
    @discardableResult
    static func submitExam(
        _ attempt: ExamAttempt,
        in context: ModelContext,
        submittedAt: Date = .now
    ) throws -> ExamSessionSnapshot {
        let snapshot = try decodeExamSnapshot(from: attempt)
        for question in snapshot.questions {
            if let selectedIndex = question.selectedIndex {
                try recordAnswer(
                    questionID: question.id,
                    selectedIndex: selectedIndex,
                    correctIndex: question.answerIndex,
                    in: context,
                    answeredAt: submittedAt
                )
            }
        }
        attempt.submittedAt = submittedAt
        attempt.score = snapshot.scorePercent
        attempt.durationSeconds = max(0, Int(submittedAt.timeIntervalSince(attempt.startedAt)))
        attempt.questionSnapshotData = try encodeExamSnapshot(snapshot)
        try context.save()
        return snapshot
    }

    static func encodeExamSnapshot(_ snapshot: ExamSessionSnapshot) throws -> Data {
        try JSONEncoder().encode(snapshot)
    }

    static func decodeExamSnapshot(from attempt: ExamAttempt) throws -> ExamSessionSnapshot {
        try JSONDecoder().decode(ExamSessionSnapshot.self, from: attempt.questionSnapshotData)
    }
}

enum ExamSnapshotError: LocalizedError {
    case invalidSelection

    var errorDescription: String? {
        "測驗作答資料不完整。"
    }
}
