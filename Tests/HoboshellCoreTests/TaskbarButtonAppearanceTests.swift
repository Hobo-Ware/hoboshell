import Testing
@testable import HoboshellCore

@Suite struct TaskbarButtonAppearanceTests {
    private func pick(_ facts: TaskbarButtonFacts) -> TaskbarButtonAppearance {
        TaskbarButtonAppearance.pick(facts)
    }

    @Test func aPinnedClosedAppHasNoPlateAndNoLine() {
        #expect(pick(TaskbarButtonFacts()) == TaskbarButtonAppearance(
            plate: .none, line: .none, hasStackedEdge: false, showsUnread: false, dipsIcon: false
        ))
    }

    @Test func aRunningAppShowsTheShortLine() {
        #expect(pick(TaskbarButtonFacts(isRunning: true)) == TaskbarButtonAppearance(
            plate: .none, line: .short, hasStackedEdge: false, showsUnread: false, dipsIcon: false
        ))
    }

    @Test func hoverLightsThePlate() {
        #expect(pick(TaskbarButtonFacts(isRunning: true, isHovered: true)).plate == .hover)
    }

    @Test func pressDimsThePlateAndDipsTheIcon() {
        let appearance = pick(TaskbarButtonFacts(isRunning: true, isPressed: true))
        #expect(appearance.plate == .pressed)
        #expect(appearance.dipsIcon)
    }

    @Test func aFocusedWindowLightsThePlateAndWidensTheLine() {
        let appearance = pick(TaskbarButtonFacts(isRunning: true, isFocused: true))
        #expect(appearance.plate == .focused)
        #expect(appearance.line == .wide)
    }

    @Test func severalWindowsShowTheStackedEdge() {
        #expect(pick(TaskbarButtonFacts(isRunning: true, windowCount: 3)).hasStackedEdge)
    }

    @Test func oneWindowHasNoStackedEdge() {
        #expect(!pick(TaskbarButtonFacts(isRunning: true, windowCount: 1)).hasStackedEdge)
    }

    @Test func anUnreadCountShowsTheUnreadDot() {
        #expect(pick(TaskbarButtonFacts(isRunning: true, badge: "4")).showsUnread)
    }

    @Test func anEmptyBadgeShowsNoUnreadDot() {
        #expect(!pick(TaskbarButtonFacts(isRunning: true, badge: "")).showsUnread)
    }

    @Test func pressBeatsHoverAndFocus() {
        let facts = TaskbarButtonFacts(isRunning: true, isFocused: true, isHovered: true, isPressed: true)
        #expect(pick(facts).plate == .pressed)
    }

    @Test func hoverOnAFocusedButtonStaysLitBrighter() {
        #expect(pick(TaskbarButtonFacts(isRunning: true, isFocused: true, isHovered: true)).plate == .focusedHover)
    }

    @Test func aWindowlessBackgroundAppKeepsTheDotEvenWhenFocused() {
        #expect(pick(TaskbarButtonFacts(isRunning: true, isFocused: true, isBackground: true)).line == .dot)
    }

    @Test func aClosedAppIgnoresFocusAndUnreadForTheLine() {
        let appearance = pick(TaskbarButtonFacts(isFocused: true, badge: "9"))
        #expect(appearance.line == .none)
        #expect(!appearance.showsUnread)
    }
}
