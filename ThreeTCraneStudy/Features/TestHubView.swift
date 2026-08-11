import SwiftData
import SwiftUI

struct TestHubView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @Query private var progress: [QuestionProgress]
    @Query private var favorites: [Favorite]

    private var wrongCount: Int {
        progress.filter { item in
            let state = MasteryState(rawValue: item.masteryState) ?? .new
            return state == .needsReview || (state == .learning && item.attemptCount > item.correctCount)
        }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("題庫測驗")
                        .font(.largeTitle.bold())
                    Text("先作答，再查看正確答案、解析與來源")
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    NavigationLink {
                        PracticeView(title: "題庫練習")
                    } label: {
                        TestFeatureTile(
                            title: "題庫練習",
                            subtitle: "全部 \(contentStore.questions.count) 題",
                            assetName: "question_bank",
                            badge: "依序作答"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("testHub.practice")

                    NavigationLink {
                        StudyLibraryView(initialSection: .wrong)
                    } label: {
                        TestFeatureTile(
                            title: "錯題複習",
                            subtitle: wrongCount == 0 ? "目前沒有錯題" : "待補強 \(wrongCount) 題",
                            assetName: "wrong_answer_review",
                            badge: "重複練習"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("testHub.wrong")

                    NavigationLink {
                        ExamSetupView()
                    } label: {
                        TestFeatureTile(
                            title: "模擬測驗",
                            subtitle: "正式模擬或快速練習",
                            assetName: "mock_exam",
                            badge: "80 題・100 分鐘"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("testHub.exam")

                    NavigationLink {
                        StudyLibraryView(initialSection: .favorites)
                    } label: {
                        TestFeatureTile(
                            title: "收藏與筆記",
                            subtitle: favorites.isEmpty ? "尚未收藏題目" : "已收藏 \(favorites.count) 題",
                            assetName: "favorites",
                            badge: "自訂清單"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("testHub.library")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("測驗規則", systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundStyle(Color.cranePrimaryBlue)
                    Text("題庫練習在選答後立即訂正；錯題會自動加入待補強清單。模擬測驗在交卷前不顯示答案。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .brandCard()
            }
            .padding()
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
        }
        .background(Color.craneBackground)
        .navigationTitle("測驗")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TestFeatureTile: View {
    let title: String
    let subtitle: String
    let assetName: String
    let badge: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .foregroundStyle(Color.cranePrimaryBlue.opacity(0.65))
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.craneNeutralDark)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text(badge)
                .font(.caption2.bold())
                .foregroundStyle(Color.cranePrimaryBlue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.cranePrimaryBlue.opacity(0.09), in: Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 178, alignment: .topLeading)
        .brandCard(padding: 14)
    }
}

enum StudyLibrarySection: String, CaseIterable, Identifiable {
    case wrong
    case favorites
    case notes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wrong: "錯題"
        case .favorites: "收藏"
        case .notes: "筆記"
        }
    }
}

struct StudyLibraryView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @Query(sort: \QuestionProgress.lastAnsweredAt, order: .reverse)
    private var progress: [QuestionProgress]
    @Query(sort: \Favorite.createdAt, order: .reverse)
    private var favorites: [Favorite]
    @Query(sort: \QuestionNote.updatedAt, order: .reverse)
    private var notes: [QuestionNote]
    @State private var section: StudyLibrarySection

    init(initialSection: StudyLibrarySection = .wrong) {
        _section = State(initialValue: initialSection)
    }

    private var wrongQuestionIDs: [String] {
        progress.compactMap { item in
            let state = MasteryState(rawValue: item.masteryState) ?? .new
            let needsReview = state == .needsReview
                || (state == .learning && item.attemptCount > item.correctCount)
            return needsReview ? item.questionID : nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("學習清單", selection: $section) {
                ForEach(StudyLibrarySection.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                switch section {
                case .wrong:
                    questionList(
                        title: "錯題複習",
                        ids: wrongQuestionIDs,
                        emptyTitle: "目前沒有錯題",
                        emptySystemImage: "checkmark.circle"
                    )
                case .favorites:
                    questionList(
                        title: "收藏練習",
                        ids: favorites.map(\.questionID),
                        emptyTitle: "尚未收藏題目",
                        emptySystemImage: "star"
                    )
                case .notes:
                    if notes.isEmpty {
                        ContentUnavailableView("尚未建立筆記", systemImage: "note.text")
                    } else {
                        ForEach(notes) { note in
                            NavigationLink {
                                PracticeView(initialQuestionID: note.questionID, title: "筆記題目")
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(questionTitle(note.questionID))
                                        .font(.headline)
                                        .lineLimit(2)
                                    Text(note.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("複習資料夾")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func questionList(
        title: String,
        ids: [String],
        emptyTitle: String,
        emptySystemImage: String
    ) -> some View {
        if ids.isEmpty {
            ContentUnavailableView(emptyTitle, systemImage: emptySystemImage)
        } else {
            Section {
                NavigationLink {
                    PracticeView(questionIDs: ids, title: title)
                } label: {
                    Label("開始練習（\(ids.count) 題）", systemImage: "play.fill")
                        .font(.headline)
                }
            }
            Section("題目") {
                ForEach(ids, id: \.self) { id in
                    NavigationLink {
                        PracticeView(questionIDs: ids, initialQuestionID: id, title: title)
                    } label: {
                        Text(questionTitle(id)).lineLimit(3)
                    }
                }
            }
        }
    }

    private func questionTitle(_ id: String) -> String {
        contentStore.question(id: id)?.prompt ?? "已下架題目（\(id)）"
    }
}
