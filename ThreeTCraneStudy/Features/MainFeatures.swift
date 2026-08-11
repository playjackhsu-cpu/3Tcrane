import SwiftData
import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @Query(sort: \QuestionProgress.lastAnsweredAt, order: .reverse)
    private var progress: [QuestionProgress]
    @Query private var favorites: [Favorite]
    @Query private var appStates: [AppState]
    let onSelectDestination: (AppDestination) -> Void

    private var totalAttempts: Int { progress.reduce(0) { $0 + $1.attemptCount } }
    private var totalCorrect: Int { progress.reduce(0) { $0 + $1.correctCount } }
    private var wrongCount: Int {
        progress.filter { item in
            let state = MasteryState(rawValue: item.masteryState) ?? .new
            return state == .needsReview || (state == .learning && item.attemptCount > item.correctCount)
        }.count
    }
    private var accuracy: Int {
        guard totalAttempts > 0 else { return 0 }
        return Int((Double(totalCorrect) / Double(totalAttempts) * 100).rounded())
    }
    private var completion: Double {
        guard !contentStore.questions.isEmpty else { return 0 }
        return Double(progress.count) / Double(contentStore.questions.count)
    }
    private var masteredCount: Int {
        progress.filter { $0.masteryState == MasteryState.mastered.rawValue }.count
    }
    private var lastQuestion: StudyQuestion? {
        guard let id = appStates.first(where: { $0.key == "primary" })?.lastQuestionID else { return nil }
        return contentStore.question(id: id)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CraneHeroHeader()

                VStack(alignment: .leading, spacing: 22) {
                    BrandSectionTitle(title: "學習功能")

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 12) {
                        Button { onSelectDestination(.learn) } label: {
                            BrandShortcutTile(title: "學習課程", assetName: "learning_course")
                        }
                        .buttonStyle(.plain)

                        Button { onSelectDestination(.practice) } label: {
                            BrandShortcutTile(title: "題庫測驗", assetName: "question_bank")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home.startPractice")

                        NavigationLink { StudyLibraryView(initialSection: .wrong) } label: {
                            BrandShortcutTile(title: "錯題複習", assetName: "wrong_answer_review")
                        }
                        .buttonStyle(.plain)

                        NavigationLink { ExamSetupView() } label: {
                            BrandShortcutTile(title: "模擬測驗", assetName: "mock_exam")
                        }
                        .buttonStyle(.plain)

                        NavigationLink { CourseReviewView(title: "法規與安全複習") } label: {
                            BrandShortcutTile(title: "法規條文", assetName: "regulations")
                        }
                        .buttonStyle(.plain)

                        NavigationLink { StudyLibraryView(initialSection: .notes) } label: {
                            BrandShortcutTile(title: "重點筆記", assetName: "notes")
                        }
                        .buttonStyle(.plain)

                        Button { onSelectDestination(.progress) } label: {
                            BrandShortcutTile(title: "學習紀錄", assetName: "learning_record")
                        }
                        .buttonStyle(.plain)

                        Button { onSelectDestination(.settings) } label: {
                            BrandShortcutTile(title: "更多功能", assetName: "more")
                        }
                        .buttonStyle(.plain)
                    }
                    .brandCard(padding: 10)

                    if let lastQuestion {
                        VStack(alignment: .leading, spacing: 12) {
                            BrandSectionTitle(title: "繼續學習")
                            NavigationLink {
                                CourseReviewView(initialQuestionID: lastQuestion.id, title: "繼續上次")
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(Color.cranePrimaryBlue)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(lastQuestion.publicCode)
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.cranePrimaryBlue)
                                        Text(lastQuestion.prompt)
                                            .font(.headline)
                                            .foregroundStyle(Color.craneNeutralDark)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("home.continue")
                        }
                        .brandCard()
                    }

                    BrandSectionTitle(title: "學習進度")
                    HStack(spacing: 20) {
                        BrandProgressRing(
                            value: totalAttempts == 0 ? 0 : Double(accuracy) / 100,
                            centerText: "\(accuracy)%",
                            subtitle: "正確率"
                        )
                        .frame(width: 112, height: 112)
                        VStack(spacing: 14) {
                            BrandProgressRow(title: "題庫完成度", value: completion, valueText: "\(progress.count) / \(contentStore.questions.count)")
                            BrandProgressRow(
                                title: "熟練題目",
                                value: contentStore.questions.isEmpty ? 0 : Double(masteredCount) / Double(contentStore.questions.count),
                                valueText: "\(masteredCount) 題",
                                color: .craneSuccessGreen
                            )
                            BrandProgressRow(
                                title: "待複習錯題",
                                value: contentStore.questions.isEmpty ? 0 : Double(wrongCount) / Double(contentStore.questions.count),
                                valueText: "\(wrongCount) 題",
                                color: .craneAccentOrange
                            )
                        }
                    }
                    .brandCard()

                    VStack(alignment: .leading, spacing: 12) {
                        BrandSectionTitle(title: "目前內容")
                        HStack {
                            Label("\(contentStore.questions.count) 題", systemImage: "checklist")
                            Spacer()
                            Text("內容版本 \(contentStore.contentVersion)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("題庫隨 App 更新；學習紀錄獨立保存在裝置內，安裝新版時不會由題庫覆蓋。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if contentStore.package?.isSynthetic == true {
                            Label("目前僅使用合成開發資料", systemImage: "hammer.fill")
                                .font(.footnote.bold())
                                .foregroundStyle(Color.craneAccentOrange)
                        } else if contentStore.questions.contains(where: { $0.rightsStatus == "needs-review" }) {
                            Label("Internal TestFlight 審查內容，尚未核准公開發行", systemImage: "person.badge.shield.checkmark")
                                .font(.footnote.bold())
                                .foregroundStyle(Color.craneAccentOrange)
                        }
                    }
                    .brandCard()

                    if !contentStore.reviewExceptions.isEmpty {
                        ReviewExceptionsCard(items: contentStore.reviewExceptions)
                    }
                }
                .padding(16)
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.craneBackground)
        .navigationTitle("首頁")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(
            UIDevice.current.userInterfaceIdiom == .pad ? .visible : .hidden,
            for: .navigationBar
        )
    }
}

private enum ReviewExceptionCategory: String, CaseIterable {
    case officialDeleted = "official-deleted"
    case hardAnswerConflict = "hard-answer-conflict"
    case regulatoryTransition = "regulatory-transition-hold"

    var title: String {
        switch self {
        case .officialDeleted: "官方最新版刪除"
        case .hardAnswerConflict: "答案或題意衝突"
        case .regulatoryTransition: "法規生效過渡"
        }
    }

    var systemImage: String {
        switch self {
        case .officialDeleted: "trash.slash.fill"
        case .hardAnswerConflict: "exclamationmark.triangle.fill"
        case .regulatoryTransition: "clock.badge.exclamationmark.fill"
        }
    }

    var color: Color {
        switch self {
        case .officialDeleted: .craneNeutralDark
        case .hardAnswerConflict: .red
        case .regulatoryTransition: .craneAccentOrange
        }
    }
}

private struct ReviewExceptionsCard: View {
    let items: [ReviewException]
    @State private var isExpanded = false

    private var categorySummary: String {
        ReviewExceptionCategory.allCases.compactMap { category in
            let count = items.count { $0.category == category.rawValue }
            guard count > 0 else { return nil }
            return "\(category.title) \(count) 題"
        }
        .joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("官方題庫例外審查")
                                .font(.title3.bold())
                                .foregroundStyle(Color.craneNeutralDark)
                            Text("\(items.count) 題")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.red, in: Capsule())
                        }

                        Text(categorySummary)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(isExpanded ? "點一下收合逐題內容" : "點一下查看原因、正確答案與官方來源")
                            .font(.caption)
                            .foregroundStyle(Color.cranePrimaryBlue)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.down")
                        .font(.headline.bold())
                        .foregroundStyle(Color.cranePrimaryBlue)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("官方題庫例外審查，共 \(items.count) 題")
            .accessibilityValue(isExpanded ? "已展開" : "已收合")
            .accessibilityHint(isExpanded ? "點一下收合逐題內容" : "點一下展開逐題內容")
            .accessibilityIdentifier("home.reviewExceptions.toggle")

            if isExpanded {
                Divider()

                VStack(alignment: .leading, spacing: 18) {
                    Text("下列題目不納入目前 983 題練習與模擬測驗。刪除題保留歷史印刷答案；衝突與過渡題列出審查後的正確答案或現行判定。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(ReviewExceptionCategory.allCases, id: \.rawValue) { category in
                        let categoryItems = items.filter { $0.category == category.rawValue }
                        if !categoryItems.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("\(category.title)（\(categoryItems.count) 題）", systemImage: category.systemImage)
                                    .font(.headline)
                                    .foregroundStyle(category.color)

                                ForEach(categoryItems) { item in
                                    ReviewExceptionRow(item: item, color: category.color)
                                    if item.id != categoryItems.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
                .accessibilityIdentifier("home.reviewExceptions.details")
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .brandCard()
    }
}

private struct ReviewExceptionRow: View {
    let item: ReviewException
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("\(item.publicCode) · \(item.subjectTitle)／\(item.chapterTitle)")
                .font(.caption.bold())
                .foregroundStyle(color)

            Text(item.prompt)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.craneNeutralDark)

            ReviewExceptionField(
                title: "官方原答案",
                value: item.officialPrintedAnswer,
                color: .secondary
            )
            ReviewExceptionField(
                title: "正確答案／現行判定",
                value: item.reviewedAnswer,
                color: color
            )
            ReviewExceptionField(
                title: "列管原因",
                value: item.reason,
                color: .secondary
            )

            if let sourceURL = item.publicSourceURL {
                Link(destination: sourceURL) {
                    Label(
                        item.publicSourceCheckedAt.isEmpty
                            ? "查看查核來源"
                            : "查看查核來源（\(item.publicSourceCheckedAt)）",
                        systemImage: "safari"
                    )
                    .font(.caption.weight(.semibold))
                }
                .accessibilityLabel("\(item.publicCode) 查看查核來源")
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.reviewException.\(item.id)")
    }
}

private struct ReviewExceptionField: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote)
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct LearnView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @Query private var appStates: [AppState]

    private var lastQuestion: StudyQuestion? {
        guard let id = appStates.first(where: { $0.key == "primary" })?.lastQuestionID else { return nil }
        return contentStore.question(id: id)
    }

    var body: some View {
        Group {
            if let package = contentStore.package {
                List {
                    Section("接續學習") {
                        if let lastQuestion {
                            NavigationLink {
                                CourseReviewView(initialQuestionID: lastQuestion.id, title: "繼續上次")
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Label("繼續上次題目", systemImage: "clock.arrow.circlepath")
                                        .font(.headline)
                                    Text("\(lastQuestion.publicCode) · \(lastQuestion.prompt)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .accessibilityIdentifier("course.continue")
                        } else {
                            NavigationLink {
                                CourseReviewView(title: "全部題目複習")
                            } label: {
                                Label("開始第一次複習", systemImage: "play.circle.fill")
                            }
                            .accessibilityIdentifier("course.start")
                        }
                    }

                    Section {
                        Text("課程採閱讀式複習：依官方題序直接閱讀答案、解析與來源，不會增加作答次數或影響正確率。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(package.subjects.sorted { $0.order < $1.order }) { subject in
                        Section(subject.title) {
                            ForEach(package.chapters.filter { $0.subjectId == subject.id }.sorted { $0.order < $1.order }) { chapter in
                                NavigationLink {
                                    ChapterView(chapter: chapter)
                                } label: {
                                    HStack {
                                        Label(chapter.title, systemImage: "book.pages")
                                        Spacer()
                                        Text("\(contentStore.questions(in: chapter.id).count) 題")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView("題庫無法載入", systemImage: "doc.badge.exclamationmark", description: Text(contentStore.loadingError ?? "未知錯誤"))
            }
        }
        .navigationTitle("學習課程")
    }
}

private struct ChapterView: View {
    @EnvironmentObject private var contentStore: ContentStore
    let chapter: QuestionChapter

    var body: some View {
        let questions = contentStore.questions(in: chapter.id)
        return List {
            Section {
                NavigationLink {
                    CourseReviewView(questionIDs: questions.map(\.id), title: chapter.title)
                } label: {
                    Label("開始本章複習（\(questions.count) 題）", systemImage: "play.fill")
                }
            }
            Section("題目") {
                ForEach(questions) { question in
                    NavigationLink(question.prompt) {
                        CourseReviewView(
                            questionIDs: questions.map(\.id),
                            initialQuestionID: question.id,
                            title: chapter.title
                        )
                    }
                }
            }
        }
        .navigationTitle(chapter.title)
    }
}

struct ProgressView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @Query(sort: \QuestionProgress.lastAnsweredAt, order: .reverse)
    private var progress: [QuestionProgress]
    @Query(sort: \ExamAttempt.startedAt, order: .reverse)
    private var examAttempts: [ExamAttempt]

    private var totalAttempts: Int { progress.reduce(0) { $0 + $1.attemptCount } }
    private var totalCorrect: Int { progress.reduce(0) { $0 + $1.correctCount } }
    private var accuracy: Int {
        guard totalAttempts > 0 else { return 0 }
        return Int((Double(totalCorrect) / Double(totalAttempts) * 100).rounded())
    }

    private var studyDays: Int {
        let calendar = Calendar.current
        let answerDays = progress.compactMap(\.lastAnsweredAt).map(calendar.startOfDay(for:))
        let examDays = examAttempts.map { calendar.startOfDay(for: $0.startedAt) }
        return Set(answerDays + examDays).count
    }

    private var subjectPerformance: [SubjectPerformance] {
        guard let package = contentStore.package else { return [] }
        let progressByID = Dictionary(uniqueKeysWithValues: progress.map { ($0.questionID, $0) })
        return package.subjects.sorted { $0.order < $1.order }.map { subject in
            let questionIDs = Set(package.questions.filter { $0.subjectId == subject.id }.map(\.id))
            let records = questionIDs.compactMap { progressByID[$0] }
            let attempts = records.reduce(0) { $0 + $1.attemptCount }
            let correct = records.reduce(0) { $0 + $1.correctCount }
            let rate = attempts == 0 ? 0 : Double(correct) / Double(attempts)
            return SubjectPerformance(id: subject.id, title: subject.title, rate: rate, answered: records.count, total: questionIDs.count)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("學習紀錄")
                    .font(.largeTitle.bold())

                HStack(spacing: 24) {
                    BrandProgressRing(
                        value: Double(accuracy) / 100,
                        centerText: "\(accuracy)%",
                        subtitle: "總正確率"
                    )
                    .frame(width: 132, height: 132)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ProgressMetric(title: "已作答", value: "\(progress.count)", unit: "題")
                        ProgressMetric(title: "累計作答", value: "\(totalAttempts)", unit: "次")
                        ProgressMetric(title: "答對", value: "\(totalCorrect)", unit: "題次")
                        ProgressMetric(title: "學習天數", value: "\(studyDays)", unit: "天")
                    }
                }
                .brandCard()

                NavigationLink {
                    StudyLibraryView()
                } label: {
                    HStack(spacing: 14) {
                        Image("wrong_answer_review")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 54, height: 54)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("錯題、收藏與筆記")
                                .font(.headline)
                                .foregroundStyle(Color.craneNeutralDark)
                            Text("集中查看個人複習清單")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .brandCard()

                BrandSectionTitle(title: "能力分析")
                VStack(spacing: 16) {
                    ForEach(subjectPerformance) { item in
                        BrandProgressRow(
                            title: item.title,
                            value: item.rate,
                            valueText: item.answered == 0 ? "尚未作答" : "\(Int((item.rate * 100).rounded()))% · \(item.answered)/\(item.total)"
                        )
                    }
                }
                .brandCard()

                BrandSectionTitle(title: "最近模擬測驗")
            let completedExams = examAttempts.filter { $0.submittedAt != nil }
                if completedExams.isEmpty {
                    Label("尚無模擬測驗紀錄", systemImage: "timer")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .brandCard()
                } else {
                    VStack(spacing: 0) {
                    ForEach(completedExams.prefix(10)) { attempt in
                        if let snapshot = try? LearningPersistence.decodeExamSnapshot(from: attempt) {
                            NavigationLink {
                                ExamResultView(
                                    snapshot: snapshot,
                                    score: attempt.score ?? snapshot.scorePercent,
                                    durationSeconds: attempt.durationSeconds
                                )
                            } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(attempt.submittedAt?.formatted(date: .abbreviated, time: .shortened) ?? "已交卷")
                                                .font(.subheadline.weight(.semibold))
                                            Text("答對 \(snapshot.correctCount) / \(snapshot.questions.count) 題")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text("\(attempt.score ?? 0) 分")
                                            .font(.title3.bold().monospacedDigit())
                                            .foregroundStyle(Color.cranePrimaryBlue)
                                    }
                                    .padding(.vertical, 12)
                            }
                                .buttonStyle(.plain)
                                if attempt.id != completedExams.prefix(10).last?.id { Divider() }
                        }
                    }
                    }
                    .brandCard()
                }

                BrandSectionTitle(title: "最近題目紀錄")
                if progress.isEmpty {
                    Label("尚無學習紀錄", systemImage: "chart.bar")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .brandCard()
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(progress.prefix(12).enumerated()), id: \.element.id) { index, item in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(questionTitle(item.questionID)).font(.subheadline.weight(.semibold)).lineLimit(2)
                                Text("作答 \(item.attemptCount) 次 · 答對 \(item.correctCount) 次")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !contentStore.questions.contains(where: { $0.id == item.questionID }) {
                                    Label("此題已下架，紀錄仍保留", systemImage: "archivebox")
                                        .font(.caption)
                                        .foregroundStyle(Color.craneAccentOrange)
                                }
                            }
                            .padding(.vertical, 11)
                            if index < min(progress.count, 12) - 1 { Divider() }
                        }
                    }
                    .brandCard()
                }
            }
            .padding()
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
        }
        .background(Color.craneBackground)
        .navigationTitle("紀錄")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func questionTitle(_ id: String) -> String {
        contentStore.questions.first(where: { $0.id == id })?.prompt ?? "已下架題目（\(id)）"
    }
}

private struct SubjectPerformance: Identifiable {
    let id: String
    let title: String
    let rate: Double
    let answered: Int
    let total: Int
}

private struct ProgressMetric: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(Color.cranePrimaryBlue)
            Text("\(title) · \(unit)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var contentStore: ContentStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    LinearGradient(
                        colors: [.cranePrimaryBlue, .craneSupportBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.white)
                        Text("我的學習")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("所有資料只保存在這台裝置")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.86))
                    }
                    .padding(.vertical, 26)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 18) {
                    NavigationLink {
                        StudyLibraryView()
                    } label: {
                        SettingsRow(title: "錯題、收藏與筆記", subtitle: "管理個人複習內容", assetName: "favorites")
                    }
                    .buttonStyle(.plain)
                    .brandCard(padding: 12)

                    VStack(spacing: 0) {
                        SettingsInfoRow(title: "App 版本", value: appVersion)
                        Divider()
                        SettingsInfoRow(title: "Build", value: buildNumber)
                        Divider()
                        SettingsInfoRow(title: "內容版本", value: contentStore.contentVersion)
                        Divider()
                        SettingsInfoRow(title: "題庫更新", value: "隨 App 更新")
                    }
                    .brandCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Label("隱私與資料", systemImage: "hand.raised.fill")
                            .font(.headline)
                            .foregroundStyle(Color.cranePrimaryBlue)
                        Label("無帳號、無追蹤、無廣告", systemImage: "checkmark.circle.fill")
                        Label("學習紀錄只保存在本機", systemImage: "iphone")
                        Label("不提供遠端題庫或雲端同步", systemImage: "icloud.slash")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .brandCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("重要說明", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(Color.craneAccentOrange)
                        Text("學科參考資料僅供學習使用；正式答案與適用法規仍應以主管機關最新公告為準。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .brandCard()
                }
                .padding()
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.craneBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

private struct SettingsRow: View {
    let title: String
    let subtitle: String
    let assetName: String

    var body: some View {
        HStack(spacing: 14) {
            Image(assetName).resizable().scaledToFit().frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(Color.craneNeutralDark)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
    }
}
