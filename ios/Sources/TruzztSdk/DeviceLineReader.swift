import Foundation
import Contacts

/// Collects phone line numbers on iOS from all user-visible sources that map to Settings paths:
/// - Contacts My Card (Me) → Settings → Phone → My Number / Settings → Cellular → SIMs
/// - Saved owner contacts (e.g. "رقمي", "my number")
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
        "my line 2",
        "sim 1",
        "sim 2",
        "sim1",
        "sim2",
        "primary line",
        "secondary line",
        "رقم اسيا",
        "رقم زين",
        "رقم كورك",
        "mobile",
        "cellular"
    ]

    /// Labels on Me-card numbers that mirror Settings → Phone → My Number.
    private static let meCardLabelHints = [
        "mobile", "iphone", "main", "primary", "home", "work", "apple", "cell", "line"
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

        func push(slot: String, phone: String, source: String, label: String? = nil, phoneLabel: String? = nil) {
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
            if let phoneLabel = phoneLabel, !phoneLabel.isEmpty { row["phoneLabel"] = phoneLabel }
            out.append(row)
        }

        let phoneKeys: [CNKeyDescriptor] = [
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor
        ]

        // Settings → Phone → My Number / Settings → Cellular → SIMs (via Contacts Me card)
        if let meId = store.unifiedMeContactIdentifier,
           let me = try? store.unifiedContact(withIdentifier: meId, keysToFetch: phoneKeys) {
            for (i, labeled) in me.phoneNumbers.enumerated() {
                let label = CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: labeled.label ?? "")
                let slot = i == 0 ? "line1" : (i == 1 ? "line2" : "line\(i + 1)")
                let source = meCardSource(for: label, index: i)
                push(slot: slot, phone: labeled.value.stringValue, source: source, phoneLabel: label)
            }
        }

        // Saved contacts the user labeled as their own line
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
                    let phoneLabel = CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: phone.label ?? "")
                    push(
                        slot: "saved_\(savedIndex)",
                        phone: phone.value.stringValue,
                        source: "contacts_saved:\(pattern)",
                        label: label,
                        phoneLabel: phoneLabel
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

    /// Background check: does expected phone match any collected line?
    static func authenticate(expectedPhone: String, lines: [[String: Any]]? = nil) -> [String: Any] {
        let expected = expectedPhone.filter { $0.isNumber }
        let list = lines ?? readLines()
        var matches: [[String: Any]] = []
        var sources: [String] = []

        guard expected.count >= 8 else {
            return ["authenticated": false, "code": "INVALID_EXPECTED", "matches": matches, "sources": sources]
        }

        for line in list {
            let candidate = String(describing: line["phone"] ?? line["msisdn"] ?? line["number"] ?? "")
                .filter { $0.isNumber }
            guard candidate.count >= 8, phonesMatch(expected, candidate) else { continue }
            var hit = line
            hit["phone"] = candidate
            matches.append(hit)
            if let src = line["source"] as? String, !src.isEmpty, !sources.contains(src) {
                sources.append(src)
            }
        }

        return [
            "authenticated": !matches.isEmpty,
            "code": matches.isEmpty ? "MISMATCH" : "MATCH",
            "expected": expected,
            "matches": matches,
            "sources": sources,
            "lineCount": list.count
        ]
    }

    private static func meCardSource(for label: String, index: Int) -> String {
        let lower = label.lowercased()
        if meCardLabelHints.contains(where: { lower.contains($0) }) {
            return "settings_phone_my_number"
        }
        if index == 0 { return "settings_cellular_sim1" }
        if index == 1 { return "settings_cellular_sim2" }
        return "contacts_me"
    }

    private static func phonesMatch(_ expected: String, _ reported: String) -> Bool {
        let a = expected.filter { $0.isNumber }
        let b = reported.filter { $0.isNumber }
        guard !a.isEmpty, !b.isEmpty else { return false }
        if a == b { return true }
        let short = a.count <= b.count ? a : b
        let long = a.count <= b.count ? b : a
        return short.count >= 8 && long.hasSuffix(short)
    }

    private static func matchesOwnerLabel(_ name: String) -> String? {
        let lower = name.lowercased()
        for pattern in ownerNamePatterns where lower.contains(pattern.lowercased()) {
            return pattern
        }
        return nil
    }
}
