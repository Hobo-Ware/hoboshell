import Testing
@testable import HoboshellCore

@Suite struct ShellPaletteTests {
    private let surfaces = ShellPalette.backdrops.map(ShellPalette.flyoutSurface(over:))

    @Test func blackOnWhiteIsTwentyOneToOne() {
        #expect(abs(Contrast.ratio(.black, .white) - 21) < 0.001)
    }

    @Test func aColourAgainstItselfIsOneToOne() {
        #expect(Contrast.ratio(ShellPalette.text, ShellPalette.text) == 1)
    }

    @Test func theTintIsAtLeastNinetyTwoPercent() {
        #expect(ShellPalette.flyoutTintAlpha >= 0.92)
    }

    @Test func bodyTextReadsAtSevenToOneOnTheFlyoutSurfaceOverAnyBackdrop() {
        for surface in surfaces {
            #expect(Contrast.ratio(ShellPalette.text, surface) >= 7)
        }
    }

    @Test func dimTextReadsAtFourPointFiveToOneOnTheFlyoutSurfaceOverAnyBackdrop() {
        for surface in surfaces {
            #expect(Contrast.ratio(ShellPalette.dimText, surface) >= 4.5)
        }
    }

    @Test func disabledTextReadsAtThreeToOneOnTheFlyoutSurfaceOverAnyBackdrop() {
        for surface in surfaces {
            #expect(Contrast.ratio(ShellPalette.disabled(ShellPalette.text, over: surface), surface) >= 3)
        }
    }

    @Test func theAccentReadsAtThreeToOneOnTheFlyoutSurfaceOverAnyBackdrop() {
        for surface in surfaces {
            #expect(Contrast.ratio(ShellPalette.accent, surface) >= 3)
        }
    }

    @Test func aWhitePageBehindTheFlyoutBarelyLightensTheSurface() {
        let overWhite = ShellPalette.flyoutSurface(over: .white)
        let overBlack = ShellPalette.flyoutSurface(over: .black)
        #expect(overWhite.red - overBlack.red < 0.07)
    }

    @Test func lightTextOnTheOnStateFillReadsAtFourPointFiveToOne() {
        for fill in [ShellPalette.accentFill, ShellPalette.accentFillHover, ShellPalette.accentFillPressed] {
            #expect(Contrast.ratio(ShellPalette.onAccent, fill) >= 4.5)
        }
    }
}
