import Testing
@testable import Daytrack

@Suite struct GlassStyleTests {
    @Test func defaultUsesGlass() {
        #expect(GlassStyle.resolve(reduceTransparency: false, increaseContrast: false) == .glass)
    }

    @Test func reduceTransparencyUsesSolidWarm() {
        #expect(GlassStyle.resolve(reduceTransparency: true, increaseContrast: false) == .solidWarm)
    }

    @Test func increaseContrastAddsBorder() {
        #expect(GlassStyle.resolve(reduceTransparency: false, increaseContrast: true) == .solidWarmBordered)
        #expect(GlassStyle.resolve(reduceTransparency: true, increaseContrast: true) == .solidWarmBordered)
    }
}
