#if os(macOS)

import Foundation
import OSLog

struct DarkbloomLogEntry: Equatable, Identifiable {
    let id: UUID
    let date: Date
    let message: String
    let category: String
    let level: OSLogEntryLog.Level
    
    init(from osLogEntry: OSLogEntryLog) {
        self.id = UUID()
        self.date = osLogEntry.date
        self.message = osLogEntry.composedMessage
        self.category = osLogEntry.category
        self.level = osLogEntry.level
    }
}

@MainActor @Observable
final class LocalLogController {
    private let subsystem = "dev.darkbloom.provider"
    private let maxLogEntries: Int = 2_000
    
    private(set) var logs: [DarkbloomLogEntry] = []
    private var streamTask: Task<Void, Never>?
    private var lastFetchDate = Date.now
    
    var unseenLogCount: Int = 0
    
    init() {}
    
    func startStreaming() {
        streamTask?.cancel()
        streamTask = Task {
            
            // Fetch historical logs
            if let historicalLogs = try? await fetchOlderLogs() {
                logs.append(contentsOf: historicalLogs.map(DarkbloomLogEntry.init))
                
                if let latest = historicalLogs.last?.date {
                    lastFetchDate = latest.addingTimeInterval(0.001)
                }
                
                if logs.count > maxLogEntries {
                    logs.removeFirst(logs.count - maxLogEntries)
                }
            }
            
            // Keep fetching latest logs
            while !Task.isCancelled {
                guard let newEntries = try? await fetchLogsSince(lastFetchDate) else {
                    try? await Task.sleep(for: .seconds(1))
                    continue
                }
                
                if let latest = newEntries.last?.date {
                    lastFetchDate = latest.addingTimeInterval(0.001)
                }
                
                logs.append(contentsOf: newEntries.map(DarkbloomLogEntry.init))
                
                if NavigationController.shared.activeTab != .logs {
                    unseenLogCount += newEntries.count
                }
                
                if logs.count > maxLogEntries {
                    logs.removeFirst(logs.count - maxLogEntries)
                }
                
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
    
    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
    }
    
    @concurrent private func fetchOlderLogs() async throws -> [OSLogEntryLog] {
        let store = try OSLogStore(scope: .system)
        let position = store.position(date: Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!)
        let predicate = NSPredicate(format: "subsystem == %@", subsystem)
        let entries = try store.getEntries(at: position, matching: predicate)
        return entries.compactMap { entry in
            guard let logEntry = entry as? OSLogEntryLog else { return nil }
            return logEntry
        }
        .sorted { $0.date < $1.date }
    }
    
    @concurrent private func fetchLogsSince(_ date: Date) async throws -> [OSLogEntryLog] {
        let store = try OSLogStore(scope: .system)
        let position = store.position(date: date)
        let predicate = NSPredicate(format: "subsystem == %@", subsystem)
        let entries = try store.getEntries(at: position, matching: predicate)
        return entries.compactMap { entry in
            guard let logEntry = entry as? OSLogEntryLog else { return nil }
            return logEntry
        }
        .sorted { $0.date < $1.date }
    }
}

#endif
