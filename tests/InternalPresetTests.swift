import Foundation

@main struct InternalPresetTests {
    static func main() throws {
        let internalPreset = Capability.all.first { $0.id == "internal" }!
        let expectedKeys: Set = ["Oji6HRoPi7rH7HPdWVakuw", "LBJfwOEzExRxzlAnSuI7eg", "EqrsVvjcYDdxHBiQmGhAWw"]
        precondition(Set(internalPreset.keys) == expectedKeys)
        precondition(Capability.all.allSatisfy { $0.id == "internal" || expectedKeys.isDisjoint(with: $0.keys) })
        for initiallyEnabled in [false, true] {
            var extra: [String: Any] = ["unrelated": "preserved"]
            if initiallyEnabled { for key in expectedKeys { extra[key] = NSNumber(value: 1) } }
            let fixture: [String: Any] = ["CacheExtra": extra, "CacheData": Data([1, 2])]
            let data = try PropertyListSerialization.data(fromPropertyList: fixture, format: .binary, options: 0)
            let original = try GestaltDocument(data: data)
            let snapshot = DocumentSnapshot(data: data, document: original, source: .local, name: "fixture")
            for choice in PresetChoice.allCases {
                var document = original
                internalPreset.apply(choice, to: &document, restoringFrom: snapshot)
                let readback = try GestaltDocument(data: document.encoded())
                for key in expectedKeys {
                    switch choice {
                    case .keep, .disable:
                        precondition(readback.extra[key] as? NSNumber == extra[key] as? NSNumber)
                    case .enable:
                        precondition(PlistValueKind.detect(readback.extra[key]!) == .integer)
                        precondition(readback.extra[key] as? NSNumber == NSNumber(value: 1))
                    case .removeAdded:
                        precondition(readback.extra[key] == nil)
                    }
                }
                precondition(readback.extra["unrelated"] as? String == "preserved")
                precondition(readback.root["CacheData"] as? Data == Data([1, 2]))
            }
        }
        print("PASS: internal preset sets all three keys to 1 when enabled, restores original values when disabled, and removes them on request; unrelated data verified.")
    }
}
