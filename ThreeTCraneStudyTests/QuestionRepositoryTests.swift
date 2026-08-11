import XCTest
@testable import ThreeTCraneStudy

final class QuestionRepositoryTests: XCTestCase {
    func testSyntheticBundleDecodesAndPreservesAnswerContract() throws {
        let package = try BundleQuestionRepository(
            bundle: Bundle(for: Self.self),
            resourceName: "question-bank.synthetic"
        ).load()

        XCTAssertEqual(package.schemaVersion, 1)
        XCTAssertEqual(package.contentVersion, "0.1.0")
        XCTAssertEqual(package.isSynthetic, true)
        XCTAssertEqual(package.subjects.count, 2)
        XCTAssertEqual(package.chapters.count, 4)
        XCTAssertEqual(package.questions.count, 12)
        XCTAssertTrue((package.reviewExceptions ?? []).isEmpty)
        XCTAssertEqual(
            package.questions[0].answer,
            package.questions[0].options[package.questions[0].answerIndex]
        )
    }

    func testDuplicateStableQuestionIDIsRejected() throws {
        let package = try BundleQuestionRepository(
            bundle: Bundle(for: Self.self),
            resourceName: "question-bank.synthetic"
        ).load()
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(package)) as? [String: Any]
        )
        var questions = try XCTUnwrap(object["questions"] as? [[String: Any]])
        questions[1]["id"] = questions[0]["id"]
        object["questions"] = questions
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try BundleQuestionRepository.decodeAndValidate(data)) { error in
            XCTAssertEqual(error as? QuestionRepositoryError, .duplicateIdentifier("fixture-choice-001"))
        }
    }

    func testInvalidAnswerIndexIsRejected() throws {
        let package = try BundleQuestionRepository(
            bundle: Bundle(for: Self.self),
            resourceName: "question-bank.synthetic"
        ).load()
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(package)
            ) as? [String: Any]
        )
        var questions = try XCTUnwrap(object["questions"] as? [[String: Any]])
        questions[0]["answerIndex"] = 9
        object["questions"] = questions
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try BundleQuestionRepository.decodeAndValidate(data)) { error in
            XCTAssertEqual(error as? QuestionRepositoryError, .invalidQuestion("fixture-choice-001"))
        }
    }

    func testReviewExceptionDecodesWithReasonAndReviewedAnswer() throws {
        var object = try syntheticPackageObject()
        object["reviewExceptions"] = [syntheticReviewException(id: "fixture-excluded-001")]
        let data = try JSONSerialization.data(withJSONObject: object)

        let package = try BundleQuestionRepository.decodeAndValidate(data)
        let item = try XCTUnwrap(package.reviewExceptions?.first)
        XCTAssertEqual(item.category, "official-deleted")
        XCTAssertEqual(item.officialPrintedAnswer, "歷史答案")
        XCTAssertEqual(item.reviewedAnswer, "官方最新版已刪除，無現行採計答案。")
        XCTAssertNotNil(item.publicSourceURL)
    }

    func testReviewExceptionCannotDuplicateAnActiveQuestionID() throws {
        var object = try syntheticPackageObject()
        object["reviewExceptions"] = [syntheticReviewException(id: "fixture-choice-001")]
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try BundleQuestionRepository.decodeAndValidate(data)) { error in
            XCTAssertEqual(
                error as? QuestionRepositoryError,
                .invalidReviewException("fixture-choice-001")
            )
        }
    }

    private func syntheticPackageObject() throws -> [String: Any] {
        let package = try BundleQuestionRepository(
            bundle: Bundle(for: Self.self),
            resourceName: "question-bank.synthetic"
        ).load()
        return try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(package)) as? [String: Any]
        )
    }

    private func syntheticReviewException(id: String) -> [String: Any] {
        [
            "id": id,
            "publicCode": "FIXTURE-EXCLUDED-001",
            "category": "official-deleted",
            "subjectTitle": "合成測試科目",
            "chapterTitle": "合成測試章節",
            "prompt": "這是一題合成的例外審查題目。",
            "officialPrintedAnswer": "歷史答案",
            "reviewedAnswer": "官方最新版已刪除，無現行採計答案。",
            "reason": "用於驗證例外審查資料，不是正式題目。",
            "publicSource": "合成測試來源",
            "publicSourceUrl": "https://example.invalid/review-exception",
            "publicSourceCheckedAt": "2026-08-11",
        ]
    }
}
