import XCTest

final class NavigationSmokeTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainNavigationCanReachPracticeOnPhoneOrPad() throws {
        let app = launchInTestHub()

        let practiceEntry = app.buttons["testHub.practice"]
        XCTAssertTrue(practiceEntry.waitForExistence(timeout: 5))
        practiceEntry.tap()

        XCTAssertTrue(app.staticTexts["practice.prompt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["practice.option.0"].exists)
        app.buttons["practice.option.1"].tap()
        let correctFeedback = app.staticTexts["答對了"]
        let incorrectFeedback = app.staticTexts["答錯了"]
        XCTAssertTrue(
            correctFeedback.waitForExistence(timeout: 2)
                || incorrectFeedback.waitForExistence(timeout: 2),
            "作答後應顯示答對或答錯的評分結果。"
        )
        XCTAssertTrue(app.buttons["practice.favorite"].exists)
    }

    func testCanCreateLocalQuestionNote() throws {
        let app = launchInTestHub()
        app.buttons["testHub.practice"].tap()
        XCTAssertTrue(app.staticTexts["practice.prompt"].waitForExistence(timeout: 5))

        app.buttons["practice.note"].tap()
        let editor = app.textViews["note.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("UI 測試筆記")
        app.buttons["note.save"].tap()
        XCTAssertTrue(app.staticTexts["UI 測試筆記"].waitForExistence(timeout: 5))
    }

    func testCanStartOfflineExam() throws {
        let app = launchInTestHub()
        app.buttons["testHub.exam"].tap()
        XCTAssertTrue(app.buttons["exam.start"].waitForExistence(timeout: 5))
        app.buttons["exam.start"].tap()
        XCTAssertTrue(app.staticTexts["exam.prompt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["exam.option.0"].exists)
    }

    func testCourseUsesReadingReviewWithoutRequiringAnAnswer() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let phoneCourse = app.tabBars.buttons["課程"]
        if phoneCourse.waitForExistence(timeout: 5) {
            phoneCourse.tap()
        } else {
            let showSidebar = app.buttons["顯示側邊欄"]
            if showSidebar.exists { showSidebar.tap() }
            let sidebarCourse = app.descendants(matching: .any)["sidebar.learn"]
            XCTAssertTrue(sidebarCourse.waitForExistence(timeout: 5))
            sidebarCourse.tap()
        }

        let continueButton = app.buttons["course.continue"]
        let startButton = app.buttons["course.start"]
        XCTAssertTrue(
            continueButton.waitForExistence(timeout: 10) || startButton.waitForExistence(timeout: 10),
            "課程頁載入後應顯示繼續學習或開始第一次複習。"
        )
        (continueButton.exists ? continueButton : startButton).tap()

        XCTAssertTrue(app.staticTexts["course.prompt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["答案"].exists)
        XCTAssertFalse(app.buttons["practice.option.0"].exists)
    }

    func testIPadHomeUsesCompactBalancedSidebar() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        if app.tabBars.buttons["首頁"].waitForExistence(timeout: 2) {
            throw XCTSkip("此比例檢查只適用於 iPad 分割導覽。")
        }

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        let sidebarHome = app.descendants(matching: .any)["sidebar.home"]
        XCTAssertTrue(sidebarHome.waitForExistence(timeout: 5))
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(
            sidebarHome.frame.maxX,
            window.frame.width * 0.30,
            "iPad 橫向側欄不應占用超過畫面寬度的 30%。"
        )

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "iPad Balanced Home Layout"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testInternalReviewExceptionsShowAllGovernedCategories() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        guard app.staticTexts["內容版本 0.2.1"].waitForExistence(timeout: 3) else {
            throw XCTSkip("公開合成題庫不包含 Internal TestFlight 例外資料。")
        }

        let toggle = app.buttons["home.reviewExceptions.toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        for _ in 0..<4 where !toggle.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(toggle.isHittable)
        XCTAssertEqual(toggle.value as? String, "已收合")
        XCTAssertFalse(app.staticTexts["正確答案／現行判定"].exists)

        let collapsedScreenshot = XCTAttachment(screenshot: app.screenshot())
        collapsedScreenshot.name = "Internal Review Exceptions Collapsed"
        collapsedScreenshot.lifetime = .keepAlways
        add(collapsedScreenshot)

        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "已展開")
        XCTAssertTrue(app.staticTexts["官方最新版刪除（8 題）"].exists)
        XCTAssertTrue(app.staticTexts["答案或題意衝突（5 題）"].exists)
        XCTAssertTrue(app.staticTexts["法規生效過渡（4 題）"].exists)

        for _ in 0..<4 {
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["正確答案／現行判定"].exists)
        XCTAssertTrue(app.staticTexts["列管原因"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Internal Review Exceptions Expanded"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func launchInTestHub() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let phonePractice = app.tabBars.buttons["測驗"]
        if phonePractice.waitForExistence(timeout: 5) {
            phonePractice.tap()
        } else {
            let showSidebar = app.buttons["顯示側邊欄"]
            if showSidebar.exists {
                showSidebar.tap()
            }

            let sidebarPractice = app.descendants(matching: .any)["sidebar.practice"]
            XCTAssertTrue(sidebarPractice.waitForExistence(timeout: 5))
            sidebarPractice.tap()
        }

        XCTAssertTrue(app.buttons["testHub.practice"].waitForExistence(timeout: 5))
        return app
    }
}
