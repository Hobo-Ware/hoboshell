import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct TaskbarAlignmentTests {
    private func originX(
        _ alignment: TaskbarAlignment,
        bar: CGFloat = 1440,
        group: CGFloat,
        trail: CGFloat = 300
    ) -> CGFloat {
        TaskbarPlacement.groupOriginX(
            alignment: alignment, barWidth: bar, groupWidth: group, trailWidth: trail, leadingInset: 8, gap: 8
        )
    }

    @Test func leftAlignmentStartsAtTheInset() {
        #expect(originX(.left, group: 400) == 8)
    }

    @Test func centredGroupSitsInTheMiddleOfTheBar() {
        #expect(originX(.centred, group: 400) == 520)
    }

    @Test func anEmptyBarStillCentresTheStartButtons() {
        #expect(originX(.centred, group: 80) == 680)
    }

    @Test func aGroupThatWouldTouchTheTrayStopsBeforeIt() {
        let x = originX(.centred, group: 1000)
        #expect(x == 132)
        #expect(x + 1000 + 8 + 300 == 1440)
    }

    @Test func aGroupFillingTheBarFallsBackToTheInset() {
        #expect(originX(.centred, group: 1200) == 8)
    }

    @Test func aNarrowerSecondScreenCentresOnItsOwnWidth() {
        #expect(originX(.centred, bar: 1280, group: 400) == 440)
    }

    @Test func aNarrowerSecondScreenStopsBeforeItsTray() {
        let x = originX(.centred, bar: 1024, group: 700)
        #expect(x == 16)
        #expect(x + 700 + 8 + 300 == 1024)
    }

    @Test func nothingStoredMeansCentred() {
        #expect(TaskbarAlignment(stored: nil) == .centred)
    }

    @Test func anUnknownStoredValueMeansCentred() {
        #expect(TaskbarAlignment(stored: "right") == .centred)
    }

    @Test func aStoredLeftComesBack() {
        #expect(TaskbarAlignment(stored: "left") == .left)
    }
}
