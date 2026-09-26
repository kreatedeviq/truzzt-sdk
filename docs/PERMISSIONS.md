# Truzzt — Permission justifications (Play Store / App Store)

Use these **exact reasons** when Google Play, Apple App Store, or a compliance review asks why Truzzt needs a permission. Copy into Play Console declarations, App Privacy questionnaires, and host-app `Info.plist` / privacy policy.

**Required for Network Identity:** phone line + contacts (platform-specific).  
**Not required:** Camera, Call Phone, Microphone, Location, Storage.

---

## Summary (what reviewers need)

| Platform | Permission / capability | Required? | One-line reason |
|----------|-------------------------|-----------|-----------------|
| Android | `INTERNET` | Yes | Call Truzzt APIs and load the in-app verify WebView. |
| Android | `ACCESS_NETWORK_STATE` | Yes | Collect basic connectivity signals during verification. |
| Android | `READ_PHONE_STATE` | Yes | Read SIM / subscription info to match the registered phone on this device. |
| Android | `READ_PHONE_NUMBERS` | Yes (API 26+) | Read the device MSISDN / line number(s) for SIM1/SIM2 match. |
| Android | `READ_CONTACTS` | Yes | Fallback: read owner-labelled contacts (e.g. “My number”, “رقمي”) when SIM APIs do not expose a number. |
| Android | Accessibility (optional) | No | Optional OEM helper to read `*#06#` device-info dialog; **not** required for the default verify flow. |
| Android | `CAMERA` | **No — do not declare** | QR was removed; verify opens via `verifyUrl` inside the SDK. |
| Android | `CALL_PHONE` | **No — do not declare** | Any dial helper uses `ACTION_DIAL` (no call permission). |
| iOS | Contacts (`NSContactsUsageDescription`) | Yes | Read **My Card (Me)** and owner contacts to match the registered phone (Apple does not allow SIM chip read). |
| iOS | Camera / Microphone / Location | **No** | Not used. |

---

## Google Play Console

### Declared permissions text (Phone)

**Permission group:** Phone (`READ_PHONE_STATE`, `READ_PHONE_NUMBERS`)

**Core functionality declaration (recommended wording):**

> Truzzt Network Identity verifies that the mobile number used for login, registration, or password recovery belongs to a SIM / line installed on this physical device. The app reads phone state and phone number(s) only during an explicit user-started verification, matches them against the number the user entered, and does not place calls, send SMS, or use the numbers for advertising.

**Video / screencast tip:** Show Login → Continue & verify → system permission prompt → match success. Emphasize no OTP SMS and no camera.

### Declared permissions text (Contacts)

**Permission:** Contacts (`READ_CONTACTS`)

> On many Android devices the telephony APIs do not return the MSISDN. Truzzt optionally reads contacts the user labelled as their own number (for example “My number” or “رقمي”) solely to complete the same line-match verification. Contacts are not uploaded as an address book sync and are not used for marketing.

### Permissions you should **not** request for Truzzt

- Camera / Photos  
- Call logs / `CALL_PHONE`  
- SMS  
- Precise location  
- Microphone  

If your host app needs those for other features, declare them separately — they are **not** part of Truzzt.

---

## Apple App Store / App Privacy

### `Info.plist` (required)

```xml
<key>NSContactsUsageDescription</key>
<string>Truzzt needs access to Contacts to read your My Card (Me) number and any contact you saved as your own phone (for example “My number” or “رقمي”), so we can verify that this device owns the phone number used for login or registration. We do not sync your full address book.</string>
```

### App Privacy questionnaire (nutrition labels)

| Data type | Collected? | Linked to user? | Tracking? | Purpose |
|-----------|------------|-----------------|-----------|---------|
| Contact Info → Phone Number | Yes (during verify) | Yes (account verification) | No | App Functionality |
| Contacts (other fields) | No (only phone numbers from Me / owner-labelled entries) | — | No | — |
| Device ID / Precise Location / Photos | No | — | No | — |

**Purpose string for reviewers:**

> Phone numbers from Contacts My Card and owner-labelled contacts are used only to confirm Network Identity (match the registered account phone on this device). Data is sent to Truzzt verification servers for that session and is not used for advertising or tracking.

### Why Contacts (not SIM) on iOS

Apple does not expose SIM MSISDN to third-party apps. Truzzt’s iOS SDK therefore uses Contacts **Me** / owner contacts as the supported line source. That is intentional and documented for App Review.

---

## Runtime permission prompts (in-app rationale)

Suggested short copy before the system dialog:

**Android — Phone**

> Allow phone access so Truzzt can confirm the SIM on this device matches the number you entered. We never call or text from this permission.

**Android — Contacts**

> Allow contacts so we can use a number you saved as “My number” if the SIM does not expose a line. We only look for your own number, not your full address book.

**iOS — Contacts**

> Truzzt reads your My Card number to verify this iPhone owns the account phone. Your other contacts are not synced.

---

## Accessibility (Android, optional)

Service label / description (already in the SDK):

> Truzzt reads the Device information dialog (*#06#) to verify your SIM phone number, IMEI, and ICCID in the background during identity verification.

**Play policy note:** Accessibility must not be required for core app use. Truzzt’s main path works with Phone + Contacts only. Do not force users to enable Accessibility to complete verify.

---

## Host SDK checklist

| SDK | What to ship |
|-----|----------------|
| Android module | Merges `INTERNET`, `ACCESS_NETWORK_STATE`, `READ_PHONE_STATE`, `READ_PHONE_NUMBERS`, `READ_CONTACTS` only |
| iOS / SPM | Host adds `NSContactsUsageDescription` (string above) |
| Capacitor / Cordova / RN / Flutter / Expo | Same Android permissions + iOS Contacts usage string — see platform guides |

See also: [ANDROID.md](./ANDROID.md) · [IOS.md](./IOS.md) · [EXPO.md](./EXPO.md)
