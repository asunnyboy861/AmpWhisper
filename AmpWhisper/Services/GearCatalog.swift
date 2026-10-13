import Foundation

enum ResourceStore {
    static func loadRecipes() -> [ToneRecipe] {
        guard let url = Bundle.main.url(forResource: "Recipes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let envelope = try? JSONDecoder().decode(RecipeEnvelope.self, from: data) else {
            return []
        }
        return envelope.recipes
    }

    static func loadDevices() -> [GearItem] {
        guard let url = Bundle.main.url(forResource: "DeviceLibrary", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let library = try? JSONDecoder().decode(DeviceLibrary.self, from: data) else {
            return []
        }
        return library.devices
    }
}

struct GearCatalog {
    static let shared = GearCatalog()
    let devices: [GearItem]
    private let brandIndex: [String: [GearItem]]

    init(devices: [GearItem] = ResourceStore.loadDevices()) {
        self.devices = devices
        var index: [String: [GearItem]] = [:]
        for device in devices {
            index[device.brand.lowercased(), default: []].append(device)
        }
        self.brandIndex = index
    }

    func brands(for kind: GearKind) -> [String] {
        var seen = Set<String>()
        return devices.filter { $0.kind == kind }.compactMap { item -> String? in
            guard !seen.contains(item.brand) else { return nil }
            seen.insert(item.brand)
            return item.brand
        }.sorted()
    }

    func models(brand: String, kind: GearKind) -> [GearItem] {
        devices.filter { $0.kind == kind && $0.brand == brand }
    }

    func search(query: String) -> [GearItem] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return devices.filter {
            $0.model.lowercased().contains(q) || $0.brand.lowercased().contains(q)
        }.prefix(30).map { $0 }
    }

    func fuzzyMatch(tokens: [String]) -> [GearItem] {
        let joined = tokens.joined(separator: " ").lowercased()
        guard !joined.isEmpty else { return [] }
        var scored: [(GearItem, Int)] = []
        for device in devices {
            let name = "\(device.brand) \(device.model)".lowercased()
            var score = 0
            for token in tokens where name.contains(token.lowercased()) {
                score += 1
            }
            if name.contains(joined) { score += 3 }
            if score > 0 { scored.append((device, score)) }
        }
        return scored.sorted { $0.1 > $1.1 }.prefix(3).map(\.0)
    }
}
