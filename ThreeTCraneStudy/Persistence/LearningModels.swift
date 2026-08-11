import Foundation
import SwiftData

enum MasteryState: String {
    case new
    case learning
    case needsReview = "needs-review"
    case mastered
}

struct ExamQuestionSnapshot: Codable, Equatable, Identifiable {
    let id: String
    let publicCode: String
    let prompt: String
    let options: [String]
    let answerIndex: Int
    let answer: String
    let explanation: String
    let imageResource: String?
    let imageAccessibilityLabel: String?
    let optionImageResources: [String?]?
    var selectedIndex: Int?

    init(question: StudyQuestion, selectedIndex: Int? = nil) {
        id = question.id
        publicCode = question.publicCode
        prompt = question.prompt
        options = question.options
        answerIndex = question.answerIndex
        answer = question.answer
        explanation = question.explanation
        imageResource = question.imageResource
        imageAccessibilityLabel = question.imageAccessibilityLabel
        optionImageResources = question.optionImageResources
        self.selectedIndex = selectedIndex
    }
}

struct ExamSessionSnapshot: Codable, Equatable {
    var questions: [ExamQuestionSnapshot]
    var currentIndex: Int
    let timeLimitSeconds: Int

    var answeredCount: Int {
        questions.filter { $0.selectedIndex != nil }.count
    }

    var correctCount: Int {
        questions.filter { $0.selectedIndex == $0.answerIndex }.count
    }

    var scorePercent: Int {
        guard !questions.isEmpty else { return 0 }
        return Int((Double(correctCount) / Double(questions.count) * 100).rounded())
    }
}

@Model
final class QuestionProgress {
    @Attribute(.unique) var questionID: String
    var attemptCount: Int
    var correctCount: Int
    var lastAnswerIndex: Int?
    var lastAnsweredAt: Date?
    var masteryState: String

    init(
        questionID: String,
        attemptCount: Int = 0,
        correctCount: Int = 0,
        lastAnswerIndex: Int? = nil,
        lastAnsweredAt: Date? = nil,
        masteryState: String = MasteryState.new.rawValue
    ) {
        self.questionID = questionID
        self.attemptCount = attemptCount
        self.correctCount = correctCount
        self.lastAnswerIndex = lastAnswerIndex
        self.lastAnsweredAt = lastAnsweredAt
        self.masteryState = masteryState
    }
}

@Model
final class Favorite {
    @Attribute(.unique) var questionID: String
    var createdAt: Date

    init(questionID: String, createdAt: Date = .now) {
        self.questionID = questionID
        self.createdAt = createdAt
    }
}

@Model
final class QuestionNote {
    @Attribute(.unique) var questionID: String
    var text: String
    var updatedAt: Date

    init(questionID: String, text: String, updatedAt: Date = .now) {
        self.questionID = questionID
        self.text = text
        self.updatedAt = updatedAt
    }
}

@Model
final class ExamAttempt {
    @Attribute(.unique) var id: UUID
    var contentVersion: String
    var startedAt: Date
    var submittedAt: Date?
    var score: Int?
    var durationSeconds: Int
    var questionSnapshotData: Data

    init(
        id: UUID = UUID(),
        contentVersion: String,
        startedAt: Date = .now,
        submittedAt: Date? = nil,
        score: Int? = nil,
        durationSeconds: Int = 0,
        questionSnapshotData: Data = Data()
    ) {
        self.id = id
        self.contentVersion = contentVersion
        self.startedAt = startedAt
        self.submittedAt = submittedAt
        self.score = score
        self.durationSeconds = durationSeconds
        self.questionSnapshotData = questionSnapshotData
    }
}

@Model
final class AppState {
    @Attribute(.unique) var key: String
    var lastQuestionID: String?
    var lastOpenedAppBuild: String
    var lastSeenContentVersion: String
    var migrationVersion: Int

    init(
        key: String = "primary",
        lastQuestionID: String? = nil,
        lastOpenedAppBuild: String = "",
        lastSeenContentVersion: String = "",
        migrationVersion: Int = 1
    ) {
        self.key = key
        self.lastQuestionID = lastQuestionID
        self.lastOpenedAppBuild = lastOpenedAppBuild
        self.lastSeenContentVersion = lastSeenContentVersion
        self.migrationVersion = migrationVersion
    }
}
