import Foundation

@Observable
final class KalenderViewModel {
    enum State {
        case idle, loading, loaded([KalenderEvent]), error(String)
    }

    private(set) var state: State = .idle
    var selectedYear: Int
    var selectedMonth: Int

    private let repository: KalenderRepositoryProtocol

    init(repository: KalenderRepositoryProtocol) {
        self.repository = repository
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        self.selectedYear = now.year ?? 2025
        self.selectedMonth = now.month ?? 1
    }

    var events: [KalenderEvent] {
        guard case .loaded(let e) = state else { return [] }
        return e
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    func load() async {
        state = .loading
        do {
            let events = try await repository.fetchEvents(year: selectedYear, month: selectedMonth)
            state = .loaded(events)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func nextMonth() {
        if selectedMonth == 12 {
            selectedMonth = 1
            selectedYear += 1
        } else {
            selectedMonth += 1
        }
        Task { await load() }
    }

    func previousMonth() {
        if selectedMonth == 1 {
            selectedMonth = 12
            selectedYear -= 1
        } else {
            selectedMonth -= 1
        }
        Task { await load() }
    }
}
