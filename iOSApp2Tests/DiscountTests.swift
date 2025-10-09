import XCTest
@testable import iOSApp2

final class DiscountTests: XCTestCase {

    @MainActor
    func testDiscountTiers() {
        let vm = HuntViewModel()

        vm._testSetFoundCount(0)
        XCTAssertEqual(vm.discountSummary().title, "Keep Hunting!")

        vm._testSetFoundCount(5)
        XCTAssertTrue(vm.discountSummary().title.contains("10%"))

        vm._testSetFoundCount(7)
        XCTAssertTrue(vm.discountSummary().title.contains("20%"))

        vm._testSetFoundCount(10)
        XCTAssertTrue(vm.discountSummary().title.contains("Grand"))
    }
}
