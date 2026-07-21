import Foundation
import Contacts

/// Collects phone line numbers available on iOS without SIM-chip APIs.
/// Primary source: Contacts "My Card" (Me) — where users often store their own lines.
enum DeviceLineReader {
    static func requestAccess(completion: @escaping (Bool) -> Void) {
        CNContactStore().requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func readLines() -> [[String: Any]] {
        let store = CNContactStore()
        var out: [[String: Any]] = []
        var seen = Set<String>()

        func push(slot: String, phone: String, source: String) {
            let digits = phone.filter { $0.isNumber }
            guard digits.count >= 8, !seen.contains(digits) else { return }
            seen.insert(digits)
            out.append([
                "slot": slot,
                "phone": digits,
                "msisdn": digits,
                "number": digits,
                "source": source
            ])
        }

        let keys: [CNKeyDescriptor] = [
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor
        ]

        // 1) Contacts → My Card (Me) — user's own number(s) on this device
        if let meId = store.unifiedMeContactIdentifier,
           let me = try? store.unifiedContact(withIdentifier: meId, keysToFetch: keys) {
            for (i, labeled) in me.phoneNumbers.enumerated() {
                let slot = i == 0 ? "line1" : (i == 1 ? "line2" : "line\(i + 1)")
                push(slot: slot, phone: labeled.value.stringValue, source: "contacts_me")
            }
        }

        // 2) Fallback: labeled "iPhone" / mobile on Me-like entries (same meId only — no broad contact scrape)
        // Already covered by Me card above.

        return out
    }

    static func readLinesAsync(completion: @escaping ([[String: Any]]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let lines = readLines()
            DispatchQueue.main.async { completion(lines) }
        }
    }
}
