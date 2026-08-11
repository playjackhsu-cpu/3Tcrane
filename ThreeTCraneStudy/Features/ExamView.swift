import SwiftData
import SwiftUI

private enum ExamMode: String, CaseIterable, Identifiable {
    case formal
    case quick

    var id: String { rawValue }

    var title: String {
        switch self {
        case .formal: "正式模擬"
        case .quick: "快速練習"
        }
    }

    var subtitle: String {
        switch self {
        case .formal: "80 題・100 分鐘・依官方比例抽題"
        case .quick: "10 題・10 分鐘・全題庫隨機"
        }
    }

    var systemImage: String {
        switch self {
        case .formal: "doc.text.magnifyingglass"
        case .quick: "bolt.fill"
        }
    }

    var timeLimitSeconds: Int {
        switch self {
        case .formal: 100 * 60
        case .quick: 10 * 60
        }
    }
}

enum ExamQuestionSelector {
    static let mainSubjectID = "06100"
    static let commonSubjectIDs = ["90006", "90007", "90008", "90009"]

    static func canCreateFormal(from questions: [StudyQuestion]) -> Bool {
        questions.filter { $0.subjectId == mainSubjectID }.count >= 64
            && commonSubjectIDs.allSatisfy { subjectID in
                questions.filter { $0.subjectId == subjectID }.count >= 4
            }
    }

    static func formal(from questions: [StudyQuestion]) -> [StudyQuestion] {
        guard canCreateFormal(from: questions) else { return [] }
        let main = questions
            .filter { $0.subjectId == mainSubjectID }
            .shuffled()
            .prefix(64)
        let common = commonSubjectIDs.flatMap { subjectID in
            questions
                .filter { $0.subjectId == subjectID }
                .shuffled()
                .prefix(4)
        }
        return (Array(main) + common).shuffled()
    }

    static func quick(from questions: [StudyQuestion], count: Int = 10) -> [StudyQuestion] {
        Array(questions.shuffled().prefix(min(count, questions.count)))
    }
}

struct ExamSetupView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExamAttempt.startedAt, order: .reverse)
    private var attempts: [ExamAttempt]
    @State private var newAttempt: ExamAttempt?
    @State private var showNewAttempt = false
    @State private var errorMessage: String?
    @State private var examMode = ExamMode.formal

    private var unfinishedAttempt: ExamAttempt? {
        attempts.first { $0.submittedAt == nil }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                examHeader

                if let unfinishedAttempt {
                    BrandSectionTitle(title: "未完成測驗")
                    NavigationLink {
                        ExamSessionView(attempt: unfinishedAttempt)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.cranePrimaryBlue)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("繼續上次測驗").font(.headline)
                                if let snapshot = try? LearningPersistence.decodeExamSnapshot(from: unfinishedAttempt) {
                                    Text("已作答 \(snapshot.answeredCount)／\(snapshot.questions.count) 題")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .brandCard()
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("exam.resume")
                }

                BrandSectionTitle(title: "選擇測驗模式")
                VStack(spacing: 12) {
                    modeButton(.formal, enabled: formalExamIsAvailable)
                    modeButton(.quick, enabled: quickQuestionCount > 0)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("作答規則", systemImage: "checklist")
                        .font(.headline)
                        .foregroundStyle(Color.cranePrimaryBlue)
                    Text("交卷前不顯示正確答案與解析；可保留空白題交卷，時間到會自動交卷。離開 App 後可從本機繼續未完成測驗。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if examMode == .formal {
                        Text("共同科目 90006～90009 各 4 題，06100 專業題 64 題。每題 1.25 分，答錯不倒扣。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .brandCard()

                Button {
                    startExam()
                } label: {
                    Label(
                        unfinishedAttempt == nil ? "開始\(examMode.title)" : "放棄未完成測驗並重新開始",
                        systemImage: "timer"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedQuestions().isEmpty)
                .accessibilityIdentifier("exam.start")

                let submitted = attempts.filter { $0.submittedAt != nil }
                if !submitted.isEmpty {
                    BrandSectionTitle(title: "最近成績")
                    VStack(spacing: 0) {
                        ForEach(submitted.prefix(5)) { attempt in
                            if let snapshot = try? LearningPersistence.decodeExamSnapshot(from: attempt) {
                                NavigationLink {
                                    ExamResultView(
                                        snapshot: snapshot,
                                        score: attempt.score ?? snapshot.scorePercent,
                                        durationSeconds: attempt.durationSeconds
                                    )
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(attempt.submittedAt?.formatted(date: .abbreviated, time: .shortened) ?? "已交卷")
                                                .foregroundStyle(.primary)
                                            Text("\(snapshot.questions.count) 題・\(snapshot.correctCount) 題正確")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text("\(attempt.score ?? 0) 分")
                                            .font(.headline)
                                            .foregroundStyle(Color.cranePrimaryBlue)
                                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 13)
                                }
                                .buttonStyle(.plain)
                                if attempt.id != submitted.prefix(5).last?.id { Divider() }
                            }
                        }
                    }
                    .brandCard()
                }
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("模擬測驗")
        .navigationDestination(isPresented: $showNewAttempt) {
            if let newAttempt {
                ExamSessionView(attempt: newAttempt)
            }
        }
        .alert("無法建立測驗", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知錯誤")
        }
        .onAppear {
            if !formalExamIsAvailable {
                examMode = .quick
            }
        }
    }

    private var quickQuestionCount: Int {
        min(10, contentStore.questions.count)
    }

    private var formalExamIsAvailable: Bool {
        ExamQuestionSelector.canCreateFormal(from: contentStore.questions)
    }

    private var examHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("單一級學科模擬", systemImage: "graduationcap.fill")
                .font(.title2.bold())
            Text("正式模擬依官方現行題數、時間與共同科目比例在本機抽題。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.86))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            LinearGradient(
                colors: [.cranePrimaryBlue, .craneSupportBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private func modeButton(_ mode: ExamMode, enabled: Bool) -> some View {
        Button {
            examMode = mode
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(mode == examMode ? Color.cranePrimaryBlue : Color.cranePrimaryBlue.opacity(0.10))
                    Image(systemName: mode.systemImage)
                        .foregroundStyle(mode == examMode ? .white : Color.cranePrimaryBlue)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.title).font(.headline).foregroundStyle(.primary)
                    Text(enabled ? mode.subtitle : "內部完整題庫到位後啟用")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: mode == examMode ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(mode == examMode ? Color.cranePrimaryBlue : .secondary)
            }
            .brandCard(padding: 14)
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(mode == examMode ? Color.cranePrimaryBlue : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.6)
    }

    private func selectedQuestions() -> [StudyQuestion] {
        switch examMode {
        case .formal:
            return ExamQuestionSelector.formal(from: contentStore.questions)
        case .quick:
            return ExamQuestionSelector.quick(from: contentStore.questions, count: quickQuestionCount)
        }
    }

    private func startExam() {
        do {
            let questions = selectedQuestions().shuffled()
            guard !questions.isEmpty else {
                errorMessage = "目前題庫不足以建立這個測驗模式。"
                return
            }
            newAttempt = try LearningPersistence.startExam(
                questions: questions,
                contentVersion: contentStore.contentVersion,
                timeLimitSeconds: examMode.timeLimitSeconds,
                in: modelContext
            )
            showNewAttempt = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ExamSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var attempt: ExamAttempt
    @State private var snapshot: ExamSessionSnapshot?
    @State private var resultSnapshot: ExamSessionSnapshot?
    @State private var errorMessage: String?
    @State private var showSubmitConfirmation = false
    @State private var isSubmitting = false

    var body: some View {
        Group {
            if let result = resultSnapshot ?? submittedSnapshot {
                ExamResultView(
                    snapshot: result,
                    score: attempt.score ?? result.scorePercent,
                    durationSeconds: attempt.durationSeconds
                )
            } else if let snapshot,
                      snapshot.questions.indices.contains(snapshot.currentIndex) {
                examBody(snapshot)
            } else {
                SwiftUI.ProgressView("載入測驗中…")
            }
        }
        .navigationTitle(attempt.submittedAt == nil ? "模擬測驗" : "測驗結果")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadSnapshot)
        .task(id: attempt.id) {
            await monitorTimeLimit()
        }
        .alert("確認交卷", isPresented: $showSubmitConfirmation) {
            Button("取消", role: .cancel) {}
            Button("交卷") { submit() }
        } message: {
            Text("交卷後不能修改本次答案。")
        }
        .alert("測驗資料無法儲存", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知錯誤")
        }
    }

    private var submittedSnapshot: ExamSessionSnapshot? {
        guard attempt.submittedAt != nil else { return nil }
        return try? LearningPersistence.decodeExamSnapshot(from: attempt)
    }

    private func examBody(_ value: ExamSessionSnapshot) -> some View {
        let question = value.questions[value.currentIndex]
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("第 \(value.currentIndex + 1)／\(value.questions.count) 題")
                    Spacer()
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(remainingTime(at: context.date, limit: value.timeLimitSeconds))
                            .monospacedDigit()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                SwiftUI.ProgressView(value: Double(value.answeredCount), total: Double(value.questions.count))
                    .accessibilityLabel("已作答 \(value.answeredCount) 題，共 \(value.questions.count) 題")

                Text(question.prompt)
                    .font(.title3.bold())
                    .accessibilityIdentifier("exam.prompt")

                if let imageResource = question.imageResource {
                    BundledQuestionImage(
                        resourceName: imageResource,
                        accessibilityLabel: question.imageAccessibilityLabel ?? "\(question.publicCode) 題目圖示"
                    )
                }

                ForEach(question.options.indices, id: \.self) { optionIndex in
                    Button {
                        selectAnswer(optionIndex, questionIndex: value.currentIndex)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle().fill(Color.cranePrimaryBlue.opacity(0.10))
                                Text(String(UnicodeScalar(65 + optionIndex)!))
                                    .font(.headline)
                                    .foregroundStyle(Color.cranePrimaryBlue)
                            }
                            .frame(width: 34, height: 34)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(question.options[optionIndex])
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                if let resources = question.optionImageResources,
                                   resources.indices.contains(optionIndex),
                                   let resourceName = resources[optionIndex] {
                                    BundledQuestionImage(
                                        resourceName: resourceName,
                                        accessibilityLabel: "選項 \(String(UnicodeScalar(65 + optionIndex)!)) 圖示",
                                        maxHeight: 130
                                    )
                                }
                            }
                            Spacer()
                            Image(systemName: question.selectedIndex == optionIndex ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(Color.cranePrimaryBlue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("exam.option.\(optionIndex)")
                }

                HStack {
                    Button("上一題") { move(to: value.currentIndex - 1) }
                        .buttonStyle(.bordered)
                        .disabled(value.currentIndex == 0)
                    Spacer()
                    if value.currentIndex < value.questions.count - 1 {
                        Button("下一題") { move(to: value.currentIndex + 1) }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button("交卷") { showSubmitConfirmation = true }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("exam.submit")
                    }
                }

                if value.answeredCount != value.questions.count {
                    Text("尚有 \(value.questions.count - value.answeredCount) 題未作答")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func loadSnapshot() {
        do {
            snapshot = try LearningPersistence.decodeExamSnapshot(from: attempt)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func selectAnswer(_ selectedIndex: Int, questionIndex: Int) {
        guard var snapshot else { return }
        snapshot.questions[questionIndex].selectedIndex = selectedIndex
        self.snapshot = snapshot
        do {
            try LearningPersistence.updateExam(
                attempt,
                selectedIndex: selectedIndex,
                questionIndex: questionIndex,
                currentIndex: snapshot.currentIndex,
                in: modelContext
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func move(to index: Int) {
        guard var snapshot,
              snapshot.questions.indices.contains(index)
        else { return }
        snapshot.currentIndex = index
        self.snapshot = snapshot
        if let selectedIndex = snapshot.questions[index].selectedIndex
            ?? snapshot.questions[snapshot.currentIndex].selectedIndex {
            try? LearningPersistence.updateExam(
                attempt,
                selectedIndex: selectedIndex,
                questionIndex: index,
                currentIndex: index,
                in: modelContext
            )
        } else {
            attempt.questionSnapshotData = (try? LearningPersistence.encodeExamSnapshot(snapshot))
                ?? attempt.questionSnapshotData
            try? modelContext.save()
        }
    }

    private func submit() {
        guard !isSubmitting, attempt.submittedAt == nil else { return }
        isSubmitting = true
        do {
            resultSnapshot = try LearningPersistence.submitExam(attempt, in: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
        }
    }

    @MainActor
    private func monitorTimeLimit() async {
        while !Task.isCancelled, attempt.submittedAt == nil {
            guard let snapshot else {
                try? await Task.sleep(for: .milliseconds(250))
                continue
            }
            if Date().timeIntervalSince(attempt.startedAt) >= Double(snapshot.timeLimitSeconds) {
                submit()
                return
            }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func remainingTime(at date: Date, limit: Int) -> String {
        let remaining = max(0, limit - Int(date.timeIntervalSince(attempt.startedAt)))
        return String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }
}

struct ExamResultView: View {
    let snapshot: ExamSessionSnapshot
    let score: Int
    let durationSeconds: Int

    var body: some View {
        List {
            Section("成績") {
                VStack(spacing: 8) {
                    Text("\(score) 分")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                    Text("答對 \(snapshot.correctCount)／\(snapshot.questions.count) 題")
                        .foregroundStyle(.secondary)
                    Text("作答時間 \(durationText)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .accessibilityIdentifier("exam.result")
            }

            Section("逐題結果") {
                ForEach(Array(snapshot.questions.enumerated()), id: \.element.id) { index, question in
                    DisclosureGroup {
                        LabeledContent("你的答案", value: selectedAnswer(question))
                        LabeledContent("正確答案", value: question.answer)
                        if let imageResource = question.imageResource {
                            BundledQuestionImage(
                                resourceName: imageResource,
                                accessibilityLabel: question.imageAccessibilityLabel ?? "\(question.publicCode) 題目圖示"
                            )
                        }
                        if let resources = question.optionImageResources {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(question.options.indices, id: \.self) { optionIndex in
                                    if resources.indices.contains(optionIndex), let resourceName = resources[optionIndex] {
                                        VStack {
                                            Text(String(UnicodeScalar(65 + optionIndex)!)).font(.caption.bold())
                                            BundledQuestionImage(
                                                resourceName: resourceName,
                                                accessibilityLabel: "選項 \(String(UnicodeScalar(65 + optionIndex)!)) 圖示",
                                                maxHeight: 90
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        Text(question.explanation)
                            .font(.subheadline)
                    } label: {
                        Label(
                            "第 \(index + 1) 題",
                            systemImage: question.selectedIndex == question.answerIndex
                                ? "checkmark.circle.fill"
                                : "xmark.circle.fill"
                        )
                        .foregroundStyle(
                            question.selectedIndex == question.answerIndex ? .green : .red
                        )
                    }
                }
            }
        }
        .navigationTitle("測驗結果")
    }

    private var durationText: String {
        String(format: "%d:%02d", durationSeconds / 60, durationSeconds % 60)
    }

    private func selectedAnswer(_ question: ExamQuestionSnapshot) -> String {
        guard let index = question.selectedIndex,
              question.options.indices.contains(index)
        else { return "未作答" }
        return question.options[index]
    }
}
