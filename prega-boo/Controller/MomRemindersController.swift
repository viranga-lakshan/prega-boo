import SwiftUI

/// Default copy and sample data for the mom Reminders screen (until backed by notifications API).
enum MomRemindersController {
    static func upcomingDefaults() -> [MomUpcomingReminderItem] {
        [
            MomUpcomingReminderItem(
                id: UUID(),
                sortKey: "2099-01-01",
                scheduleAt: nil,
                title: "Clinic Appointment",
                scheduleText: "Tomorrow, 10:00 AM",
                tag: .health,
                metadata: "Dr. Sarah Miller",
                iconSystemName: "calendar",
                source: .clinicMom,
                dbNotificationEnabled: true
            ),
            MomUpcomingReminderItem(
                id: UUID(),
                sortKey: "2099-01-02",
                scheduleAt: nil,
                title: "Baby Vaccination",
                scheduleText: "Friday, 2:30 PM",
                tag: .pediatric,
                metadata: "6-Month Checkup",
                iconSystemName: "syringe",
                source: .clinicChild,
                dbNotificationEnabled: true
            )
        ]
    }

    static func historyDefaults() -> [MomReminderHistoryItem] {
        [
            MomReminderHistoryItem(
                id: UUID(),
                title: "Weekly Weight Tracked",
                completedText: "Completed yesterday at 8:00 PM"
            ),
            MomReminderHistoryItem(
                id: UUID(),
                title: "Prenatal Yoga Class",
                completedText: "Completed on Monday, Oct 24"
            ),
            MomReminderHistoryItem(
                id: UUID(),
                title: "Iron Supplement Taken",
                completedText: "Completed on Sunday, Oct 23"
            )
        ]
    }
}
