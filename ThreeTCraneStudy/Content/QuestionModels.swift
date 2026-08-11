import Foundation

struct QuestionBankPackage: Codable, Equatable {
    let schemaVersion: Int
    let contentVersion: String
    let generatedAt: String?
    let sourceSystem: String?
    let license: ContentLicense?
    let isSynthetic: Bool?
    let subjects: [QuestionSubject]
    let chapters: [QuestionChapter]
    let questions: [StudyQuestion]
    let reviewExceptions: [ReviewException]?
}

struct ContentLicense: Codable, Equatable {
    let name: String
    let url: String
    let attribution: String
    let checkedAt: String

    var licenseURL: URL? {
        URL(string: url)
    }
}

struct ReviewException: Codable, Identifiable, Equatable {
    let id: String
    let publicCode: String
    let category: String
    let subjectTitle: String
    let chapterTitle: String
    let prompt: String
    let officialPrintedAnswer: String
    let reviewedAnswer: String
    let reason: String
    let publicSource: String
    let publicSourceUrl: String
    let publicSourceCheckedAt: String

    var publicSourceURL: URL? {
        guard !publicSourceUrl.isEmpty else { return nil }
        return URL(string: publicSourceUrl)
    }
}

struct QuestionSubject: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let order: Int
}

struct QuestionChapter: Codable, Identifiable, Equatable {
    let id: String
    let subjectId: String
    let title: String
    let order: Int
}

struct StudyQuestion: Codable, Identifiable, Equatable {
    let id: String
    let publicCode: String
    let subjectId: String
    let chapterId: String
    let kind: String
    let prompt: String
    let options: [String]
    let answerIndex: Int
    let answer: String
    let explanation: String
    let alternativeAnswer: String
    let publicSource: String
    let publicSourceUrl: String
    let publicSourceCheckedAt: String
    let accuracyStatus: String
    let rightsStatus: String
    let imageResource: String?
    let imageAccessibilityLabel: String?
    let optionImageResources: [String?]?

    var publicSourceURL: URL? {
        guard !publicSourceUrl.isEmpty else { return nil }
        return URL(string: publicSourceUrl)
    }
}
