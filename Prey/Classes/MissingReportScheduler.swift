//
//  MissingReportScheduler.swift
//  Prey
//
//  Schedules background refresh tasks to run missing reports at server-defined intervals
//  without keeping GPS on continuously.
//

import Foundation
import BackgroundTasks
import UIKit

class MissingReportScheduler {
    static func scheduleNext(after seconds: TimeInterval) {
        guard seconds > 0 else { return }

        let earliest = Date(timeIntervalSinceNow: seconds)

        let refreshId = AppDelegate.appRefreshTaskIdentifier
        let request = BGAppRefreshTaskRequest(identifier: refreshId)
        request.earliestBeginDate = earliest

        do {
            try BGTaskScheduler.shared.submit(request)
            PreyLogger("Scheduled next missing report refresh ~in \(Int(seconds))s")
        } catch {
            PreyLogger("BGTaskScheduler submit failed for missing report: \(error.localizedDescription)")
        }
    }

    static func maybeRunIfDue(interval seconds: TimeInterval, lastRun: Date?) {
        let now = Date()
        if let last = lastRun, now.timeIntervalSince(last) < seconds { return }
        // Trigger a single report cycle
        let report = Report(withTarget: kAction.report, withCommand: kCommand.get, withOptions: PreyConfig.sharedInstance.reportOptions)
        // Prevent creating a repeating timer; call the cycle directly
        report.runReportCycle()
    }
}

