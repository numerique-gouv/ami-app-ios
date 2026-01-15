import Foundation
import OSLog
import UIKit

enum LogsExporter {
    static func shareLogs(userFcHash: String? = nil) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())

        let filename: String
        if let hash = userFcHash, !hash.isEmpty, hash != "null" {
            filename = "ami_logs_ios_\(hash)_\(timestamp).txt"
        } else {
            filename = "ami_logs_ios_\(timestamp).txt"
        }

        var logsContent = ""
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let oneHourAgo = Date().addingTimeInterval(-3600)
            let position = store.position(date: oneHourAgo)
            let entries = try store.getEntries(at: position)
                .compactMap { $0 as? OSLogEntryLog }
                .suffix(5000)

            let isoFormatter = ISO8601DateFormatter()
            logsContent = entries.map { "[\(isoFormatter.string(from: $0.date))] \($0.composedMessage)" }.joined(separator: "\n")
        } catch {
            logsContent = "Failed to retrieve logs: \(error.localizedDescription)"
        }

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try logsContent.write(to: fileURL, atomically: true, encoding: .utf8)

            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
            }
        } catch {
            print("LogsExporter: Failed to write logs file: \(error)")
        }
    }
}
