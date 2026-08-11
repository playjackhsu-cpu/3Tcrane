import XCTest
import UIKit
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

    func testBrandSemanticColorsRemainReadableInLightAndDarkMode() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let foreground = UIColor.craneNeutralDark.resolvedColor(with: traits)
            let secondary = UIColor.craneNeutralGray.resolvedColor(with: traits)
            let card = UIColor.secondarySystemGroupedBackground.resolvedColor(with: traits)
            let link = UIColor.cranePrimaryBlue.resolvedColor(with: traits)

            XCTAssertGreaterThanOrEqual(
                contrastRatio(foreground, card),
                4.5,
                "主要文字在 \(style == .dark ? "Dark" : "Light") 模式必須保持可讀。"
            )
            XCTAssertGreaterThanOrEqual(
                contrastRatio(secondary, card),
                4.5,
                "次要文字在 \(style == .dark ? "Dark" : "Light") 模式必須保持可讀。"
            )
            XCTAssertGreaterThanOrEqual(
                contrastRatio(link, card),
                4.5,
                "互動藍色在 \(style == .dark ? "Dark" : "Light") 模式必須保持可讀。"
            )
        }
    }

    func testBrandBackgroundActuallyChangesForDarkMode() {
        let light = UIColor.craneBackground.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .light)
        )
        let dark = UIColor.craneBackground.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .dark)
        )

        XCTAssertGreaterThan(relativeLuminance(light), relativeLuminance(dark))
        XCTAssertGreaterThanOrEqual(contrastRatio(UIColor.craneNeutralDark.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .dark)
        ), dark), 4.5)
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

    private func contrastRatio(_ first: UIColor, _ second: UIColor) -> CGFloat {
        let lighter = max(relativeLuminance(first), relativeLuminance(second))
        let darker = min(relativeLuminance(first), relativeLuminance(second))
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))

        func linearize(_ component: CGFloat) -> CGFloat {
            component <= 0.04045
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linearize(red)
            + 0.7152 * linearize(green)
            + 0.0722 * linearize(blue)
    }
}
