import Testing
@testable import HoboshellCore

@Suite struct BatteryIconTests {
    private func icon(_ percent: Int, charging: Bool = false, lowPower: Bool = false) -> BatteryIcon {
        BatteryIcon(status: BatteryStatus(percent: percent, isCharging: charging), isLowPowerMode: lowPower)
    }

    @Test func chargingIsGreenWithTheBoltSymbol() {
        #expect(icon(40, charging: true).tone == .good)
        #expect(icon(40, charging: true).symbolName == "battery.100.bolt")
    }

    @Test func lowPowerModeIsAmber() {
        #expect(icon(60, lowPower: true).tone == .warning)
    }

    @Test(arguments: [(0, TrayTone.critical), (5, .critical), (6, .normal), (7, .normal), (100, .normal)])
    func underSixPercentIsRedOnBattery(percent: Int, tone: TrayTone) {
        #expect(icon(percent).tone == tone)
    }

    @Test func redWinsOverLowPowerWhenNotCharging() {
        #expect(icon(5, lowPower: true).tone == .critical)
        #expect(icon(6, lowPower: true).tone == .warning)
    }

    @Test func chargingStaysGreenEvenWhenNearlyEmptyOrInLowPower() {
        #expect(icon(2, charging: true).tone == .good)
        #expect(icon(50, charging: true, lowPower: true).tone == .good)
    }

    @Test func aPlainBatteryIsUntinted() {
        #expect(icon(80).tone == .normal)
    }

    @Test(arguments: [(0, "battery.0"), (12, "battery.0"), (13, "battery.25"), (37, "battery.25"), (38, "battery.50"), (62, "battery.50"), (63, "battery.75"), (87, "battery.75"), (88, "battery.100"), (100, "battery.100")])
    func levelStepsChangeAtEachCutOff(percent: Int, symbol: String) {
        #expect(icon(percent).symbolName == symbol)
    }

    @Test func outOfRangePercentsAreClampedBeforeTheyPickAState() {
        #expect(icon(-5).tone == .critical)
        #expect(icon(140).symbolName == "battery.100")
    }
}
