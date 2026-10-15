# Jeevandhara Project Improvement Plan

Read-only audit completed on 2026-09-09. This document is the master roadmap and live status tracker for future work. Statuses are updated only when implementation and validation are verified.

## Audit Scope and Verification Notes

Inspected:

- All `lib/**/*.dart` files
- `pubspec.yaml`, `analysis_options.yaml`, project metadata, and README
- Android Gradle files, manifests, Kotlin activity, and Firebase configuration
- iOS, macOS, Windows, Linux, and Web platform files
- Declared assets and asset catalogs
- Existing tests and current Git worktree state

Validation performed:

- `flutter analyze --no-pub`: 0 errors, 21 warnings, 94 informational issues.
- `flutter test test/widget_test.dart --no-pub`: failed because the old counter smoke test still expects `0` and `1`, which no longer exist in the app.

Items marked **Needs Verification** require Firebase Console access, real-device testing, product decisions, or files/configuration not present in the repository.

## Completed Implementation Milestones

- Crop recommendation data was integrated from `Crop_recommendation.csv`.
- A six-feature model was selected using N, P, K, temperature, humidity, and pH.
- Rainfall was intentionally excluded because the dataset's rainfall semantics were insufficiently documented for the app's intended use.
- An ExtraTrees model was selected and exported to ONNX.
- The compatible ONNX model was validated against the Joblib model.
- `CropMlService` was integrated into `AdviceScreen`.
- ML top-3 predictions are displayed in the existing recommendation UI.
- Gemini is used only to explain the primary ML-selected crop.
- Physical Android testing confirmed the ML prediction flow works.
- Physical Android testing confirmed the hybrid ML plus Gemini explanation flow works.

## Current Security Limitation

Gemini, OpenWeather, and Data.gov.in keys are currently handled through `.env` for development. This is not equivalent to secure production secret storage in a released Flutter APK because bundled client configuration can be extracted. Backend/proxy work remains required for production. T01 and T02 therefore remain incomplete.

## Current Progress Snapshot

### Completed

T04, T07, T08, T11, T12, T13, T14, T15, T17, T18, T19, T20, T21, T22, T28, and T33.

### Partial

T06, T09, T16, T23, T24, T25, T26, T27, T29, T30, T31, T32, T34, T35, T36, T37, T39, T40, T41, and T45.

### Remaining TODO

All other T01-T46 tasks remain TODO, blocked, or require manual action as noted in the master task list.

# 1. Application Overview

## Current purpose

Jeevandhara is a Flutter farming-advisor prototype intended to help farmers with crop guidance, soil input, weather information, crop-image scanning, AI chat, and agricultural advice.

## Target users

The apparent target users are farmers and agriculture users who need localized, mobile-first guidance. The app offers English, Hindi, Marathi, Telugu, Tamil, and Bengali language choices.

## Current user flows

1. App starts with Firebase initialization, then an email/password authentication gate.
2. New users can sign up; a Firestore `users/{uid}` profile is written.
3. Authenticated users select a language and view a three-page onboarding carousel.
4. Onboarding opens the main navigation shell.
5. Main tabs expose Home, Scan Crop, Chat, Advice, and Profile.
6. Home requests location/weather data and displays dashboard information and trusted market content when available.
7. Users can enter soil data, request crop advice, chat with an AI service, and select/capture a crop image.
8. Profile displays the Firebase user, edits the name in Firestore, and signs out.

## Architecture

The app is a Flutter application using large StatefulWidget screens with services called directly from widgets. There is no repository layer, typed domain model layer, dependency injection, or centralized state-management solution. The main shell uses a `PageView`, while several feature screens retain older navigation implementations.

## Technology stack

- Flutter/Dart
- Material 3
- Firebase Core, Firebase Auth, and Cloud Firestore
- Google Fonts and Font Awesome
- `http`
- Google Generative AI package
- Flutter Markdown
- Geolocator and Geocoding
- Image Picker
- Permission Handler
- Shared Preferences
- Flutter Native Splash and Launcher Icons tooling
- Android Gradle/Kotlin v2 embedding

## Current product maturity

The app is a visually developed prototype, not a production-ready agricultural product. Authentication and profile basics exist, but several displayed claims are implemented with static, fallback, or mock data.

# 2. Critical Issues

## C-01: Client-side API secrets are hardcoded

- **Problem:** Gemini, OpenWeather, and Data.gov.in API keys are handled through development `.env` configuration and remain client-side secrets.
- **Why it matters:** APK users can extract keys, abuse quotas, cause billing, and bypass intended usage controls.
- **Recommended solution:** Rotate both keys immediately, remove them from source and Git history, and route calls through an authenticated backend or tightly restricted proxy. Add quota, abuse, and secret-scanning controls.
- **Priority:** CRITICAL / P0.

## C-02: Firebase and Firestore security rules are not present

- **Problem:** The repository contains no Firestore rules. User profile access control is therefore **Needs Verification**.
- **Why it matters:** An open or incorrect rule could expose every user profile or permit unauthorized writes.
- **Recommended solution:** Verify Console rules and deploy rules allowing an authenticated user to read/write only `users/{request.auth.uid}`. Add rules tests.
- **Priority:** CRITICAL / P0.

## C-03: Firebase initialization has no failure UI

- **Problem:** `Firebase.initializeApp()` is awaited without a startup error boundary.
- **Why it matters:** Missing or invalid platform configuration can crash or leave users with no actionable explanation.
- **Recommended solution:** Catch initialization failures, show a retry/configuration screen, and log a non-sensitive diagnostic.
- **Priority:** CRITICAL / P0.

## C-04: AI crop diagnosis is fabricated

- **Problem:** `AIService.analyzePlantHealth()` ignores the image path, waits, and returns deterministic/mock health, disease, yield, and nutrient data.
- **Why it matters:** Users may make unsafe agricultural or pesticide decisions based on false diagnoses.
- **Recommended solution:** Implement real image inference with confidence limits and validation, or clearly label/disable the feature as a prototype. Add safety disclaimers and expert escalation.
- **Priority:** CRITICAL / P0.

## C-05: Navigation can fail at runtime

- **Problem:** Advice navigates to `/input_data`, but that route is not registered in `MaterialApp.routes`.
- **Why it matters:** A valid user action results in a navigation exception.
- **Recommended solution:** Register the route or replace it with the single authenticated navigation architecture.
- **Priority:** CRITICAL / P0.

## C-06: Release signing uses debug credentials

- **Problem:** The Android release build uses the debug signing configuration.
- **Why it matters:** It is unsuitable for Play Store distribution, update identity, and release security.
- **Recommended solution:** Add a private release keystore/signing configuration through protected CI secrets and document the release process.
- **Priority:** CRITICAL / P0.

## C-07: Existing automated test is stale and failing

- **Problem:** The widget smoke test still tests the removed Flutter counter template.
- **Why it matters:** CI cannot provide a trustworthy signal.
- **Recommended solution:** Replace it with tests for startup/auth routing and current app behavior.
- **Priority:** HIGH / P0.

## C-08: Platform configuration is incomplete

- **Problem:** Only Android Firebase configuration is present. iOS lacks `GoogleService-Info.plist`; other supported targets have no verified Firebase setup.
- **Why it matters:** Builds or runtime initialization can fail on platforms that appear enabled.
- **Recommended solution:** Decide supported platforms and generate FlutterFire configuration for each supported platform.
- **Priority:** HIGH / P0.

## C-09: Current worktree contains extensive deletions

- **Problem:** Git status shows 63 entries: 17 modified, 41 deleted, and 5 untracked, including iOS/macOS assets and workspace files.
- **Why it matters:** Builds may be broken or user work may be lost if these changes are accidental.
- **Recommended solution:** Review and commit/restore intentionally; do not overwrite without owner confirmation.
- **Priority:** HIGH / P0.

## C-10: Async operations can update disposed screens

- **Problem:** Several async flows call `setState` after awaits; one existing advice crash was observed before a mounted guard was added.
- **Why it matters:** This causes runtime crashes when users navigate away during network or permission work.
- **Recommended solution:** Apply mounted/request-generation guards consistently and cancel or ignore stale requests.
- **Priority:** HIGH / P1.

## C-11: Partial signup can create orphaned auth users

- **Problem:** Auth account creation happens before Firestore profile creation. A Firestore failure leaves an authenticated user without a profile document.
- **Why it matters:** The profile flow becomes inconsistent and difficult to recover.
- **Recommended solution:** Use a controlled provisioning flow, retryable profile creation, or delete the newly created Auth user when provisioning fails.
- **Priority:** HIGH / P1.

## C-12: Static/fallback information is presented as live

- **Problem:** Market information now has a trusted source and explicit loading/error states, but production secret mediation and broader freshness/caching policy remain.
- **Why it matters:** Users cannot distinguish current data from estimates or sample content.
- **Recommended solution:** Add source/timestamp/stale labels, retry states, or explicitly label sample/demo values.
- **Priority:** HIGH / P1.

# 3. UI/UX Improvements

## Authentication

- **Current problem:** Auth is visually simple but not localized; email validation only checks for `@`; there is no password reset, email verification, account deletion, or clear startup/configuration failure state.
- **Recommended improvement:** Add accessible field errors, password reset, verification status, show/hide password semantics, localized strings, progress/error states, and clear recovery actions.
- **Expected benefit:** Better account completion and fewer support failures.
- **Priority:** P1.

## Language selection and onboarding

- **Current problem:** Onboarding completion and selected language are not persisted. `selectedLanguage` is passed but not meaningfully used. Every authenticated session can return users to onboarding.
- **Recommended improvement:** Persist language and onboarding completion per device/user; provide a settings entry to revisit language/onboarding.
- **Expected benefit:** Faster repeat launches and consistent localization.
- **Priority:** P1.

## Home dashboard

- **Current problem:** The screen is approximately 2,032 lines and mixes dashboard, navigation, weather, market, alerts, and business logic. Several small text sizes, fixed rows, and color-coded cards may fail on narrow screens or large text.
- **Recommended improvement:** Split sections, use responsive layouts, expose loading/error/stale states, add refresh, label sample data, and use semantic controls.
- **Expected benefit:** Easier maintenance and clearer trust in dashboard data.
- **Priority:** P1/P2.

## Scan Crop

- **Current problem:** Image analysis is mock/fabricated. Permission errors are generic. The screen can show a back button while embedded in the main shell, which can pop the shell unexpectedly.
- **Recommended improvement:** Make diagnosis trustworthy or label it as demo, distinguish denied/permanently denied permissions, use a shell-safe back behavior, and show image-processing/loading/error/empty states.
- **Expected benefit:** Safer decisions and predictable navigation.
- **Priority:** P0/P1.

## Chat

- **Current problem:** Fallback responses can hide AI failures. Attachment, camera/gallery, location, and voice actions are incomplete. Icon-only and gesture controls lack semantics. The entire message UI can rebuild on text changes.
- **Recommended improvement:** Show service availability and retry states, complete or remove unsupported actions, add semantic labels, and isolate the composer from the message list.
- **Expected benefit:** Better trust, accessibility, and responsiveness.
- **Priority:** P1/P2.

## Advice and crop recommendations

- **Current problem:** Advice silently falls back, asks for missing weather description data, uses static extraction values, and can navigate to an unregistered route. The crop recommendation screen appears unreachable.
- **Recommended improvement:** Add explicit source/confidence/safety states, structured recommendation data, correct weather mapping, register or remove the unreachable flow, and provide a real input-data path.
- **Expected benefit:** Actionable and understandable recommendations.
- **Priority:** P0/P1.

## Soil input

- **Current problem:** Existing saved data is not loaded; defaults can overwrite user expectations. The three-column parameter layout may overflow. Units and validation are unclear, and saving includes an artificial delay.
- **Recommended improvement:** Load saved values, define units, validate in the service layer, make narrow layouts responsive, remove delay, and show save/error confirmation.
- **Expected benefit:** Accurate user data and fewer accidental overwrites.
- **Priority:** P1.

## Profile

- **Current problem:** Profile works for basic name/email/sign-out, but Firestore loading/error states are not differentiated and `substring(0, 1)` is unsafe for empty names.
- **Recommended improvement:** Add loading/error/empty states, safe initial generation, verification/reset/account deletion actions, and localized labels.
- **Expected benefit:** Robust account management.
- **Priority:** P1.

## Global UI consistency

- **Current problem:** Multiple navigation implementations use different tab ordering and incomplete actions. There are many hardcoded English strings, inconsistent spacing, deprecated color APIs, small labels, and light-gray contrast.
- **Recommended improvement:** Establish theme tokens, one navigation shell, centralized localization, consistent component patterns, and accessibility-tested typography.
- **Expected benefit:** Coherent product experience.
- **Priority:** P1/P2.

# 4. Existing Features That Should Be Enhanced

| Feature | Current implementation | Problems/limitations | Suggested enhancement | User benefit | Technical considerations | Priority |
|---|---|---|---|---|---|---|
| Authentication | Firebase email/password auth | No verification, reset, deletion, robust provisioning, or initialization failure UI | Add complete account lifecycle and guarded startup | Recoverable, trustworthy accounts | Firebase Auth, rules, localized errors | P1 |
| User profile | Firestore name document and sign-out | Loading/error gaps, unsafe initial, no account controls | Add typed profile handling and lifecycle actions | Clear account ownership | User-scoped rules and merge writes | P1 |
| Onboarding | Three-page carousel | Completion not persisted; language parameter underused | Persist completion and language | Faster repeat usage | SharedPreferences or user profile | P1 |
| Localization | Six locale maps | Most screens remain English; no locale-aware formatting | Localize all UI/errors and format values | Wider usability | ARB/message catalog recommended | P1/P2 |
| Weather | Geolocator plus OpenWeather HTTP | Repeated location calls, no timeout/cache, first five 3-hour entries treated as days | Add location cache, validated client, daily aggregation, stale/retry UI | Reliable current forecasts | Repository/cache, permission states | P1 |
| Soil data | SharedPreferences JSON | Not loaded on entry, shared across users, corruption/partial-write risks | Typed model, validation, load-on-start, explicit local/cloud policy | Preserved and accurate measurements | Per-user Firestore or scoped local key | P1 |
| AI chat | Gemini service with fallback | Key exposure, silent fallback, no cancellation/limits | Backend mediation, structured responses, clear availability state | More reliable advice | Authenticated proxy and quotas | P0/P1 |
| Crop scan | Image picker and mock analysis | Image ignored; false health/disease output | Real inference or honest prototype state | Safer decisions | Image upload/privacy/consent | P0 |
| Crop recommendations | Keyword/static extraction | Unreachable screen and fabricated detail data | Complete structured flow or remove stale code | Useful recommendations | Typed recommendation model | P1 |
| Market information | Data.gov.in/AGMARKNET records with source and arrival date | Production secret mediation and broader freshness/caching policy remain | Keep trusted source, timestamp/source labels, cache, and stale handling | Better decisions | Data source and caching | P1 |
| Navigation | PageView plus embedded screen nav | Duplicate shells, inconsistent back behavior, missing route | One authenticated shell and route strategy | Predictable movement | Router/guard tests | P0 |
| Profile tab | Recently implemented Firebase profile | No loading/error distinctions | Complete account-management UX | Better self-service | Auth and Firestore state | P1 |

# 5. Unnecessary or Redundant Features

| Feature/code | Reason for removal or rework | Impact | Recommendation |
|---|---|---|---|
| Duplicate bottom navigation inside feature screens | Duplicates `MainNavigation` and creates conflicting tab orders/back stacks | Removing it simplifies navigation and prevents accidental shell pops | REWORK |
| Unreachable `CropRecommendationScreen` | No repository call sites were found | Keeping it increases maintenance and confuses feature ownership | REWORK, then REMOVE if product flow is not approved |
| Dead private widget/method implementations | Several builders and chat widgets are unused | Less code and fewer stale paths | REMOVE after behavior review |
| `mobile_scanner` dependency | No Dart usage was found; generated registrants still include it | Removes native/plugin overhead unless QR scanning is planned | REMOVE or implement intended scanner |
| `flutter_svg` dependency | No Dart usage was found | Reduces dependency surface | REMOVE if confirmed unused |
| `cupertino_icons` dependency | No usage was found | Minor dependency cleanup | REMOVE if confirmed unused |
| Static “LIVE” market data | Misleading rather than useful without a source | Removing the label or replacing the source improves trust | REWORK |
| Artificial one-second soil save delay | Adds no user value | Faster feedback | REMOVE |
| Placeholder share/notification/settings actions | Claims functionality users cannot complete | Removing or completing avoids dead ends | REWORK |
| Hardcoded fallback AI answers presented as AI | Misrepresents service availability | Must be clearly labeled or removed | REWORK |

# 6. Missing Features

## Essential

| Feature | What it does and why | High-level implementation | Priority |
|---|---|---|---|
| Secure API mediation | Keeps AI/weather secrets out of APKs | Authenticated backend/proxy with quotas and logging | P0 |
| Firestore rules | Restricts profiles to owners | Deploy and test `request.auth.uid` rules | P0 |
| Firebase startup recovery | Explains configuration/network failures | Initialization state controller with retry UI | P0 |
| Real or disabled crop diagnosis | Prevents unsafe mock advice | Real model/backend or clearly disabled prototype | P0 |
| Correct route for soil input | Makes advice navigation functional | Register route or use shell action | P0 |
| Release signing | Enables safe distribution | Protected keystore and CI configuration | P0 |
| Email verification and password reset | Completes account lifecycle | Firebase Auth actions and verified-state UX | P1 |
| Explicit loading/error/empty/retry states | Makes failures understandable | Shared async state pattern per feature | P1 |
| Per-user soil policy | Prevents cross-account leakage | Cloud user document or scoped local keys | P1 |
| Onboarding/language persistence | Avoids repeated setup | Persist and restore state | P1 |

## Recommended

| Feature | What it does and why | High-level implementation | Priority |
|---|---|---|---|
| Live market data | Official Data.gov.in/AGMARKNET mandi records | Freshness caching and production secret mediation remain | P1 |
| Daily forecast | Presents weather in user-meaningful periods | Aggregate API periods by date | P1 |
| Safety and expert escalation | Reduces risk from agricultural recommendations | Confidence, disclaimers, local expert/contact path | P1 |
| Complete settings | Centralizes language, permissions, account, notifications | Settings screen under one shell | P1 |
| Notification system | Delivers actionable weather/crop alerts | Permission flow, scheduled/remote notifications | P2 |
| History | Lets users review soil, scans, advice | User-scoped Firestore collections with retention policy | P2 |
| Offline mode | Preserves useful cached information | Cache with visible offline/stale status | P2 |
| Accessibility support | Supports screen readers, large text, keyboard | Semantics, contrast, adaptive layouts, tests | P1 |

## Optional/Future

- Voice input/output after chat reliability is established.
- Camera/gallery attachments in chat after privacy and upload design.
- Location sharing in chat only with explicit consent.
- Crop/location/season personalization.
- Analytics and crash monitoring with privacy controls.
- Expert marketplace or agronomist escalation.

# 7. Performance Improvements

1. **Avoid eager feature initialization:** `PageView` creates multiple feature screens; Advice can start location/weather work before it is visible. Lazy-load or start work on visible-tab activation.
2. **Reuse location data:** Home weather and forecast independently retrieve location. Fetch once per refresh and pass the coordinate to both requests.
3. **Add request timeouts and cancellation:** HTTP, AI, geocoding, and permission flows currently lack consistent timeout/cancellation behavior.
4. **Cache weather and geocoding:** Use a short-lived cache with timestamp and stale state to reduce API calls and startup latency.
5. **Reduce chat rebuild scope:** Keep the composer state separate from the message list; avoid rebuilding all messages on every keystroke.
6. **Handle stale async results:** Ignore responses for disposed or superseded requests.
7. **Optimize images:** Resize/compress before upload/inference, cache remote images where applicable, and clean temporary files.
8. **Reduce monolith cost:** Split the 2,032-line Home screen and other large screens into focused widgets and controllers.
9. **Avoid repeated font work:** Centralize typography and avoid repeated dynamic font construction where not needed.
10. **Use structured logging:** Replace production `print` calls and avoid logging sensitive request data.
11. **Profile real devices:** Measure startup, memory, frame time, network latency, and battery on low-end Android hardware.

# 8. Code Quality & Architecture

## Current issues

- Business logic, network calls, persistence, navigation, and presentation are mixed in StatefulWidgets.
- No repository/data-source separation or typed domain models.
- Duplicate navigation shells and feature-local navigation.
- Large files make behavior difficult to test and review.
- Several unused methods, widgets, dependencies, and stale template code remain.
- Hardcoded strings, colors, thresholds, and market values are spread through screens.
- Broad exception handling turns failures into silent fallback behavior.
- Several async gaps and lifecycle concerns exist.

## Appropriate improvement path

Do not over-engineer this app. Use a lightweight structure:

```text
lib/
  app/
    app.dart
    router.dart
    theme.dart
  models/
  services/
  repositories/
  screens/
  widgets/
  localization/
```

Recommended steps:

1. Establish one app/router/authenticated-shell boundary.
2. Extract typed models for UserProfile, SoilData, Weather, Forecast, Recommendation, and ChatMessage.
3. Keep API and Firebase access in services/repositories.
4. Use a simple feature controller/notifier pattern rather than introducing a large state framework unless complexity proves it necessary.
5. Centralize result/error states and design tokens.
6. Remove dead code only after call-site verification.
7. Add focused unit/widget tests before broad refactoring.

## Naming and maintainability

- Use consistent screen/content naming; avoid placeholder names after replacement.
- Replace magic strings and numeric thresholds with named constants or configuration.
- Keep user-facing strings in localization resources.
- Avoid duplicating bottom navigation and route definitions.
- Preserve explicit error context instead of generic fallback success states.

# 9. Security Audit

## Immediate attention

1. Rotate Gemini and OpenWeather keys in provider consoles.
2. Remove those keys from source and Git history.
3. Add an authenticated backend/proxy with quotas and abuse controls.
4. Verify Firebase Android API key restrictions by package and signing certificate.
5. Verify Firestore rules; repository rules are absent.
6. Confirm Email/Password provider configuration and billing limits.
7. Avoid exposing raw Firebase implementation errors to users.
8. Add input length/range validation at service boundaries.
9. Decide whether soil data is local-only or cloud-synced; current local data survives sign-out and is not user-scoped.
10. Add secret scanning to CI.

## Firebase configuration

`google-services.json` is required for Android and is not itself equivalent to a server secret, but it must be correctly restricted. It is currently untracked according to the audited worktree. Whether it should be committed or supplied through build configuration is a project policy decision.

## Needs Verification

- Actual Firestore Console rules.
- API key restrictions and billing.
- Whether exposed keys were used by third parties.
- Release certificate SHA-1/SHA-256 registration.
- Firebase configuration for iOS, web, macOS, Windows, and Linux.

# 10. Responsiveness & Device Compatibility

The source contains fixed rows/columns and compact labels that require testing at 320px, 360px, 375px, 390px, 414px, and tablet widths.

Priority checks:

- Home dashboard cards and fixed rows at 320px.
- Soil input three-column parameter layout at narrow widths and 200% text scale.
- Weather and crop cards with long localized strings.
- Chat composer, attachment actions, and keyboard resizing.
- Profile dialogs and long email/name values.
- Landscape orientation and tablet two-pane opportunities.
- Web/desktop keyboard focus and window resizing.
- Android 13/14 camera, location, notification, and install behavior.

No automated or real-device matrix evidence exists for these sizes. Results are **Needs Verification** until tested.

# 11. Accessibility

Findings:

- Icon-only controls and many `GestureDetector` actions lack semantic labels/tooltips.
- Important information relies on color and icons.
- Numerous labels are 9–12px and light gray.
- Fixed layouts may clip at large font scales.
- Reduced-motion behavior is not implemented.
- Keyboard, screen-reader, high-contrast, and focus-order testing is not documented.

Actions:

1. Use `IconButton`, `Button`, `ListTile`, and `Semantics` for actions.
2. Add labels/tooltips to icon-only controls.
3. Verify contrast for green/gray text and status colors.
4. Test 200% text scaling and avoid fixed-height text containers.
5. Add non-color status text and icons.
6. Respect reduced-motion settings where practical.
7. Test TalkBack, keyboard navigation, web focus, and landscape.
8. Add accessibility widget tests for auth, navigation, profile, and core actions.

# 12. Feature Ideas / Future Roadmap

## Version 1.1 — Trust and correctness

- Secure API mediation and key rotation.
- Firestore rules and Firebase startup recovery.
- Complete auth lifecycle.
- Correct navigation and soil-data persistence.
- Honest AI/scanning behavior with safety warnings.
- Loading/error/empty/retry states.
- Localization completion.

## Version 1.2 — Useful daily workflow

- Live weather with cached daily forecasts.
- Market freshness, caching, and production secret mediation.
- User-scoped soil history.
- Crop/location/season personalization.
- Settings and notification preferences.
- Actionable weather/crop notifications.
- Share/export recommendations.

## Version 2.0 — Deeper assistance

- Real image-based crop diagnosis with confidence and expert review.
- Recommendation history and progress tracking.
- Offline-first experience.
- Agronomist escalation or expert marketplace.
- Better chat attachments and voice support.
- Analytics/crash monitoring with privacy controls.

## Long-term ideas

- Regional crop calendars.
- Community/local cooperative insights.
- Multilingual voice assistant.
- Farm-level trend analytics.
- Integrations with verified soil labs, weather stations, or agricultural programs.

# 13. Prioritized Master Task List

Priority mapping: P0 = critical, P1 = high, P2 = medium, P3 = low. Statuses below are maintained as a live tracker and reflect verified implementation state through the latest roadmap update.

| ID | Task | Category | Priority | Difficulty | Dependencies | Status / implementation note |
|----|------|----------|----------|------------|--------------|------------------------------|
| T01 | Rotate and remove exposed Gemini/OpenWeather keys | Security | P0 | Medium | Provider access | [BLOCKED - MANUAL ACTION] Source keys removed; rotate provider keys and purge exposed values from Git history. |
| T02 | Add authenticated backend/proxy for AI and weather | Security/Backend | P0 | Hard | T01 | [BLOCKED - MANUAL ACTION] Deploy an authenticated backend/proxy with quotas, abuse controls, and server-held provider secrets. |
| T03 | Deploy and test owner-only Firestore rules | Security/Firebase | P0 | Medium | Firebase Console | [BLOCKED - MANUAL ACTION] Configure and deploy rules allowing each authenticated user access only to `users/{uid}`. |
| T04 | Add Firebase initialization failure and retry UI | Reliability | P0 | Easy | T05 | [COMPLETED] Added startup error boundary with retry UI. |
| T05 | Generate/configure Firebase options for supported platforms | Platform/Firebase | P0 | Medium | Platform decision | [BLOCKED - MANUAL ACTION] Generate and register Firebase configuration for each supported platform. |
| T06 | Replace or clearly disable fabricated crop diagnosis | Safety/AI | P0 | Hard | T02 | [PARTIALLY COMPLETED] Mock diagnosis is disabled and labeled unavailable; validated real image inference remains. |
| T07 | Fix/register the `/input_data` route | Navigation | P0 | Easy | T08 | [COMPLETED] Registered the `/input_data` route. |
| T08 | Consolidate to one authenticated navigation shell | Architecture | P0 | Hard | Product flow decision | [COMPLETED] MainNavigation is the authenticated navigation shell. Duplicate feature-level bottom navigation builders were removed, and the existing PageView/tab architecture is preserved. |
| T09 | Configure protected release signing | Android/Release | P0 | Medium | Signing credentials | [PARTIALLY COMPLETED] Debug signing was removed and `key.properties` support added; keystore and CI secrets remain to be configured. |
| T10 | Review and resolve deleted platform files safely | Platform/Git | P0 | Medium | Owner confirmation | [BLOCKED - MANUAL ACTION] Owner must review intentional iOS/macOS file deletions and restore any required platform assets. |
| T11 | Replace stale counter widget test | Testing | P0 | Easy | T08 | [COMPLETED] Existing widget tests were updated/replaced as part of the current suite, which passes. |
| T12 | Add email verification and password reset | Authentication | P1 | Medium | Firebase Auth | [COMPLETED] Added verification email, verification status/resend action, and password reset. |
| T13 | Add account deletion and auth lifecycle recovery | Authentication | P1 | Medium | T03/T12 | [COMPLETED] Added reauthentication-protected profile deletion and recent-login error handling. |
| T14 | Make signup profile provisioning retryable/consistent | Authentication | P1 | Medium | T03 | [COMPLETED] Auth creation is retained while profile and verification setup failures are reported as retryable follow-up work. |
| T15 | Persist onboarding completion and selected language | UX/State | P1 | Easy | Auth flow | [COMPLETED] Added per-user persistence plus Settings controls to change language and revisit onboarding. |
| T16 | Complete localization for all screens and errors | UX/Localization | P1 | Medium | T08 | [PARTIALLY COMPLETED] Added translated shared navigation, account/settings, and permission keys with locale tests; feature labels and errors remain hardcoded in many screens. |
| T17 | Load, validate, and safely persist soil data | Data/UX | P1 | Medium | Data policy | [COMPLETED] Soil N/P/K/pH input is validated and persisted; soil data is scoped to the authenticated user. The soil input UI no longer asks for soil moisture, and weather supplies temperature/humidity separately. |
| T18 | Scope soil data per authenticated user or document local-only behavior | Data/Security | P1 | Medium | T03/T17 | [COMPLETED] Soil persistence uses a user-scoped storage key, and cleanup behavior was tested. |
| T19 | Add weather timeout, validation, retry, cache, and stale state | Weather | P1 | Medium | T02 | [COMPLETED] WeatherService was restored from stubs. OpenWeather integration works with timeout/status handling, coordinate validation, cached location fallback, diagnostics, and dotenv-based local development configuration. |
| T20 | Reuse one location lookup and aggregate daily forecasts | Weather/Performance | P1 | Medium | T19 | [COMPLETED] Weather/location flow was improved and daily forecast aggregation was implemented. |
| T21 | Label/remove static market data and implement trusted source | Product/Data | P1 | Medium | Data source | [COMPLETED] Static sample market data was removed from Home. The market section now uses official Data.gov.in/AGMARKNET-backed mandi data with dotenv API-key configuration, typed commodity/modal-price/market/state/arrival-date/source parsing, verified server-side filtering, Maharashtra defaults, and capped results. Unsupported date/sort parameters were deliberately not used. T21-B extends this with MainNavigation-owned in-memory ML-to-market integration: Advice publishes successful top-3 crop names, Home requests those commodities, duplicate requests are prevented, and valid existing market data is preserved on refresh failure. |
| T22 | Add explicit loading/error/empty/retry states across features | UX/Reliability | P1 | Medium | T08 | [COMPLETED] Added comprehensive loading/error/empty/retry states: Home (weather & market retry/cache/error states), Advice (ML/weather loading/error/retry & trust banner), Scan (analyzing/result/unavailable error card & reset), Chat (distinct error bubble & inline prompt retry), Profile (StreamBuilder error card with stream retry & edit name loading indicator), and InputData (initial load failure retry & saving state). |
| T23 | Add AI confidence, source, safety disclaimer, and expert escalation | Safety/AI | P1 | Medium | T06 | [PARTIALLY COMPLETED] ML confidence is displayed with crop recommendations, and Gemini explains the selected ML crop. Prompt safeguards address fabricated prices/costs/subsidies and unsafe specific treatment/dosage claims in AIService. AdviceScreen includes a Safety & Expert Escalation card, and ChatScreen provides a safety notice bar. Physical device validation remains. |
| T24 | Complete or remove share, notifications, settings, and attachment actions | Product/UX | P1 | Medium | Product decision | [PARTIALLY COMPLETED] Settings is implemented; share, notifications, and chat attachments remain incomplete. |
| T25 | Fix async lifecycle guards and request cancellation everywhere | Reliability | P1 | Medium | T22 | [PARTIALLY COMPLETED] Added mounted/request-generation guards for weather plus bounded location/geocoding/HTTP operations, scan, Advice, delayed chat scroll, and explicit auth loading/error exits; remaining async flows still need coverage. |
| T26 | Add camera/photo/location permission explanations | Android/UX | P1 | Easy | Platform testing | [PARTIALLY COMPLETED] Camera denied/permanently-denied explanations and actionable settings are present; location-specific UX remains. |
| T27 | Add responsive layouts for narrow, large-text, tablet, and landscape states | UI/Responsive | P1 | Medium | T08 | [PARTIALLY COMPLETED] Several narrow-screen/320px and large-text overflow issues were fixed; soil input and Home layout responsiveness were improved. Full tablet/landscape/large-text coverage is not complete. |
| T28 | Complete profile loading/error/empty and safe avatar initial handling | Profile | P1 | Easy | T03 | [COMPLETED] Added profile loading/error states, safe initials, verification status, and account actions. |
| T29 | Add semantics, tooltips, contrast, and accessible controls | Accessibility | P1 | Medium | T08 | [PARTIALLY COMPLETED] Semantic labels and tooltips were added to several controls, with accessibility improvements in tested areas. A full accessibility audit and coverage are not complete. |
| T30 | Split Home and feature screens into focused widgets/controllers | Architecture | P2 | Hard | T08 | [PARTIALLY COMPLETED] HomeMarketSection was extracted; additional Home decomposition remains. |
| T31 | Extract typed models and repositories/services | Architecture | P2 | Hard | T30 | [PARTIALLY COMPLETED] Typed weather/soil service models exist; repository and controller separation remains. |
| T32 | Remove duplicate navigation and dead widgets/methods | Cleanup | P2 | Medium | T08/T30 | [PARTIALLY COMPLETED] Main shell usage is established and all four confirmed feature-level duplicate navigation builders were removed; other dead widgets/methods remain. |
| T33 | Remove confirmed unused dependencies | Cleanup | P2 | Easy | Usage verification | [COMPLETED] Removed `mobile_scanner`, `flutter_svg`, and `cupertino_icons`. |
| T34 | Replace deprecated `withOpacity` usage | Code quality | P2 | Easy | None | [PARTIALLY COMPLETED] Automated cleanup was attempted; many deprecated opacity calls remain in legacy screens. |
| T35 | Replace production `print` calls with structured logging | Code quality | P2 | Easy | Logging choice | [PARTIALLY COMPLETED] Structured diagnostic logging was introduced in areas such as weather and AI; a complete production-wide logging migration is not complete. |
| T36 | Add unit tests for weather, soil, recommendations, localization, and storage | Testing | P2 | Medium | T31 | [PARTIALLY COMPLETED] Added soil validation and user-scoped storage, weather parsing/daily aggregation, unavailable scan, fallback recommendations, and supported-locales tests; broader service coverage remains. |
| T37 | Add widget tests for auth, routing, profile, and async states | Testing | P2 | Medium | T08/T22 | [PARTIALLY COMPLETED] Added startup recovery, localized five-tab shell, password visibility accessibility, and auth loading/error tests; profile and broader async-state tests remain. |
| T38 | Add Firebase/device permission integration tests | Testing | P2 | Hard | T03/T26 | [NOT STARTED] |
| T39 | Lazy-load feature work and reduce chat rebuild scope | Performance | P2 | Medium | T30 | [PARTIALLY COMPLETED] Main shell now uses PageView.builder; chat composer/message rebuild separation remains. |
| T40 | Add image resizing, caching, cleanup, and request cancellation | Performance/AI | P2 | Medium | T06 | [PARTIALLY COMPLETED] Image picker resizing and scan request-generation cancellation exist; image caching and cleanup remain. |
| T41 | Add offline/stale caching with visible status | Performance/Product | P2 | Hard | T19/T31 | [PARTIALLY COMPLETED] Weather cache, stale badge, refresh, and empty state exist; broader offline cache remains. |
| T42 | Add user history for scans, soil, advice, and recommendations | Product/Data | P2 | Hard | T03/T31 | [NOT STARTED] |
| T43 | Add crop/location/season personalization | Product | P3 | Medium | T42 | [NOT STARTED] |
| T44 | Add notification scheduling and actionable alerts | Product | P3 | Hard | T24/T42 | [NOT STARTED] |
| T45 | Improve splash, launcher, branding, and web metadata | UI/Platform | P3 | Easy | Platform decision | [PARTIALLY COMPLETED] Web title and description were updated; native branding/platform review remains. |
| T46 | Add analytics/crash monitoring with privacy controls | Operations | P3 | Medium | Privacy review | [NOT STARTED] |

# 14. Recommended Development Order

## Phase 1 — Critical fixes

Rotate secrets, verify worktree/platform files, fix startup failure handling, correct routes, replace the stale test, and stop fabricated diagnosis from being presented as fact. These items prevent security incidents, crashes, and misleading user decisions.

## Phase 2 — Security and account integrity

Deploy Firestore rules, restrict Firebase keys, complete platform Firebase setup, fix partial signup behavior, and add email verification/reset/account deletion. This protects user data before additional persistence is added.

## Phase 3 — Core functionality

Consolidate navigation, make soil data reliable and user-scoped, improve weather parsing/caching, and complete the remaining market freshness/security work. Core flows must be correct before visual polish.

## Phase 4 — UI/UX and accessibility

Complete loading/error/empty states, localization, responsive layouts, profile robustness, semantics, contrast, and permission explanations. This makes the corrected core usable across devices and languages.

## Phase 5 — Performance and maintainability

Split monolithic screens, extract models/repositories, remove dead code/dependencies, reduce rebuilds, cache images/data, and add structured logging.

## Phase 6 — Additional features

Add settings, notifications, history, personalization, offline behavior, sharing, and complete chat attachments only after the underlying data and trust model are stable.

## Phase 7 — Testing and release

Run unit, widget, integration, accessibility, device-size, permission, and performance tests. Configure release signing, crash monitoring, CI, and supported-platform release checklists.

# 15. Final Application Health Report

Scores reflect the audited source and are not a substitute for real-device/product validation.

| Area | Score | Reason |
|---|---:|---|
| UI/UX | 6/10 | Visually developed, but inconsistent navigation, static/live ambiguity, incomplete actions, and weak states |
| Functionality | 5/10 | Many flows exist, but scanning is mock, routes are incomplete, and several features are placeholders |
| Performance | 5/10 | Duplicate requests, eager screens, large widgets, and limited caching |
| Security | 2/10 | Client API secrets and unverified Firestore rules are critical risks |
| Code Quality | 5/10 | Working prototype with many large files, dead code, warnings, and mixed responsibilities |
| Architecture | 4/10 | Direct widget-service coupling and duplicate navigation |
| Responsiveness | 5/10 | Some adaptive wrappers exist, but narrow/large-text/tablet behavior is unverified |
| Accessibility | 3/10 | Missing semantics, small text, color dependence, and no evidence of accessibility testing |
| Overall Product Quality | 4/10 | Promising prototype, not ready for production agricultural decisions |

## Top 10 things that MUST be fixed

1. Rotate/remove exposed Gemini and OpenWeather keys.
2. Add backend mediation and quotas.
3. Verify/deploy Firestore owner-only rules.
4. Replace or clearly disable fabricated crop diagnosis.
5. Add Firebase startup failure recovery.
6. Fix `/input_data` navigation.
7. Consolidate duplicate navigation.
8. Configure real release signing.
9. Resolve accidental platform-file deletions.
10. Replace the failing stale widget test.

## Top 10 things that SHOULD be improved

1. Complete auth lifecycle.
2. Persist onboarding/language.
3. Make soil data load, validate, and scope correctly.
4. Add weather cache, timeout, daily aggregation, and retry.
5. Complete market freshness/caching and production secret mediation.
6. Add explicit loading/error/empty states.
7. Localize all user-facing strings.
8. Add safety disclaimers and expert escalation.
9. Add semantics and responsive large-text layouts.
10. Split large screens and remove duplicate/dead code.

## Top 10 features worth adding

1. Market freshness, caching, and production secret mediation.
2. Daily cached forecast.
3. User-scoped soil history.
4. Crop/location/season personalization.
5. Settings and notification preferences.
6. Actionable weather/crop alerts.
7. Recommendation history and sharing.
8. Offline/stale-data support.
9. Real image diagnosis with confidence and expert review.
10. Expert escalation/contact workflow.

## Features to remove or rework

- Rework duplicate feature-level bottom navigation into one shell.
- Rework or remove unreachable crop recommendation code.
- Remove dead private widgets and methods after call-site verification.
- Remove confirmed unused dependencies.
- Rework static “LIVE” market labels.
- Rework incomplete share, notification, settings, chat attachment, and location actions.
- Rework fallback AI responses so they are clearly identified as fallback/unavailable.

## Biggest technical risks

- Extractable API keys and uncontrolled provider usage.
- Incorrect/missing Firestore rules.
- Mock agricultural diagnosis presented as real.
- Platform configuration drift and deleted native files.
- Duplicate navigation and untested async lifecycle paths.
- Local soil data crossing account boundaries.
- Debug-signed release artifacts.

## Biggest UX risks

- Users trusting false crop/disease/pesticide advice.
- Users believing static or fallback information is current.
- App exits/navigation failures during common actions.
- Repeated onboarding and lost language preference.
- Silent failures without retry or explanation.
- Poor usability at narrow widths, large font sizes, and with assistive technology.

