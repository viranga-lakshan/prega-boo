import XCTest
@testable import prega_boo

final class PregaBooLogicTests: XCTestCase {

    func testOnboardingHasThreePages() {
        let pages = OnboardingController().loadPages()
        XCTAssertEqual(pages.count, 3)
    }

    func testOnboardingLastPageHasGetStartedButton() {
        let pages = OnboardingController().loadPages()
        XCTAssertEqual(pages.last?.primaryButtonTitle, "Get Started")
        XCTAssertTrue(pages.last?.isCompact ?? false)
    }

    func testDashboardProfileCopyLooksRight() {
        let model = MomDashboardController().loadProfileDisplayModel()
        XCTAssertEqual(model.title, "Mom Profile")
        XCTAssertEqual(model.securitySectionTitle, "App lock")
        XCTAssertEqual(model.signOutTitle, "Sign out")
    }

    func testSupabaseHumanMessageUsesMsgField() {
        let body = #"{"msg":"JWT expired","error":"invalid_token"}"#
        let text = SupabaseAuthService.humanMessage(fromBody: body)
        XCTAssertEqual(text, "JWT expired")
    }

    func testSupabaseHumanMessageFallsBackToErrorDescription() {
        let body = #"{"error_description":"Invalid login credentials"}"#
        let text = SupabaseAuthService.humanMessage(fromBody: body)
        XCTAssertEqual(text, "Invalid login credentials")
    }

    func testWidgetReminderFormatterForInvalidDateReturnsNil() {
        let formatted = WidgetReminderFormatter.format(reminderDateISO: "not-a-date", reminderTime: "10:00 AM")
        XCTAssertNil(formatted)
    }

    func testWidgetReminderFormatterTodayKeepsTime() {
        let today = isoDate(Date())
        let formatted = WidgetReminderFormatter.format(reminderDateISO: today, reminderTime: "10:00 AM")
        XCTAssertEqual(formatted, "Today at 10:00 AM")
    }

    func testWidgetReminderFormatterTomorrowWithoutTime() {
        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let tomorrow = isoDate(tomorrowDate)
        let formatted = WidgetReminderFormatter.format(reminderDateISO: tomorrow, reminderTime: "   ")
        XCTAssertEqual(formatted, "Tomorrow")
    }

    @MainActor
    func testDeepLinkRouterHandlesMomBabyDetails() {
        let router = DeepLinkRouter.shared
        router.shouldOpenMomBabyDetails = false

        let handled = router.handle(URL(string: "cw.prega-boo://widget-nav/mom-baby-details")!)

        XCTAssertTrue(handled)
        XCTAssertTrue(router.shouldOpenMomBabyDetails)
    }

    @MainActor
    func testDeepLinkRouterIgnoresOAuthCallback() {
        let router = DeepLinkRouter.shared
        router.shouldOpenMomBabyDetails = false

        let handled = router.handle(URL(string: "cw.prega-boo://login-callback?code=abc")!)

        XCTAssertFalse(handled)
        XCTAssertFalse(router.shouldOpenMomBabyDetails)
    }

    func testICSExportIncludesCalendarShell() {
        let events = [makeEvent(title: "Clinic Visit", isPast: false, scheduleAt: nil)]
        let ics = EventCalendarICSExportService.makeICS(for: events)

        XCTAssertTrue(ics.contains("BEGIN:VCALENDAR"))
        XCTAssertTrue(ics.contains("END:VCALENDAR"))
        XCTAssertTrue(ics.contains("SUMMARY:Clinic Visit"))
    }

    func testICSExportAddsAlarmForUpcomingTimedEvent() {
        let schedule = Date(timeIntervalSince1970: 1_720_000_000)
        let events = [makeEvent(title: "Growth Check", isPast: false, scheduleAt: schedule, timeText: "10:00 AM")]
        let ics = EventCalendarICSExportService.makeICS(for: events)

        XCTAssertTrue(ics.contains("BEGIN:VALARM"))
        XCTAssertTrue(ics.contains("TRIGGER:-PT1H"))
        XCTAssertTrue(ics.contains("DTSTART:"))
    }

    func testICSExportSkipsAlarmForPastEvent() {
        let events = [makeEvent(title: "Old Vaccine", isPast: true, scheduleAt: nil)]
        let ics = EventCalendarICSExportService.makeICS(for: events)

        XCTAssertFalse(ics.contains("BEGIN:VALARM"))
        XCTAssertTrue(ics.contains("SUMMARY:Old Vaccine"))
    }

    // MARK: - Small local helpers

    private func isoDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }

    private func makeEvent(
        title: String,
        isPast: Bool,
        scheduleAt: Date?,
        timeText: String? = nil
    ) -> MomCalendarEvent {
        MomCalendarEvent(
            id: UUID(),
            dateISO: "2026-05-08",
            title: title,
            timeText: timeText,
            metadata: "From test",
            category: .clinicMom,
            isPast: isPast,
            scheduleAt: scheduleAt
        )
    }
}
