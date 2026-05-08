# Prega Boo

Smart maternal and child health companion for Sri Lanka.

Prega Boo is an iOS app that helps mothers, babies, and midwives manage health details in one place.  
It includes pregnancy/baby tracking, reminders, notes, secure app lock, map support, calendar export, and widget quick access.

## Project Info

- **Module**: iOS Development (BSc Hons in Computing)
- **App Type**: Native iOS (Swift / SwiftUI)
- **Targets**:
  - `prega-boo` (main app)
  - `PregaBooWidgetExtension` (home screen widget)

## Key Features

- Email/password login and Google OAuth login
- Mom dashboard with quick navigation cards
- Mom & baby details, growth tracking, vaccine tracking
- Midwife-side record viewing and note updates
- Reminder/event grid flow
- Profile editing with photo upload
- PIN + Face ID / Touch ID app lock
- Accessibility settings:
  - Screen reader mode
  - Sound effects
  - Dynamic text support
- WidgetKit summary + deep-link into app
- MapKit care-finder support
- Event/calendar export support

## Tech Stack

- **Language**: Swift
- **UI**: SwiftUI
- **IDE**: Xcode
- **Backend**: Supabase (Auth + PostgREST + Storage)
- **Device Security**: Keychain + LocalAuthentication
- **Apple Frameworks**: WidgetKit, MapKit, UserNotifications, EventKit, AVFoundation
- **Version Control**: Git / GitHub

## Project Structure (Simplified)

```text
prega-boo/
├── prega-boo/                # Main app source
│   ├── View/
│   ├── Model/
│   ├── Controller/
│   └── Service/
├── PregaBooWidget/           # Widget extension source
├── supabase/migrations/      # SQL migrations
└── prega-boo.xcodeproj
```

## Run Locally (Xcode)

1. Open `prega-boo.xcodeproj` in Xcode.
2. Select scheme **`prega-boo`**.
3. Choose simulator or a physical iPhone.
4. Configure signing:
   - `Signing & Capabilities`
   - Select your Apple Team for **both**:
     - `prega-boo`
     - `PregaBooWidgetExtension`
5. Build and run.

## Supabase Configuration

Set your Supabase values in the app secrets/config file used by the project (URL + anon key).  
Make sure your Supabase project has required tables/policies/migrations applied from:

- `supabase/migrations/`

If roles are used (mom/midwife/admin), ensure `user_roles` is populated correctly.

## Testing

Unit tests were added in:

- `prega-booTests/PregaBooLogicTests.swift`

To run tests:

1. Add/create a Unit Test target if not already present in your local Xcode project.
2. Run **Product -> Test**.

## Accessibility Notes

Accessibility settings are available in the Profile tab and are persisted on device:

- Screen reader announcements/speech feedback
- Sound effects on key interactions
- Dynamic text behavior

For full screen-reader testing on iPhone, also enable:

- **Settings -> Accessibility -> VoiceOver**

## Known Non-Blocking Warnings

You may see deprecation warnings for older `NavigationLink(destination:isActive:)` usage.  
These do not block current builds but can be refactored later to modern `NavigationStack` destination APIs.

## Author

P.K. Viranga Lakshan  
Coventry Index: 16116029  
NIBM Index: COBSCCOMP24.2P-068

