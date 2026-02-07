import Foundation
import Libbox

/// 仅用于打印日志
public final class CommandClient {
    private var client: LibboxCommandClient?
    private var connectTask: Task<Void, Error>?

    public init() {}

    /// 连接日志
    public func connect() {
        if client != nil { return }
        if let connectTask {
            connectTask.cancel()
        }
        connectTask = Task {
            await connectToLog()
        }
    }

    /// 断开连接
    public func disconnect() {
        connectTask?.cancel()
        connectTask = nil
        if let client {
            try? client.disconnect()
            self.client = nil
        }
    }

    // MARK: - 内部连接逻辑
    private nonisolated func connectToLog() async {
        let options = LibboxCommandClientOptions()
        options.command = LibboxCommandLog
        options.statusInterval = Int64(500 * NSEC_PER_MSEC) // 500ms
        let newClient = LibboxNewCommandClient(LogHandler(), options)!

        for i in 0..<10 {
            do {
                try await Task.sleep(nanoseconds: UInt64(Double(100 + (i * 50)) * Double(NSEC_PER_MSEC)))
                try newClient.connect()
                return
            } catch {
                continue
            }
        }
        try? newClient.disconnect()
    }

    // MARK: - 日志处理
    private class LogHandler: NSObject, LibboxCommandClientHandlerProtocol {
        func connected() {
            print("✅ [LogClient] Connected")
        }

        func disconnected(_ message: String?) {
            print("❌ [LogClient] Disconnected: \(message ?? "No message")")
        }

        func clearLogs() {
            print("🧹 [LogClient] Logs cleared")
        }

        func writeLogs(_ messageList: (any LibboxStringIteratorProtocol)?) {
            guard let messageList else { return }
            while messageList.hasNext() {
                let msg = messageList.next() // 直接取
                print("🪵 \(msg)")
            }
        }

        // 以下方法不处理
        func writeStatus(_ message: LibboxStatusMessage?) {}
        func writeGroups(_ groups: (any LibboxOutboundGroupIteratorProtocol)?) {}
        func initializeClashMode(_ modeList: (any LibboxStringIteratorProtocol)?, currentMode: String?) {}
        func updateClashMode(_ newMode: String?) {}
        func write(_ message: LibboxConnections?) {}
        func clearLog() {}
        func writeLog(_ message: String?) {}
    }
}
