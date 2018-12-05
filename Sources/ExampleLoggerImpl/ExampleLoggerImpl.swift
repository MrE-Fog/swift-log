//
// THIS IS NOT PART OF THE PITCH, JUST AN EXAMPLE HOW A LOGGER IMPLEMENTATION LOOKS LIKE
//

import Foundation
import ServerLoggerAPI

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return body()
    }
}

public final class ExampleLoggerImplementation: LogEmitter {
    private let formatter: DateFormatter
    private let identifier: String
    private let lock = NSLock()

    private var _logLevel: LogLevel = .info
    public var logLevel: LogLevel {
        get {
            return self.lock.withLock { self._logLevel }
        }
        set {
            self.lock.withLock {
                self._logLevel = newValue
            }
        }
    }

    public init(identifier: String) {
        self.identifier = identifier
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = Calendar(identifier: .gregorian)
        self.formatter = formatter
    }

    private func formatLevel(_ level: LogLevel) -> String {
        switch level {
        case .error:
            return "ERRO"
        case .warn:
            return "WARN"
        case .info:
            return "info"
        case .debug:
            return "dbug"
        case .trace:
            return "trce"
        }
    }

    public func log(level: LogLevel, message: String, file _: String, function _: String, line _: UInt) {
        print("\(self.formatter.string(from: Date()))\(self.prettyMetadata.map { " \($0)" } ?? "") \(self.formatLevel(level)): \(message)")
    }

    private var prettyMetadata: String?
    private var _metadata: LoggingMetadata? {
        didSet {
            self.prettyMetadata = !(self._metadata?.isEmpty ?? true) ? self._metadata!.map { "\($0)=\($1)" }.joined(separator: " ") : nil
        }
    }

    public var metadata: LoggingMetadata? {
        get {
            return self.lock.withLock { self._metadata }
        }
        set {
            self.lock.withLock { self._metadata = newValue }
        }
    }

    public subscript(diagnosticKey diagnosticKey: String) -> String? {
        get {
            return self.lock.withLock { self._metadata?[diagnosticKey] }
        }
        set {
            self.lock.withLock {
                if nil == self._metadata {
                    self._metadata = [:]
                }
                self._metadata![diagnosticKey] = newValue
            }
        }
    }
}
