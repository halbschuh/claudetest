import SwiftUI

struct KalenderView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: KalenderViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    content(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Kalender")
        }
        .task {
            guard viewModel == nil else { return }
            let repo = KalenderRepository(apiClient: env.apiClient, modelContext: modelContext)
            viewModel = KalenderViewModel(repository: repo)
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(vm: KalenderViewModel) -> some View {
        VStack(spacing: 0) {
            monthNavigator(vm: vm)
                .padding()
                .background(Color.appBackground)

            Divider()

            switch vm.state {
            case .idle, .loading:
                ProgressView("Lade Ereignisse …")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded:
                if vm.events.isEmpty {
                    ContentUnavailableView(
                        "Keine Ereignisse",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Für diesen Monat sind keine historischen Ereignisse verzeichnet.")
                    )
                } else {
                    List(vm.events) { event in
                        KalenderEventRowView(event: event)
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.load() }
                }

            case .error(let msg):
                ContentUnavailableView(
                    "Fehler",
                    systemImage: "exclamationmark.triangle",
                    description: Text(msg)
                )
                .onTapGesture { Task { await vm.load() } }
            }
        }
    }

    private func monthNavigator(vm: KalenderViewModel) -> some View {
        HStack {
            Button(action: { vm.previousMonth() }) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(vm.monthTitle)
                .font(.appHeadline)
            Spacer()
            Button(action: { vm.nextMonth() }) {
                Image(systemName: "chevron.right")
            }
        }
    }
}

private struct KalenderEventRowView: View {
    let event: KalenderEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(dayString)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(Color.appSepia)
                    .frame(width: 40)
                Text(event.title)
                    .font(.appHeadline)
            }
            Text(event.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .padding(.leading, 48)

            if !event.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(event.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.appSepia.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.leading, 48)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var dayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMM"
        return formatter.string(from: event.historicalDate)
    }
}
