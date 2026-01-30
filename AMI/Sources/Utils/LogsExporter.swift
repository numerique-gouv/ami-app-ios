import Foundation
import OSLog
import UIKit

struct LogsExporter {
    private static let MAX_LOG_ENTRIES = 5000
    private static let MAX_LOG_SIZE = 10 * 1024 * 1024 // 10 MB

    enum LogsExporterError: Error {
        case unableToAccessLogs
        case unableToWriteLogFile

        var description: String {
            switch self {
            case .unableToAccessLogs: AMIL10n.logsErrorUnableToAccessLog
            case .unableToWriteLogFile: AMIL10n.logsErrorUnableToWriteLog
            }
        }
    }

    var mainRootViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }

    private let userId: String?

    init(userId: String? = nil) {
        self.userId = userId
    }

    func shareLogs() {
        do {
            let logContent = try grabLogEntries()
            let logFileUrl = try writeToTemporaryFile(content: logContent)
            Task { @MainActor in
                presentShareLogsSheet(logFileURL: logFileUrl)
            }
        } catch {
            if let error = error as? LogsExporterError {
                Task { @MainActor in
                    handleError(error)
                }
            }
        }
    }

    // Grab and concatenate recents logs.
    private func grabLogEntries() throws -> String {
        let isoFormatter = ISO8601DateFormatter()
        let oneHourAgo = Date().addingTimeInterval(-3600)

        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(date: oneHourAgo)
            return try store.getEntries(at: position)
                .compactMap { $0 as? OSLogEntryLog }
                // last MAX_LOG_ENTRIES entries
                .suffix(Self.MAX_LOG_ENTRIES)
                // from recent to old.
                .reversed()
                // Accumulate log entry from recent to old up to MAX_LOG_SIZE
                .reduce("") { partialResult, logEntry in
                    guard let partialResultSize = partialResult.data(using: .utf8)?.count,
                          partialResultSize < Self.MAX_LOG_SIZE else {
                        return partialResult
                    }
                    let logToAdd = (partialResult.isEmpty ? "" : "\n") + "[\(isoFormatter.string(from: logEntry.date))] \(logEntry.composedMessage)"
                    guard let logToAddSize = logToAdd.data(using: .utf8)?.count,
                          partialResultSize + logToAddSize < Self.MAX_LOG_SIZE else {
                        return partialResult
                    }
                    return partialResult + logToAdd
                }
        } catch {
            throw LogsExporterError.unableToAccessLogs
        }
    }

    private func writeToTemporaryFile(content: String) throws -> URL {
        // Create new filename containing date and hour.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())

        let filename = if let userId,
                          !userId.isEmpty,
                          userId != "null" {
            "ami_logs_ios_\(userId)_\(timestamp).txt"
        } else {
            "ami_logs_ios_\(timestamp).txt"
        }

        // Create path to temporary file.
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            // Write concatenated logs into temporary file.
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            throw LogsExporterError.unableToWriteLogFile
        }

        return fileURL
    }

    @MainActor
    private func presentShareLogsSheet(logFileURL: URL) {
        let activity = UIActivityViewController(activityItems: [logFileURL], applicationActivities: nil)

        mainRootViewController?.present(activity, animated: true)
    }

    @MainActor
    private func handleError(_ error: LogsExporterError) {
        let alert = UIAlertController(title: AMIL10n.error,
                                      message: error.description,
                                      preferredStyle: .alert)

        let okAction = UIAlertAction(title: AMIL10n.ok, style: .default)

        alert.addAction(okAction)

        mainRootViewController?.present(alert, animated: true)
    }
}
