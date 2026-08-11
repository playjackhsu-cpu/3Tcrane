import SwiftUI
import UIKit

enum AppDestination: String, CaseIterable, Identifiable {
    case home
    case learn
    case practice
    case progress
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "首頁"
        case .learn: "課程"
        case .practice: "測驗"
        case .progress: "紀錄"
        case .settings: "我的"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .learn: "book.closed"
        case .practice: "checklist"
        case .progress: "chart.bar"
        case .settings: "person.crop.circle"
        }
    }
}

struct AppShell: View {
    @State private var selection: AppDestination = .home
    @State private var splitVisibility: NavigationSplitViewVisibility = .all

    private var usesSidebarNavigation: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Group {
            if usesSidebarNavigation {
                NavigationSplitView(columnVisibility: $splitVisibility) {
                    List(AppDestination.allCases) { destination in
                        Button {
                            selection = destination
                        } label: {
                            Label(destination.title, systemImage: destination.systemImage)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                            .buttonStyle(.plain)
                            .listRowBackground(
                                selection == destination
                                    ? Color.cranePrimaryBlue.opacity(0.12)
                                    : Color.clear
                            )
                            .accessibilityIdentifier("sidebar.\(destination.rawValue)")
                            .accessibilityAddTraits(selection == destination ? .isSelected : [])
                    }
                    .navigationTitle("起重機考照通")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 280)
                } detail: {
                    destinationView(selection)
                        .id(selection)
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                TabView(selection: $selection) {
                    ForEach(AppDestination.allCases) { destination in
                        destinationView(destination)
                            .tag(destination)
                            .tabItem {
                                Label(destination.title, systemImage: destination.systemImage)
                            }
                    }
                }
            }
        }
        .tint(.cranePrimaryBlue)
    }

    @ViewBuilder
    private func destinationView(_ destination: AppDestination) -> some View {
        switch destination {
        case .home:
            NavigationStack {
                HomeView(onSelectDestination: { selection = $0 })
            }
        case .learn:
            NavigationStack { LearnView() }
        case .practice:
            NavigationStack { TestHubView() }
        case .progress:
            NavigationStack { ProgressView() }
        case .settings:
            NavigationStack { SettingsView() }
        }
    }
}
