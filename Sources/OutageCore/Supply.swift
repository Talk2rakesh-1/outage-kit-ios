import Foundation

public enum KitError: Error, LocalizedError {
  case invalidSupply, unsupportedVersion
  public var errorDescription: String? {
    switch self {
    case .invalidSupply:
      "Use a name of 1–80 characters and quantities between 0 and 999 (target at least 1)."
    case .unsupportedVersion:
      "This kit was saved by an unsupported version. Your file has not been changed."
    }
  }
}

public struct Supply: Codable, Identifiable, Equatable, Sendable {
  public let id: UUID
  public var name: String
  public var quantity: Int
  public var target: Int
  public var expiry: Date?

  public init(id: UUID = UUID(), name: String, quantity: Int, target: Int, expiry: Date? = nil)
    throws
  {
    self.id = id
    self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    self.quantity = quantity
    self.target = target
    self.expiry = expiry
    try validate()
  }

  public func validate() throws {
    guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      name.count <= 80, (0...999).contains(quantity), (1...999).contains(target),
      expiry?.timeIntervalSince1970.isFinite ?? true
    else { throw KitError.invalidSupply }
  }

  public func isExpired(on date: Date, calendar: Calendar = .current) -> Bool {
    guard let expiry else { return false }
    return calendar.startOfDay(for: expiry) < calendar.startOfDay(for: date)
  }

  public func isReady(on date: Date, calendar: Calendar = .current) -> Bool {
    quantity >= target && !isExpired(on: date, calendar: calendar)
  }
}

public struct KitStore: Sendable {
  public let url: URL
  public init(url: URL) { self.url = url }
  private struct Envelope: Codable {
    var version: Int
    var supplies: [Supply]
  }

  public func load() throws -> [Supply] {
    guard FileManager.default.fileExists(atPath: url.path) else { return [] }
    let data = try Data(contentsOf: url)
    let envelope = try JSONDecoder().decode(Envelope.self, from: data)
    guard envelope.version == 1 else { throw KitError.unsupportedVersion }
    try validate(envelope.supplies)
    return envelope.supplies
  }

  public func save(_ supplies: [Supply]) throws {
    try validate(supplies)
    let data = try JSONEncoder().encode(Envelope(version: 1, supplies: supplies))
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    #if os(iOS)
      try data.write(to: url, options: [.atomic, .completeFileProtection])
    #else
      try data.write(to: url, options: .atomic)
    #endif
  }

  private func validate(_ supplies: [Supply]) throws {
    guard supplies.count <= 500, Set(supplies.map(\.id)).count == supplies.count else {
      throw KitError.invalidSupply
    }
    for supply in supplies { try supply.validate() }
  }
}
