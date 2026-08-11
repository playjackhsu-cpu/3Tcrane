import Foundation

protocol QuestionRepository {
    func load() throws -> QuestionBankPackage
}

enum QuestionRepositoryError: LocalizedError, Equatable {
    case missingResource(String)
    case unsupportedSchema(Int)
    case invalidQuestion(String)
    case duplicateIdentifier(String)
    case invalidReference(String)
    case invalidReviewException(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            "找不到內建題庫資源：\(name)"
        case .unsupportedSchema(let version):
            "不支援題庫結構版本：\(version)"
        case .invalidQuestion(let id):
            "題目資料不完整：\(id)"
        case .duplicateIdentifier(let id):
            "題庫包含重複識別碼：\(id)"
        case .invalidReference(let id):
            "題目分類關聯無效：\(id)"
        case .invalidReviewException(let id):
            "題庫例外審查資料不完整：\(id)"
        }
    }
}

struct BundleQuestionRepository: QuestionRepository {
    let bundle: Bundle
    let resourceName: String

    init(bundle: Bundle = .main, resourceName: String? = nil) {
        self.bundle = bundle
        if let resourceName {
            self.resourceName = resourceName
        } else if bundle.url(forResource: "question-bank.internal", withExtension: "json") != nil {
            self.resourceName = "question-bank.internal"
        } else {
            self.resourceName = "question-bank.synthetic"
        }
    }

    func load() throws -> QuestionBankPackage {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw QuestionRepositoryError.missingResource("\(resourceName).json")
        }
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        return try Self.decodeAndValidate(data)
    }

    static func decodeAndValidate(_ data: Data) throws -> QuestionBankPackage {
        let package = try JSONDecoder().decode(QuestionBankPackage.self, from: data)
        guard package.schemaVersion == 1 else {
            throw QuestionRepositoryError.unsupportedSchema(package.schemaVersion)
        }
        try validateUniqueIDs(package.subjects.map(\.id))
        try validateUniqueIDs(package.chapters.map(\.id))
        try validateUniqueIDs(package.questions.map(\.id))

        let subjectIDs = Set(package.subjects.map(\.id))
        let chapterIDs = Set(package.chapters.map(\.id))
        let chapterSubject = Dictionary(uniqueKeysWithValues: package.chapters.map { ($0.id, $0.subjectId) })
        for chapter in package.chapters where !subjectIDs.contains(chapter.subjectId) {
            throw QuestionRepositoryError.invalidReference(chapter.id)
        }
        for question in package.questions {
            guard question.options.count == 4,
                  question.options.indices.contains(question.answerIndex),
                  question.answer == question.options[question.answerIndex],
                  !question.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  Set(question.options).count == question.options.count
            else {
                throw QuestionRepositoryError.invalidQuestion(question.id)
            }
            if let optionImageResources = question.optionImageResources,
               optionImageResources.count != question.options.count {
                throw QuestionRepositoryError.invalidQuestion(question.id)
            }
            guard subjectIDs.contains(question.subjectId),
                  chapterIDs.contains(question.chapterId),
                  chapterSubject[question.chapterId] == question.subjectId
            else {
                throw QuestionRepositoryError.invalidReference(question.id)
            }
        }
        let questionIDs = Set(package.questions.map(\.id))
        let reviewExceptions = package.reviewExceptions ?? []
        try validateUniqueIDs(reviewExceptions.map(\.id))
        let allowedCategories = Set([
            "official-deleted",
            "hard-answer-conflict",
            "regulatory-transition-hold",
        ])
        for item in reviewExceptions {
            guard !questionIDs.contains(item.id),
                  allowedCategories.contains(item.category),
                  !item.publicCode.isEmpty,
                  !item.prompt.isEmpty,
                  !item.officialPrintedAnswer.isEmpty,
                  !item.reviewedAnswer.isEmpty,
                  !item.reason.isEmpty,
                  item.publicSourceURL != nil
            else {
                throw QuestionRepositoryError.invalidReviewException(item.id)
            }
        }
        return package
    }

    private static func validateUniqueIDs(_ ids: [String]) throws {
        var seen = Set<String>()
        for id in ids {
            guard !id.isEmpty, seen.insert(id).inserted else {
                throw QuestionRepositoryError.duplicateIdentifier(id)
            }
        }
    }
}

@MainActor
final class ContentStore: ObservableObject {
    @Published private(set) var package: QuestionBankPackage?
    @Published private(set) var loadingError: String?

    init(repository: any QuestionRepository = BundleQuestionRepository()) {
        do {
            package = try repository.load()
            loadingError = nil
        } catch {
            package = nil
            loadingError = error.localizedDescription
        }
    }

    var questions: [StudyQuestion] { package?.questions ?? [] }
    var reviewExceptions: [ReviewException] { package?.reviewExceptions ?? [] }
    var contentVersion: String { package?.contentVersion ?? "未載入" }

    func question(id: String) -> StudyQuestion? {
        questions.first { $0.id == id }
    }

    func questions(in chapterID: String) -> [StudyQuestion] {
        questions.filter { $0.chapterId == chapterID }
    }
}
