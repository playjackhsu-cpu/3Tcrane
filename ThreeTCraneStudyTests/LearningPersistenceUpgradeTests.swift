import SwiftData
import XCTest
@testable import ThreeTCraneStudy

@MainActor
final class LearningPersistenceUpgradeTests: XCTestCase {
    func testAppUpdateReopenPreservesEveryLearningRecordType() throws {
        let testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("3tcrane-upgrade-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        let storeURL = testDirectory.appendingPathComponent("LearningStore.store")
        defer { try? FileManager.default.removeItem(at: testDirectory) }

        try seedVersionA(at: storeURL)
        try verifyVersionB(at: storeURL)
    }

    func testContentRemovalKeepsOrphanedProgressByStableID() throws {
        let container = try LearningPersistence.makeContainer(inMemory: true)
        let context = container.mainContext
        context.insert(QuestionProgress(questionID: "retired-question", attemptCount: 3, correctCount: 1))
        try context.save()

        let records = try context.fetch(FetchDescriptor<QuestionProgress>())
        XCTAssertEqual(records.map(\.questionID), ["retired-question"])
    }

    func testWrongReviewFirstCorrectClearsAndReviewMistakeRequiresTwoConsecutiveCorrect() throws {
        let container = try LearningPersistence.makeContainer(inMemory: true)
        let context = container.mainContext

        try LearningPersistence.recordAnswer(
            questionID: "fixture-choice-001",
            selectedIndex: 1,
            correctIndex: 0,
            in: context
        )
        var progress = try XCTUnwrap(context.fetch(FetchDescriptor<QuestionProgress>()).first)
        XCTAssertEqual(progress.masteryState, MasteryState.needsReview.rawValue)
        XCTAssertEqual(progress.wrongAnswerReviewStreak, 0)

        try LearningPersistence.recordAnswer(
            questionID: "fixture-choice-001",
            selectedIndex: 0,
            correctIndex: 0,
            mode: .wrongAnswerReview,
            in: context
        )
        progress = try XCTUnwrap(context.fetch(FetchDescriptor<QuestionProgress>()).first)
        XCTAssertEqual(progress.masteryState, MasteryState.mastered.rawValue)
        XCTAssertFalse(progress.needsWrongAnswerReview)

        // 再次答錯會重新進錯題池；在錯題複習內答錯後須連勝兩次。
        try LearningPersistence.recordAnswer(
            questionID: "fixture-choice-001",
            selectedIndex: 1,
            correctIndex: 0,
            in: context
        )
        try LearningPersistence.recordAnswer(
            questionID: "fixture-choice-001",
            selectedIndex: 2,
            correctIndex: 0,
            mode: .wrongAnswerReview,
            in: context
        )
        progress = try XCTUnwrap(context.fetch(FetchDescriptor<QuestionProgress>()).first)
        XCTAssertEqual(progress.masteryState, MasteryState.reviewRecoveryNeeded.rawValue)
        XCTAssertTrue(progress.requiresTwoCorrectReviews)
        XCTAssertEqual(progress.wrongAnswerReviewStreak, 0)

        try LearningPersistence.recordAnswer(
            questionID: "fixture-choice-001",
            selectedIndex: 0,
            correctIndex: 0,
            mode: .wrongAnswerReview,
            in: context
        )
        progress = try XCTUnwrap(context.fetch(FetchDescriptor<QuestionProgress>()).first)
        XCTAssertEqual(progress.masteryState, MasteryState.reviewRecoveryCorrectOnce.rawValue)
        XCTAssertEqual(progress.wrongAnswerReviewStreak, 1)
        XCTAssertTrue(progress.needsWrongAnswerReview)

        try LearningPersistence.recordAnswer(
            questionID: "fixture-choice-001",
            selectedIndex: 2,
            correctIndex: 0,
            mode: .wrongAnswerReview,
            in: context
        )
        progress = try XCTUnwrap(context.fetch(FetchDescriptor<QuestionProgress>()).first)
        XCTAssertEqual(progress.masteryState, MasteryState.reviewRecoveryNeeded.rawValue)
        XCTAssertEqual(progress.wrongAnswerReviewStreak, 0)

        for expectedStreak in 1...2 {
            try LearningPersistence.recordAnswer(
                questionID: "fixture-choice-001",
                selectedIndex: 0,
                correctIndex: 0,
                mode: .wrongAnswerReview,
                in: context
            )
            progress = try XCTUnwrap(context.fetch(FetchDescriptor<QuestionProgress>()).first)
            if expectedStreak == 1 {
                XCTAssertEqual(progress.wrongAnswerReviewStreak, 1)
            }
        }
        XCTAssertEqual(progress.masteryState, MasteryState.mastered.rawValue)
        XCTAssertFalse(progress.needsWrongAnswerReview)
    }

    func testExistingOneOrTwoCorrectReviewsDisappearAfterReopenWithoutDeletingRecords() throws {
        let testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("3tcrane-review-upgrade-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        let storeURL = testDirectory.appendingPathComponent("LearningStore.store")
        defer { try? FileManager.default.removeItem(at: testDirectory) }

        do {
            let container = try LearningPersistence.makeContainer(storeURL: storeURL)
            let context = container.mainContext
            context.insert(QuestionProgress(
                questionID: "old-correct-once", attemptCount: 2, correctCount: 1,
                masteryState: MasteryState.reviewCorrectOnce.rawValue
            ))
            context.insert(QuestionProgress(
                questionID: "old-correct-twice", attemptCount: 3, correctCount: 2,
                masteryState: MasteryState.reviewCorrectTwice.rawValue
            ))
            context.insert(QuestionProgress(
                questionID: "old-unreviewed", attemptCount: 1, correctCount: 0,
                masteryState: MasteryState.needsReview.rawValue
            ))
            try context.save()
        }

        let reopened = try LearningPersistence.makeContainer(storeURL: storeURL)
        let records = try reopened.mainContext.fetch(FetchDescriptor<QuestionProgress>())
        XCTAssertEqual(records.count, 3)
        XCTAssertEqual(Set(records.filter(\.needsWrongAnswerReview).map(\.questionID)), ["old-unreviewed"])
        XCTAssertEqual(records.first(where: { $0.questionID == "old-correct-once" })?.correctCount, 1)
        XCTAssertEqual(records.first(where: { $0.questionID == "old-correct-twice" })?.correctCount, 2)
    }

    func testRegularCorrectAnswerDoesNotAdvanceWrongAnswerReviewStreak() throws {
        let container = try LearningPersistence.makeContainer(inMemory: true)
        let context = container.mainContext

        try LearningPersistence.recordAnswer(
            questionID: "fixture-choice-001",
            selectedIndex: 1,
            correctIndex: 0,
            in: context
        )
        try LearningPersistence.recordAnswer(
            questionID: "fixture-choice-001",
            selectedIndex: 0,
            correctIndex: 0,
            in: context
        )

        let progress = try XCTUnwrap(context.fetch(FetchDescriptor<QuestionProgress>()).first)
        XCTAssertEqual(progress.masteryState, MasteryState.needsReview.rawValue)
        XCTAssertEqual(progress.wrongAnswerReviewStreak, 0)
    }

    func testFullQuestionBankPositionIsIndependentFromCoursePosition() throws {
        let container = try LearningPersistence.makeContainer(inMemory: true)
        let context = container.mainContext

        try LearningPersistence.saveLastQuestion(
            questionID: "course-question",
            contentVersion: "0.2.1",
            appBuild: "6",
            in: context
        )
        try LearningPersistence.saveLastQuestion(
            questionID: "full-practice-question",
            contentVersion: "0.2.1",
            appBuild: "7",
            stateKey: PracticeMode.fullQuestionBankStateKey,
            in: context
        )

        let states = try context.fetch(FetchDescriptor<AppState>())
        XCTAssertEqual(states.count, 2)
        XCTAssertEqual(states.first(where: { $0.key == "primary" })?.lastQuestionID, "course-question")
        XCTAssertEqual(
            states.first(where: { $0.key == PracticeMode.fullQuestionBankStateKey })?.lastQuestionID,
            "full-practice-question"
        )
    }

    func testFavoriteAndNoteCanBeUpdatedWithoutDuplicates() throws {
        let container = try LearningPersistence.makeContainer(inMemory: true)
        let context = container.mainContext

        XCTAssertTrue(try LearningPersistence.toggleFavorite(questionID: "fixture-choice-001", in: context))
        XCTAssertFalse(try LearningPersistence.toggleFavorite(questionID: "fixture-choice-001", in: context))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Favorite>()), 0)

        try LearningPersistence.saveNote(
            questionID: "fixture-choice-001",
            text: "第一版",
            in: context
        )
        try LearningPersistence.saveNote(
            questionID: "fixture-choice-001",
            text: "第二版",
            in: context
        )
        let notes = try context.fetch(FetchDescriptor<QuestionNote>())
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.text, "第二版")
    }

    func testExamSnapshotCanResumeAndSubmit() throws {
        let package = try BundleQuestionRepository(
            bundle: Bundle(for: Self.self),
            resourceName: "question-bank.synthetic"
        ).load()
        let container = try LearningPersistence.makeContainer(inMemory: true)
        let context = container.mainContext
        let startedAt = Date(timeIntervalSince1970: 1_000)
        let attempt = try LearningPersistence.startExam(
            questions: Array(package.questions.prefix(2)),
            contentVersion: package.contentVersion,
            timeLimitSeconds: 600,
            in: context,
            startedAt: startedAt
        )

        try LearningPersistence.updateExam(
            attempt,
            selectedIndex: package.questions[0].answerIndex,
            questionIndex: 0,
            currentIndex: 1,
            in: context
        )
        try LearningPersistence.updateExam(
            attempt,
            selectedIndex: (package.questions[1].answerIndex + 1) % 4,
            questionIndex: 1,
            currentIndex: 1,
            in: context
        )

        let resumed = try LearningPersistence.decodeExamSnapshot(from: attempt)
        XCTAssertEqual(resumed.currentIndex, 1)
        XCTAssertEqual(resumed.answeredCount, 2)

        let result = try LearningPersistence.submitExam(
            attempt,
            in: context,
            submittedAt: Date(timeIntervalSince1970: 1_060)
        )
        XCTAssertEqual(result.scorePercent, 50)
        XCTAssertEqual(attempt.score, 50)
        XCTAssertEqual(attempt.durationSeconds, 60)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<QuestionProgress>()), 2)
    }

    func testFormalExamUsesOfficialSubjectDistribution() {
        var questions = (0..<70).map { makeQuestion(subjectID: "06100", index: $0) }
        for subjectID in ExamQuestionSelector.commonSubjectIDs {
            questions += (0..<10).map { makeQuestion(subjectID: subjectID, index: $0) }
        }

        let selected = ExamQuestionSelector.formal(from: questions)

        XCTAssertEqual(selected.count, 80)
        XCTAssertEqual(selected.filter { $0.subjectId == "06100" }.count, 64)
        for subjectID in ExamQuestionSelector.commonSubjectIDs {
            XCTAssertEqual(selected.filter { $0.subjectId == subjectID }.count, 4)
        }
        XCTAssertEqual(Set(selected.map(\.id)).count, 80)
    }

    func testFormalExamRejectsAnIncompleteCommonSubjectPool() {
        var questions = (0..<64).map { makeQuestion(subjectID: "06100", index: $0) }
        questions += (0..<3).map { makeQuestion(subjectID: "90006", index: $0) }
        for subjectID in ["90007", "90008", "90009"] {
            questions += (0..<4).map { makeQuestion(subjectID: subjectID, index: $0) }
        }

        XCTAssertFalse(ExamQuestionSelector.canCreateFormal(from: questions))
        XCTAssertTrue(ExamQuestionSelector.formal(from: questions).isEmpty)
    }

    private func makeQuestion(subjectID: String, index: Int) -> StudyQuestion {
        StudyQuestion(
            id: "\(subjectID)-\(index)",
            publicCode: "\(subjectID)-\(index)",
            subjectId: subjectID,
            chapterId: "\(subjectID)-chapter",
            kind: "single-choice",
            prompt: "測試題目 \(index)",
            options: ["A", "B", "C", "D"],
            answerIndex: 0,
            answer: "A",
            explanation: "測試解析",
            alternativeAnswer: "",
            publicSource: "公開測試來源",
            publicSourceUrl: "https://example.com",
            publicSourceCheckedAt: "2026-08-11",
            accuracyStatus: "verified",
            rightsStatus: "verified",
            imageResource: nil,
            imageAccessibilityLabel: nil,
            optionImageResources: nil
        )
    }

    private func seedVersionA(at url: URL) throws {
        let container = try LearningPersistence.makeContainer(storeURL: url)
        let context = container.mainContext
        context.insert(QuestionProgress(
            questionID: "fixture-choice-001",
            attemptCount: 2,
            correctCount: 1,
            lastAnswerIndex: 0,
            lastAnsweredAt: Date(timeIntervalSince1970: 100),
            masteryState: "learning"
        ))
        context.insert(Favorite(questionID: "fixture-choice-001"))
        context.insert(QuestionNote(questionID: "fixture-choice-001", text: "保留這則筆記"))
        context.insert(ExamAttempt(
            contentVersion: "0.1.0",
            submittedAt: Date(timeIntervalSince1970: 200),
            score: 100,
            durationSeconds: 30,
            questionSnapshotData: Data("fixture-choice-001".utf8)
        ))
        context.insert(AppState(
            lastQuestionID: "fixture-choice-001",
            lastOpenedAppBuild: "1",
            lastSeenContentVersion: "0.1.0"
        ))
        try context.save()
    }

    private func verifyVersionB(at url: URL) throws {
        let container = try LearningPersistence.makeContainer(storeURL: url)
        let context = container.mainContext

        let progress = try XCTUnwrap(context.fetch(FetchDescriptor<QuestionProgress>()).first)
        XCTAssertEqual(progress.questionID, "fixture-choice-001")
        XCTAssertEqual(progress.attemptCount, 2)
        XCTAssertEqual(progress.correctCount, 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Favorite>()), 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<QuestionNote>()).first?.text, "保留這則筆記")
        XCTAssertEqual(try context.fetch(FetchDescriptor<ExamAttempt>()).first?.score, 100)
        XCTAssertEqual(try context.fetch(FetchDescriptor<AppState>()).first?.lastOpenedAppBuild, "1")
    }
}
