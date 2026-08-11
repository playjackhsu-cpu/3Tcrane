import SwiftData
import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [Favorite]
    @Query private var notes: [QuestionNote]
    @Query private var appStates: [AppState]
    @State private var currentIndex = 0
    @State private var selectedIndex: Int?
    @State private var saveError: String?
    @State private var isEditingNote = false
    @State private var noteDraft = ""
    let questionIDs: [String]?
    let initialQuestionID: String?
    let title: String

    init(
        questionIDs: [String]? = nil,
        initialQuestionID: String? = nil,
        title: String = "題庫練習"
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("單選題")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.cranePrimaryBlue, in: Capsule())
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(currentIndex + 1) / \(questions.count)")
                                    .font(.subheadline.bold().monospacedDigit())
                                Text(question.publicCode)
                                    .font(.caption)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        SwiftUI.ProgressView(value: Double(currentIndex + 1), total: Double(questions.count))
                            .accessibilityLabel("第 \(currentIndex + 1) 題，共 \(questions.count) 題")

                        Text(question.prompt)
                            .font(.title3.bold())
                            .lineSpacing(4)
                            .accessibilityIdentifier("practice.prompt")

                        if let imageResource = question.imageResource {
                            BundledQuestionImage(
                                resourceName: imageResource,
                                accessibilityLabel: question.imageAccessibilityLabel ?? "\(question.publicCode) 題目圖示"
                            )
                        }

                        ForEach(question.options.indices, id: \.self) { index in
                            optionButton(question: question, index: index)
                        }

                        if let selectedIndex {
                            AnswerExplanationCard(question: question, selectedIndex: selectedIndex)

                            HStack {
                                Button("上一題", action: moveToPreviousQuestion)
                                    .buttonStyle(.bordered)
                                    .disabled(questions.count < 2)
                                Spacer()
                                Button(
                                    currentIndex == questions.count - 1 ? "回到第一題" : "下一題",
                                    action: moveToNextQuestion
                                )
                                .buttonStyle(.borderedProminent)
                                .accessibilityIdentifier("practice.next")
                            }

                            HStack(spacing: 22) {
                                Button(action: toggleFavorite) {
                                    Label(isCurrentQuestionFavorite ? "已收藏" : "收藏", systemImage: isCurrentQuestionFavorite ? "star.fill" : "star")
                                }
                                Button(action: openNoteEditor) {
                                    Label(currentNote == nil ? "筆記" : "已筆記", systemImage: "note.text")
                                }
                                Spacer()
                                Label("學習紀錄已保存", systemImage: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.cranePrimaryBlue)
                            .padding(.top, 4)
                        }

                        if let currentNote {
                            GroupBox("我的筆記") {
                                Text(currentNote.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                    .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .background(Color.craneBackground)
            } else {
                ContentUnavailableView(
                    "沒有可用題目",
                    systemImage: "questionmark.folder",
                    description: Text("這個清單可能已因內容版本更新而沒有可顯示的題目。")
                )
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: toggleFavorite) {
                    Label(
                        isCurrentQuestionFavorite ? "取消收藏" : "收藏題目",
                        systemImage: isCurrentQuestionFavorite ? "star.fill" : "star"
                    )
                }
                .disabled(question == nil)
                .accessibilityIdentifier("practice.favorite")

                Button(action: openNoteEditor) {
                    Label("編輯筆記", systemImage: currentNote == nil ? "note.text.badge.plus" : "note.text")
                }
                .disabled(question == nil)
                .accessibilityIdentifier("practice.note")
            }
        }
        .sheet(isPresented: $isEditingNote) {
            NavigationStack {
                Form {
                    Section("我的筆記") {
                        TextEditor(text: $noteDraft)
                            .frame(minHeight: 180)
                            .accessibilityIdentifier("note.editor")
                    }
                    Section {
                        Text("筆記只保存在這台裝置，不會取代題庫答案。清空內容後儲存即可刪除筆記。")
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
                            .accessibilityIdentifier("note.save")
                    }
                }
            }
        }
        .alert("紀錄無法儲存", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("知道了", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "未知錯誤")
        }
        .onAppear(perform: selectInitialQuestion)
    }

    private func optionButton(question: StudyQuestion, index: Int) -> some View {
        Button {
            guard selectedIndex == nil else { return }
            selectedIndex = index
            do {
                try LearningPersistence.recordAnswer(
                    questionID: question.id,
                    selectedIndex: index,
                    correctIndex: question.answerIndex,
                    in: modelContext
                )
                try LearningPersistence.saveLastQuestion(
                    questionID: question.id,
                    contentVersion: contentStore.contentVersion,
                    appBuild: appBuild,
                    in: modelContext
                )
            } catch {
                saveError = error.localizedDescription
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(optionColor(question: question, index: index).opacity(0.12))
                    Text(String(UnicodeScalar(65 + index)!))
                        .font(.headline)
                        .foregroundStyle(optionColor(question: question, index: index))
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 8) {
                    Text(question.options[index])
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    if let resources = question.optionImageResources,
                       resources.indices.contains(index),
                       let resourceName = resources[index] {
                        BundledQuestionImage(
                            resourceName: resourceName,
                            accessibilityLabel: "選項 \(String(UnicodeScalar(65 + index)!)) 圖示",
                            maxHeight: 130
                        )
                    }
                }
                Spacer()
                if selectedIndex != nil {
                    Image(systemName: optionSymbol(question: question, index: index))
                        .foregroundStyle(optionColor(question: question, index: index))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(optionBackground(question: question, index: index), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(optionColor(question: question, index: index).opacity(0.55), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(selectedIndex != nil)
        .accessibilityIdentifier("practice.option.\(index)")
        .accessibilityLabel(optionAccessibilityLabel(question: question, index: index))
    }

    private func optionSymbol(question: StudyQuestion, index: Int) -> String {
        guard let selectedIndex else { return "circle" }
        if index == question.answerIndex { return "checkmark.circle.fill" }
        if index == selectedIndex { return "xmark.circle.fill" }
        return "circle"
    }

    private func optionColor(question: StudyQuestion, index: Int) -> Color {
        guard let selectedIndex else { return .craneNeutralGray }
        if index == question.answerIndex { return .green }
        if index == selectedIndex { return .red }
        return .craneNeutralGray
    }

    private func optionBackground(question: StudyQuestion, index: Int) -> Color {
        guard let selectedIndex else { return Color(uiColor: .secondarySystemGroupedBackground) }
        if index == question.answerIndex { return .green.opacity(0.12) }
        if index == selectedIndex { return .red.opacity(0.1) }
        return Color(uiColor: .secondarySystemGroupedBackground)
    }

    private func optionAccessibilityLabel(question: StudyQuestion, index: Int) -> String {
        var label = "選項 \(index + 1)，\(question.options[index])"
        if selectedIndex != nil {
            if index == question.answerIndex {
                label += "，正確答案"
            } else if index == selectedIndex {
                label += "，你的答案，錯誤"
            }
        }
        return label
    }

    private func selectInitialQuestion() {
        let targetID = initialQuestionID
            ?? (questionIDs == nil ? appStates.first(where: { $0.key == "primary" })?.lastQuestionID : nil)
        guard let targetID,
              let index = questions.firstIndex(where: { $0.id == targetID })
        else { return }
        currentIndex = index
    }

    private func moveToNextQuestion() {
        guard !questions.isEmpty else { return }
        currentIndex = (currentIndex + 1) % questions.count
        selectedIndex = nil
    }

    private func moveToPreviousQuestion() {
        guard !questions.isEmpty else { return }
        currentIndex = (currentIndex - 1 + questions.count) % questions.count
        selectedIndex = nil
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
            try LearningPersistence.saveNote(
                questionID: question.id,
                text: noteDraft,
                in: modelContext
            )
            isEditingNote = false
        } catch {
            saveError = error.localizedDescription
        }
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }
}

private struct AnswerExplanationCard: View {
    let question: StudyQuestion
    let selectedIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(
                selectedIndex == question.answerIndex ? "答對了" : "答錯了",
                systemImage: selectedIndex == question.answerIndex ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .font(.headline)
            .foregroundStyle(selectedIndex == question.answerIndex ? .green : .red)

            LabeledContent("正確答案", value: question.answer)
            Divider()
            Text("解析").font(.headline)
            Text(question.explanation)

            if !question.alternativeAnswer.isEmpty {
                Divider()
                Text("另外解答").font(.headline)
                Text(question.alternativeAnswer)
            }

            if let url = question.publicSourceURL {
                Divider()
                Link(destination: url) {
                    Label(question.publicSource, systemImage: "arrow.up.right.square")
                }
            }
            if question.accuracyStatus == "official-reference-reviewed" {
                Text("官方參考答案已完成題文與明顯衝突檢查；不作為正式測試答案依據。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
            .padding()
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.craneBorder, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        .accessibilityIdentifier("practice.explanation")
    }
}
