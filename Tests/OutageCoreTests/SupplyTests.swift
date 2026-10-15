import Foundation
import XCTest

@testable import OutageCore

final class SupplyTests: XCTestCase {
  func test_quantitiesAndWhitespace() throws {
    let supply = try Supply(name: " Batteries ", quantity: 3, target: 4)
    XCTAssertTrue(supply.name == "Batteries")
    XCTAssertTrue(!supply.isReady(on: .now))
    XCTAssertThrowsError(try Supply(name: " ", quantity: 0, target: 1))
    XCTAssertThrowsError(try Supply(name: "A", quantity: -1, target: 1))
    XCTAssertThrowsError(try Supply(name: "A", quantity: 1, target: 0))
    XCTAssertThrowsError(
      try Supply(name: String(repeating: "a", count: 81), quantity: 1, target: 1)
    )
  }

  func test_expiryIncludesWholeDay() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let start = Date(timeIntervalSince1970: 1_728_950_400)
    let supply = try Supply(name: "Battery", quantity: 1, target: 1, expiry: start)
    XCTAssertTrue(supply.isReady(on: start.addingTimeInterval(86399), calendar: calendar))
    XCTAssertTrue(supply.isExpired(on: start.addingTimeInterval(86400), calendar: calendar))
  }

  func test_noExpiryAndExcessStock() throws {
    let supply = try Supply(name: "Light", quantity: 4, target: 1)
    XCTAssertTrue(supply.isReady(on: .distantFuture))
  }

  func test_persistenceRoundTrip() throws {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = KitStore(url: folder.appending(path: "kit.json"))
    XCTAssertTrue(try store.load().isEmpty)
    let items = [try Supply(name: "Light", quantity: 1, target: 2)]
    try store.save(items)
    XCTAssertTrue(try store.load() == items)
    try store.save([])
    XCTAssertTrue(try store.load().isEmpty)
  }

  func test_corruptFilePreserved() throws {
    let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: file) }
    let data = Data("broken".utf8)
    try data.write(to: file)
    XCTAssertThrowsError(try KitStore(url: file).load())
    XCTAssertTrue(try Data(contentsOf: file) == data)
  }

  func test_unsupportedVersion() throws {
    let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: file) }
    try Data("{\"version\":2,\"supplies\":[]}".utf8).write(to: file)
    XCTAssertThrowsError(try KitStore(url: file).load())
  }

  func test_invalidMutationAndDuplicateIDsRejected() throws {
    let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let store = KitStore(url: file)
    var item = try Supply(name: "Light", quantity: 1, target: 2)
    XCTAssertThrowsError(try store.save([item, item]))
    item.quantity = -1
    XCTAssertThrowsError(try store.save([item]))
    XCTAssertTrue(!FileManager.default.fileExists(atPath: file.path))
  }

  func test_failedSaveThrows() throws {
    let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: file) }
    try Data().write(to: file)
    XCTAssertThrowsError(try KitStore(url: file.appending(path: "kit.json")).save([]))
  }

}
