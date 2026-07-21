import Foundation
import Contacts

/// Collects phone line numbers available on iOS without SIM-chip APIs.
/// Sources: Contacts My Card (Me) + saved contacts named like "رقمي" / "my number".
enum DeviceLineReader {
    private static let ownerNamePatterns = [
        "رقمي",
        "my number",
        "my line",
        "my phone",
        "own number",
        "my mobile",
        "my sim",
        "self number",
        "رقم الهاتف",
        "my asia",
        "my line 1",
        "my line 2"
    ]

    static func requestAccess(completion: @escaping (Bool) -> Void) {
        CNContactStore().requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func readLines() -> [[String: Any]] {
        let store = CNContactStore()
        var out: [[String: Any]] = []
        var seen = Set<String>()
        var savedIndex = 0

        func push(slot: String, phone: String, source: String, label: String? = nil) {
            let digits = phone.filter { $0.isNumber }
            guard digits.count >= 8, !seen.contains(digits) else { return }
            seen.insert(digits)
            var row: [String: Any] = [
                "slot": slot,
                "phone": digits,
                "msisdn": digits,
                "number": digits,
                "source": source
            ]
            if let label = label, !label.isEmpty { row["contactName"] = label }
            out.append(row)
        }

        let phoneKeys: [CNKeyDescriptor] = [
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor
        ]

        // 1) Contacts → My Card (Me) — iOS profile card with user's own number(s)
        if let meId = store.unifiedMeContactIdentifier,
           let me = try? store.unifiedContact(withIdentifier: meId, keysToFetch: phoneKeys) {
            for (i, labeled) in me.phoneNumbers.enumerated() {
                let slot = i == 0 ? "line1" : (i == 1 ? "line2" : "line\(i + 1)")
                push(slot: slot, phone: labeled.value.stringValue, source: "contacts_me")
            }
        }

        // 2) Saved contacts the user labeled as their own line (e.g. "رقمي اسيا")
        let nameKeys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactNicknameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]
        let request = CNContactFetchRequest(keysToFetch: nameKeys)
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let label = [
                    contact.givenName,
                    contact.familyName,
                    contact.nickname,
                    contact.organizationName
                ].joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                guard let pattern = matchesOwnerLabel(label) else { return }
                for phone in contact.phoneNumbers {
                    savedIndex += 1
                    push(
                        slot: "saved_\(savedIndex)",
                        phone: phone.value.stringValue,
                        source: "contacts_saved:\(pattern)",
                        label: label
                    )
                }
            }
        } catch {
            // Permission denied or fetch error — return whatever Me card produced.
        }

        return out
    }

    static func readLinesAsync(completion: @escaping ([[String: Any]]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let lines = readLines()
            DispatchQueue.main.async { completion(lines) }
        }
    }

    private static func matchesOwnerLabel(_ name: String) -> String? {
        let lower = name.lowercased()
        for pattern in ownerNamePatterns where lower.contains(pattern.lowercased()) {
            return pattern
        }
        return nil
    }
}
