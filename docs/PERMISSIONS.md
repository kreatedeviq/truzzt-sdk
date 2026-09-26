# Permissions (Play / App Store) — short

**OTP-less Network Identity** needs phone lines on device. No Camera. No Call Phone. No SMS.

## Android — declare these

| Permission | Why (one line) |
|------------|----------------|
| `INTERNET` | API + verify WebView |
| `ACCESS_NETWORK_STATE` | Connectivity during verify |
| `READ_PHONE_STATE` | SIM / subscription for line match |
| `READ_PHONE_NUMBERS` | MSISDN / SIM1·SIM2 match |
| `READ_CONTACTS` | Fallback: “My number” / “رقمي” if SIM hides MSISDN |

**Do not declare for Truzzt:** `CAMERA`, `CALL_PHONE`, SMS, Location, Mic.

**Play Console (Phone):**  
> Confirms the account phone is on a SIM/line on this device during user-started verify. No calls, no SMS, no ads.

**Play Console (Contacts):**  
> Reads only owner-labelled numbers when SIM APIs return blank. Not an address-book sync.

## iOS — declare this

```xml
<key>NSContactsUsageDescription</key>
<string>Truzzt reads your My Card (Me) and owner contacts (“My number” / “رقمي”) to verify this device owns the account phone. We do not sync your full address book.</string>
```

**App Privacy:** Phone Number → App Functionality · Linked to user · **Not** used for tracking.  
Apple blocks SIM MSISDN — Contacts Me is the supported iOS source.

## In-app prompts (short)

- **Phone:** Confirm SIM matches the number you entered. We never call or text.
- **Contacts:** Use your saved “My number” if the SIM has no line. Not your full contacts.

## Accessibility (optional)

`*#06#` helper only — **not required** for verify. Don’t force it.

Full platform guides: [ANDROID.md](./ANDROID.md) · [IOS.md](./IOS.md)
