import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct StartMenuPlacementTests {
    private func originX(_ alignment: TaskbarAlignment, bar: CGRect = CGRect(x: 0, y: 0, width: 1440, height: 48), menu: CGFloat = 640) -> CGFloat {
        StartMenuPlacement.originX(alignment: alignment, bar: bar, menuWidth: menu, inset: 8)
    }

    @Test func leftAlignedMenuOpensAtTheInset() {
        #expect(originX(.left) == 8)
    }

    @Test func centredMenuOpensInTheMiddleOfTheBar() {
        #expect(originX(.centred) == 400)
    }

    @Test func centredMenuOnASecondScreenCentresOnThatScreen() {
        #expect(originX(.centred, bar: CGRect(x: 1440, y: 0, width: 1280, height: 48)) == 1760)
    }

    @Test func menuWiderThanTheBarStaysAtTheInset() {
        #expect(originX(.centred, bar: CGRect(x: 0, y: 0, width: 600, height: 48)) == 8)
    }

    @Test func oddWidthsLandOnWholePoints() {
        #expect(originX(.centred, bar: CGRect(x: 0, y: 0, width: 1441, height: 48)) == 401)
    }
}
