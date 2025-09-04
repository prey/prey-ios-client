import Foundation
import Darwin
import Darwin.Mach
import UIKit

final class CrashHandler {

    private static var signalLogPath: String = {
        // Precompute a safe path for signal logs (created at install time)
        let dir = CrashHandler.crashReportsDirectory()
        return dir.appendingPathComponent("signals.log").path
    }()

    private static let crashFileDateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static func install() {
        // Ensure directory exists early
        do { try FileManager.default.createDirectory(at: crashReportsDirectory(), withIntermediateDirectories: true) } catch {}

        NSSetUncaughtExceptionHandler { exception in
            CrashHandler.handle(exception: exception)
        }

        // Register minimal, async-signal-safe handlers
        signal(SIGABRT, crashHandlerSignalShim)
        signal(SIGILL,  crashHandlerSignalShim)
        signal(SIGSEGV, crashHandlerSignalShim)
        signal(SIGFPE,  crashHandlerSignalShim)
        signal(SIGBUS,  crashHandlerSignalShim)
        signal(SIGPIPE, crashHandlerSignalShim)
    }

    private static func crashReportsDirectory() -> URL {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("CrashReports", isDirectory: true)
        return url
    }

    private static func handle(exception: NSException) {
        // Persist minimal info; full payload is built on next launch
        let info: [String: Any] = [
            "message": (exception.reason?.isEmpty == false ? exception.reason! : exception.name.rawValue),
            "backtrace": exception.callStackSymbols.joined(separator: "\n")
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: info, options: [])
            let file = crashReportsDirectory().appendingPathComponent("crash-\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: file, options: .atomic)
        } catch {
            // Avoid heavy work inside crash handling; ignore failures
        }
    }

    // MARK: - Async-signal-safe logging for fatal signals
    fileprivate static func handleSignal(_ signo: Int32) {
        // Compose a small line and append using low-level POSIX calls only
        let line = "signal=\(signo) time=\(time(nil)) pid=\(getpid())\n"
        line.withCString { cstr in
            let fd = open(signalLogPath, O_WRONLY | O_CREAT | O_APPEND, 0o644)
            if fd >= 0 {
                _ = write(fd, cstr, strlen(cstr))
                _ = close(fd)
            }
        }

        // Restore default and re-raise so the crash is not swallowed
        signal(signo, SIG_DFL)
        raise(signo)
    }

    // MARK: - Utilities

    static func pendingCrashReportURLs() -> [URL] {
        let dir = crashReportsDirectory()
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        return files.filter { $0.lastPathComponent.hasPrefix("crash-") && $0.pathExtension == "json" }
    }

    static func forceCrashForTesting() {
        // Write a pre-crash marker to verify path and write permissions
        let ts = Int(Date().timeIntervalSince1970)
        appendSignalLogLine("ios error ts=\(ts) pid=\(getpid())")
        PreyLogger("wrote pre-crash marker to signals.log; raising SIGABRT in test mode")
        // Using raise triggers our signal handler path
        raise(SIGABRT)
    }

    // MARK: - Uploading pending reports to server
    static func uploadPendingReportsIfPossible() {
        let dir = crashReportsDirectory()
        PreyLogger("scanning pending crash reports for upload at \(dir.path)")
        // First, send JSON exception reports
        let crashFiles = pendingCrashReportURLs().sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        PreyLogger("found \(crashFiles.count) crash json file(s)")
        for url in crashFiles {
            do {
                let data = try Data(contentsOf: url)
                var obj: Any = [:]
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) { obj = json }
                let dict = obj as? [String: Any] ?? [:]
                let message = (dict["message"] as? String)
                    ?? (dict["reason"] as? String)
                    ?? (dict["name"] as? String)
                    ?? "uncaught_exception"
                let backtrace = (dict["backtrace"] as? String)
                    ?? (dict["callStack"] as? String)
                    ?? ""
                var payload = buildBasePayload()
                payload["message"] = message
                payload["backtrace"] = backtrace
                let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)??.int64Value ?? Int64(data.count)
                PreyLogger("uploading crash report \(url.lastPathComponent) (\(size) bytes)")
                CrashHandler.sendExceptionJSON(payload, tag: "EXCEPTIONS-JSON") { success in
                    if success {
                        try? FileManager.default.removeItem(at: url)
                        PreyLogger("uploaded and removed signals.log")
                    } else {
                        PreyLogger("upload failed for signals.log; will retry on next launch")
                    }
                }

            } catch {
                // Keep file for next launch
                continue
            }
        }

        // Then, send signal log entries as a single aggregated event if present
        let sigPath = signalLogPath
        if FileManager.default.fileExists(atPath: sigPath), let raw = try? String(contentsOfFile: sigPath, encoding: .utf8) {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                var payload = buildBasePayload()
                let last = trimmed.split(separator: "\n").map(String.init).last ?? "fatal_signal"
                payload["message"] = last
                payload["backtrace"] = trimmed
                let lineCount = trimmed.split(separator: "\n").count
                PreyLogger("uploading signals log (\(lineCount) lines, \(trimmed.utf8.count) bytes)")

                CrashHandler.sendExceptionJSON(payload, tag: "EXCEPTIONS-SIGNAL") { success in
                    if success {
                        try? FileManager.default.removeItem(atPath: sigPath)
                        PreyLogger("uploaded and removed signals.log")
                    } else {
                        PreyLogger("upload failed for signals.log; will retry on next launch")
                    }
                }
            } else {
                PreyLogger("signals.log exists but is empty; skipping upload")
            }
        } else {
            PreyLogger("no signals.log present")
        }
    }

    // MARK: - Local JSON sender with slash-unescaped body
    private static func sendExceptionJSON(_ payload: [String: Any], tag: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: exceptionsUrl) else { completion(false); return }
        var req = URLRequest(url: url)
        req.httpMethod = Method.POST.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(PreyHTTPClient.sharedInstance.userAgent, forHTTPHeaderField: "User-Agent")
        do {
            let data: Data
            if #available(iOS 15.0, *) {
                data = try JSONSerialization.data(withJSONObject: payload, options: [.withoutEscapingSlashes])
            } else {
                let raw = try JSONSerialization.data(withJSONObject: payload, options: [])
                if var s = String(data: raw, encoding: .utf8) {
                    s = s.replacingOccurrences(of: "\\/", with: "/")
                    data = s.data(using: .utf8) ?? raw
                } else {
                    data = raw
                }
            }
            req.httpBody = data
        } catch {
            completion(false); return
        }
        PreyHTTPClient.sharedInstance.performRequest(req) { data, response, error in
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    // MARK: - Payload builders matching exceptions.js
    private static func buildBasePayload() -> [String: Any] {
        let appInfo = Bundle.main.infoDictionary ?? [:]
        let appVersion = (appInfo["CFBundleShortVersionString"] as? String) ?? "0"
        let deviceKey = PreyConfig.sharedInstance.deviceKey
        let device = UIDevice.current
        let env = ProcessInfo.processInfo.environment
        let args = CommandLine.arguments
        let cwd = FileManager.default.currentDirectoryPath
        let uid = UInt32(getuid())
        let gid = UInt32(getgid())
        let pid = Int(getpid())
        let framework = "Prey/\(appVersion)"
        let version = device.systemVersion
        let platform = "ios"
        let release = osRelease()
        let user = usernameFromUID(uid: uid)
        let memory = memoryUsage()

        let payload: [String: Any] = [
            "deviceKey": deviceKey ?? NSNull(),
            "cwd": cwd,
            "language": "swift",
            "version": version,
            "framework": framework,
            "platform": platform,
            "release": release,
            "user": user ?? NSNull(),
            "args": args,
            "env": env,
            "gid": gid,
            "uid": uid,
            "pid": pid,
            "memory": memory
        ]
        return payload
    }

    // MARK: - Low-level append helper (POSIX)
    private static func appendSignalLogLine(_ text: String) {
        let line = text + "\n"
        line.withCString { cstr in
            let fd = open(signalLogPath, O_WRONLY | O_CREAT | O_APPEND, 0o644)
            if fd >= 0 {
                _ = write(fd, cstr, strlen(cstr))
                _ = close(fd)
            }
        }
    }

    private static func usernameFromUID(uid: uid_t) -> String? {
        guard let pw = getpwuid(uid) else { return nil }
        if let namePtr = pw.pointee.pw_name { return String(cString: namePtr) }
        return nil
    }

    private static func osRelease() -> String {
        var uts = utsname()
        uname(&uts)
        let rel = withUnsafePointer(to: &uts.release) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                return String(cString: $0)
            }
        }
        return rel
    }

    private static func memoryUsage() -> [String: Any] {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            return [
                "resident_size": NSNumber(value: info.resident_size),
                "virtual_size": NSNumber(value: info.virtual_size)
            ]
        } else {
            return ["error": Int(kerr)]
        }
    }
}

// Top-level C function pointer shim for signal() API
private func crashHandlerSignalShim(_ signo: Int32) {
    CrashHandler.handleSignal(signo)
}
