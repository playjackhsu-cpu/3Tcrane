import SwiftData
import SwiftUI

struct CourseReviewView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [Favorite]
    @Query private var notes: [QuestionNote]
    @Query private var appStates: [AppState]

    @State private var currentIndex = 0
    @State private var jumpText = ""
    @State private var isJumping = false
    @State private var saveError: String?
    @State private var isEditingNote = false
    @State private var noteDraft = ""

    let questionIDs: [String]?
    let initialQuestionID: String?
    let title: String

    init(
        questionIDs: [String]? = nil,
        initialQuestionID: String? = nil,
        title: String = "課程複習"
    ) {
        self.questionIDs = questionIDs
        self.initialQuestionID = initialQuestionID
        self.title = title
    }

    private var questions: [StudyQuestion] {
        guard let questionIDs else { return contentStore.questions }
        return questionIDs.compactMap(contentStore.question(id:))
    }

    private var question: StudyQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    private var isCurrentQuestionFavorite: Bool {
        guard let question else { return false }
        return favorites.contains { $0.questionID == question.id }
    }

    private var currentNote: QuestionNote? {
        guard let question else { return nil }
        return notes.first { $0.questionID == question.id }
    }

    var body: some View {
        Group {
            if let question {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            CourseQuestionCard(
                                question: question,
                                positionText: "第 \(currentIndex + 1)／\(questions.count) 題"
                            )
                            .id("course.question.top")
                            .accessibilityIdentifier("course.prompt")

                            if let currentNote {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("我的筆記", systemImage: "note.text")
                                        .font(.headline)
                                    Text(currentNote.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .brandCard()
                            }
                        }
                        .padding()
                        .frame(maxWidth: 780)
                        .frame(maxWidth: .infinity)
                    }
                    .background(Color.craneBackground)
                    .safeAreaInset(edge: .bottom) {
                        CourseReviewBottomBar(
                            isFirst: currentIndex == 0,
                            isLast: currentIndex >= questions.count - 1,
                            isFavorite: isCurrentQuestionFavorite,
                            previous: { move(by: -1, proxy: proxy) },
                            toggleFavorite: toggleFavorite,
                            next: { move(by: 1, proxy: proxy) }
                        )
                    }
                }
            } else {
                ContentUnavailableView(
                    "沒有可複習的題目",
                    systemImage: "text.book.closed",
                    description: Text("這個工作項目目前沒有可顯示的題目。")
                )
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isJumping = true
                } label: {
                    Label("跳題", systemImage: "number.square")
                }
                .disabled(questions.isEmpty)

                Button(action: openNoteEditor) {
                    Label("編輯筆記", systemImage: currentNote == nil ? "note.text.badge.plus" : "note.text")
                }
                .disabled(question == nil)
                .accessibilityIdentifier("course.note")
            }
        }
        .sheet(isPresented: $isEditingNote) {
            NavigationStack {
                Form {
                    Section("我的筆記") {
                        TextEditor(text: $noteDraft)
                            .frame(minHeight: 180)
                            .accessibilityIdentifier("course.note.editor")
                    }
                    Section {
                        Text("筆記只保存在這台裝置，不會改寫題庫答案；清空後儲存即可刪除。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("題目筆記")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { isEditingNote = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("儲存", action: saveNote)
                            .accessibilityIdentifier("course.note.save")
                    }
                }
            }
        }
        .alert("跳至指定題號", isPresented: $isJumping) {
            TextField("1–\(max(questions.count, 1))", text: $jumpText)
                .keyboardType(.numberPad)
            Button("取消", role: .cancel) { jumpText = "" }
            Button("前往") { jumpToQuestion() }
                .disabled(!isValidJump)
        } message: {
            Text("請輸入這個複習範圍內的題號。")
        }
        .alert("紀錄無法儲存", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("知道了", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "未知錯誤")
        }
        .onAppear {
            selectInitialQuestion()
            saveReadingPosition()
        }
    }

    private var isValidJump: Bool {
        guard let number = Int(jumpText) else { return false }
        return (1...questions.count).contains(number)
    }

    private func selectInitialQuestion() {
        let targetID = initialQuestionID
            ?? (questionIDs == nil ? appStates.first(where: { $0.key == "primary" })?.lastQuestionID : nil)
        guard let targetID,
              let index = questions.firstIndex(where: { $0.id == targetID })
        else { return }
        currentIndex = index
    }

    private func move(by delta: Int, proxy: ScrollViewProxy) {
        guard !questions.isEmpty else { return }
        currentIndex = min(max(currentIndex + delta, 0), questions.count - 1)
        saveReadingPosition()
        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo("course.question.top", anchor: .top)
        }
    }

    private func jumpToQuestion() {
        guard let number = Int(jumpText), (1...questions.count).contains(number) else { return }
        currentIndex = number - 1
        jumpText = ""
        saveReadingPosition()
    }

    private func saveReadingPosition() {
        guard let question else { return }
        do {
            try LearningPersistence.saveLastQuestion(
                questionID: question.id,
                contentVersion: contentStore.contentVersion,
                appBuild: appBuild,
                in: modelContext
            )
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func toggleFavorite() {
        guard let question else { return }
        do {
            try LearningPersistence.toggleFavorite(questionID: question.id, in: modelContext)
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func openNoteEditor() {
        noteDraft = currentNote?.text ?? ""
        isEditingNote = true
    }

    private func saveNote() {
        guard let question else { return }
        do {
            try LearningPersistence.saveNote(questionID: question.id, text: noteDraft, in: modelContext)
            isEditingNote = false
        } catch {
            saveError = error.localizedDescription
        }
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }
}

private struct CourseQuestionCard: View {
    let question: StudyQuestion
    let positionText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text(question.publicCode)
                    .font(.caption.bold())
                    .foregroundStyle(Color.cranePrimaryBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.cranePrimaryBlue.opacity(0.10), in: Capsule())
                Spacer()
                Text(positionText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text("原始複習題")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(question.prompt)
                .font(.title3.bold())
                .fixedSize(horizontal: false, vertical: true)

            if let imageResource = question.imageResource {
                BundledQuestionImage(
                    resourceName: imageResource,
                    accessibilityLabel: question.imageAccessibilityLabel ?? "\(question.publicCode) 題目圖示"
                )
            }

            if let optionImages = question.optionImageResources {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(question.options.indices, id: \.self) { index in
                        VStack(spacing: 8) {
                            Text(String(UnicodeScalar(65 + index)!))
                                .font(.headline)
                                .foregroundStyle(Color.cranePrimaryBlue)
                            if optionImages.indices.contains(index), let resourceName = optionImages[index] {
                                BundledQuestionImage(
                                    resourceName: resourceName,
                                    accessibilityLabel: "選項 \(String(UnicodeScalar(65 + index)!)) 圖示",
                                    maxHeight: 120
                                )
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: 150)
                        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.craneBorder, lineWidth: 1)
                        }
                    }
                }
            }

            ReadingSection(
                title: "答案",
                text: question.answer,
                systemImage: "checkmark.circle.fill",
                tint: .craneSuccessGreen,
                background: Color.craneSuccessGreen.opacity(0.10)
            )

            if !question.explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ReadingSection(
                    title: "解析",
                    text: question.explanation,
                    systemImage: "lightbulb.fill",
                    tint: .craneAccentOrange,
                    background: Color.craneAccentOrange.opacity(0.10)
                )
            }

            if !question.alternativeAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ReadingSection(
                    title: "另外解答",
                    text: question.alternativeAnswer,
                    systemImage: "text.bubble.fill",
                    tint: .purple,
                    background: Color.purple.opacity(0.08)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("來源", systemImage: "checkmark.shield.fill")
                    .font(.headline)
                    .foregroundStyle(Color.cranePrimaryBlue)
                Text(question.publicSource)
                    .fixedSize(horizontal: false, vertical: true)
                if let url = question.publicSourceURL {
                    Link(destination: url) {
                        Label("開啟官方來源", systemImage: "arrow.up.right.square")
                    }
                }
                if !question.publicSourceCheckedAt.isEmpty {
                    Text("查核日期：\(question.publicSourceCheckedAt)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if question.accuracyStatus == "official-reference-reviewed" {
                    Text("官方參考答案已完成題文與明顯衝突檢查；不作為正式測試答案依據。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cranePrimaryBlue.opacity(0.07), in: RoundedRectangle(cornerRadius: 15))
        }
        .brandCard()
    }
}

private struct ReadingSection: View {
    let title: String
    let text: String
    let systemImage: String
    let tint: Color
    let background: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
            Text(text)
                .lineSpacing(4)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 15))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(tint)
                .frame(width: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

private struct CourseReviewBottomBar: View {
    let isFirst: Bool
    let isLast: Bool
    let isFavorite: Bool
    let previous: () -> Void
    let toggleFavorite: () -> Void
    let next: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: previous) {
                Label("上一題", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .disabled(isFirst)

            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title3)
                    .frame(width: 56, height: 48)
            }
            .accessibilityIdentifier("course.favorite")
            .accessibilityLabel(isFavorite ? "取消收藏" : "收藏此題")

            Button(action: next) {
                Label("下一題", systemImage: "chevron.right")
                    .labelStyle(.titleAndIcon)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .disabled(isLast)
        }
        .buttonStyle(.bordered)
        .tint(.cranePrimaryBlue)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
