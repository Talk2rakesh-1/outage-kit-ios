import SwiftUI

@main
struct OutageKitApp: App {
  var body: some Scene {
    WindowGroup { KitView() }
  }
}

@MainActor
final class KitModel: ObservableObject {
  @Published private(set) var supplies: [Supply] = []
  @Published var error: String?
  @Published private(set) var loadFailed = false
  private let store: KitStore

  init() {
    let directory = URL.applicationSupportDirectory.appending(path: "OutageKit")
    store = KitStore(url: directory.appending(path: "supplies.json"))
    reload()
  }

  func reload() {
    do {
      supplies = try store.load()
      loadFailed = false
      error = nil
    } catch {
      loadFailed = true
      self.error = "Unable to load your kit: \(error.localizedDescription)"
    }
  }

  @discardableResult
  func commit(_ next: [Supply]) -> Bool {
    guard !loadFailed else { return false }
    do {
      try store.save(next)
      supplies = next
      return true
    } catch {
      self.error = "Changes were not saved: \(error.localizedDescription)"
      return false
    }
  }
}

struct KitView: View {
  @StateObject private var model = KitModel()
  @State private var editing: Supply?
  @State private var adding = false
  @State private var deletion: Supply?
  @State private var search = ""

  var body: some View {
    NavigationStack {
      TimelineView(.periodic(from: .now, by: 60)) { context in
        List {
          Section {
            let ready = model.supplies.filter { $0.isReady(on: context.date) }.count
            Text("\(ready) of \(model.supplies.count) items stocked and in date")
              .font(.headline)
            Text(
              "Track your own quantities. This checklist does not certify emergency preparedness."
            )
            .font(.footnote).foregroundStyle(.secondary)
          }
          if model.loadFailed {
            Section("Kit unavailable") {
              Text(
                "Your saved file is preserved. Retry after unlocking your device or restoring a valid backup."
              )
              Button("Retry loading") { model.reload() }
            }
          } else if model.supplies.isEmpty {
            ContentUnavailableView(
              "Build your kit", systemImage: "shippingbox",
              description: Text(
                "Add supplies such as a flashlight, batteries, or a power bank. Choose quantities that fit your household."
              ))
          }
          Section("Supplies") {
            ForEach(
              model.supplies.filter {
                search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
              }
            ) { supply in
              Button {
                editing = supply
              } label: {
                HStack(alignment: .top) {
                  Image(
                    systemName: supply.isReady(on: context.date)
                      ? "checkmark.circle.fill" : "circle"
                  )
                  .foregroundStyle(supply.isReady(on: context.date) ? .green : .secondary)
                  .accessibilityHidden(true)
                  VStack(alignment: .leading, spacing: 4) {
                    Text(supply.name).font(.headline)
                    Text("\(supply.quantity) / \(supply.target) stocked").font(.subheadline)
                    if let expiry = supply.expiry {
                      Text("Expiry: \(expiry.formatted(date: .abbreviated, time: .omitted))").font(
                        .caption)
                    }
                    Text(
                      supply.isExpired(on: context.date)
                        ? "Expired — review item"
                        : (supply.isReady(on: context.date) ? "Stocked" : "Needs more")
                    )
                    .font(.caption).bold()
                  }
                }
              }
              .tint(.primary)
              .swipeActions { Button("Delete", role: .destructive) { deletion = supply } }
            }
          }
          Section {
            Link(
              "Official preparedness resources",
              destination: URL(string: "https://www.ready.gov/power-outages")!)
            Text(
              "All kit data stays in this app’s storage. Opening the resource link uses your browser."
            )
            .font(.caption).foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle("OutageKit")
      .searchable(text: $search, prompt: "Find a supply")
      .toolbar {
        Button("Add", systemImage: "plus") { adding = true }.disabled(model.loadFailed)
      }
      .sheet(isPresented: $adding) {
        SupplyEditor(supply: nil) { supply in model.commit(model.supplies + [supply]) }
      }
      .sheet(item: $editing) { supply in
        SupplyEditor(supply: supply) { updated in
          model.commit(model.supplies.map { $0.id == updated.id ? updated : $0 })
        }
      }
      .confirmationDialog(
        "Delete this supply?",
        isPresented: Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } }),
        titleVisibility: .visible
      ) {
        Button("Delete", role: .destructive) {
          if let deletion { model.commit(model.supplies.filter { $0.id != deletion.id }) }
          deletion = nil
        }
      }
      .alert(
        "Storage error",
        isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })
      ) {
        Button("OK") { model.error = nil }
      } message: {
        Text(model.error ?? "")
      }
    }
  }
}

struct SupplyEditor: View {
  @Environment(\.dismiss) private var dismiss
  let supply: Supply?
  let save: (Supply) -> Bool
  @State private var name = ""
  @State private var quantity = 0
  @State private var target = 1
  @State private var hasExpiry = false
  @State private var expiry = Date.now
  @State private var error: String?

  var body: some View {
    NavigationStack {
      Form {
        TextField("Supply name", text: $name)
        Stepper("Stocked: \(quantity)", value: $quantity, in: 0...999)
        Stepper("Target: \(target)", value: $target, in: 1...999)
        Toggle("Track expiry", isOn: $hasExpiry)
        if hasExpiry { DatePicker("Expiry date", selection: $expiry, displayedComponents: .date) }
        if let error { Text(error).foregroundStyle(.red) }
      }
      .navigationTitle(supply == nil ? "Add supply" : "Edit supply")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            do {
              let next = try Supply(
                id: supply?.id ?? UUID(), name: name, quantity: quantity, target: target,
                expiry: hasExpiry ? expiry : nil)
              if save(next) {
                dismiss()
              } else {
                error = "Could not save. Your changes remain here; please retry."
              }
            } catch { self.error = error.localizedDescription }
          }
        }
      }
      .onAppear {
        if let supply {
          name = supply.name
          quantity = supply.quantity
          target = supply.target
          hasExpiry = supply.expiry != nil
          expiry = supply.expiry ?? .now
        }
      }
    }
  }
}
