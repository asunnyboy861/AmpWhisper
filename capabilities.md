# Capabilities Configuration

## Analysis
Based on operation guide analysis (TR-20261013-AmpWhisper吉他音色匹配操作指南.MD) and us.md:
- **Camera** — GearSnap photo gear entry (guide §3.3 MUST #4, §5.4): keyword "拍照"/"相机"/"拍一张" → Camera usage required
- **Photo Library** — GearSnap fallback to pick an existing photo → Photo Library usage required
- **In-App Purchase** — Pro subscription + BYO lifetime (guide §8): StoreKit 2 products; no explicit entitlement needed (automatic with StoreKit 2)
- **Microphone** — NOT needed (recording comparison is COULD/scope-out for MVP; A/B preview plays bundled audio only)
- **iCloud** — NOT needed (local-first SwiftData; guide has no sync requirement for MVP)
- **Apple Watch** — NOT needed for MVP (guide SHOULD #12, month 2; deferred)
- **Push Notifications / App Groups / Background Modes / HealthKit / Location / Siri** — none mentioned in guide

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| Camera (NSCameraUsageDescription) | ✅ Configured | project.yml INFOPLIST_KEY build setting |
| Photo Library (NSPhotoLibraryUsageDescription) | ✅ Configured | project.yml INFOPLIST_KEY build setting |
| In-App Purchase (StoreKit 2) | ✅ Ready | No entitlement file required; products configured in PHASE 4+5 |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| (none) | — | All detected capabilities auto-configured |

## No Configuration Needed
- iCloud/CloudKit — local SwiftData only
- Apple Watch — deferred to month 2 per guide
- Push / App Groups / Background Modes / HealthKit / Location / Siri — not in guide
- Microphone — A/B preview uses bundled audio; no recording in MVP

## Verification
- Build succeeded after configuration: ✅ (placeholder skeleton, 8.9s)
- All entitlements correct: ✅ (no custom entitlements required)
- Signing verification (generic/platform=iOS): ✅ PASSED — "Apple Development: he zhou (VX3Q75X27B)" on all targets, BUILD SUCCEEDED
- DEVELOPMENT_TEAM: JP4TN5PTS3 baked at project level (all targets inherit)
- PrivacyInfo.xcprivacy: ✅ App target covered (UserDefaults CA92.1 + FileTimestamp C617.1, tracking=false, no collected data)
