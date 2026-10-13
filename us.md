# AmpWhisper — iOS Development Guide

> **App Name**: AmpWhisper (no colon, no "word:word" format)
> **Subtitle**: Guitar Tone Matched to You (26 chars ≤ 30)
> **Bundle ID**: `com.zzoutuo.AmpWhisper` — ⚠️ Guide suggested `com.ampwhisper.ios`; IGNORED per ios-app-developer CRITICAL RULE 11 (DOCUMENT-vs-SKILL PRECEDENCE). Skill preset `${BUNDLE_PREFIX}<APP_NAME>` always wins.
> **Min iOS**: 26.0 (hard requirement: Foundation Models / Apple Intelligence; overrides .env default 17.0)
> **Target Market**: United States (English-speaking guitarists, global reach)
> **Copyright**: © 2026 he zhou
> **Slogan**: *Your amp has secrets. We whisper them.*
> **Document Date**: 2026-10-13
> **Contact**: iocompile67692@gmail.com ｜ GitHub: asunnyboy861

---

## Executive Summary

**Product vision**: AmpWhisper turns the loneliest frustration in guitar playing ("same guitar, same amp — why does HIS tone sound like THAT?") into a 60-second guided answer. Point the camera at your gear, pick a song, and the app outputs every knob position, pedal chain order, and an A/B audio preview — adapted to YOUR equipment, with a confidence score and a "why" note for every suggestion.

**Compliance red lines (from guide §0)**:
1. This is a "device setup suggestion tool" — no audio hardware sales.
2. No brand trademark infringement: device brand/model names used ONLY as compatibility descriptions (nominative fair use). No brand logos in share cards.
3. Song tone data entered as "reconstructed from public performance videos/interviews" with source attribution.
4. A/B preview labeled "modeled approximation — final result depends on your real gear".

**Key differentiators vs ToneAdapt (guide §3.2)**:
1. GearSnap photo gear entry (1 min vs 10 min manual)
2. Full-chain adaptation engine (guitar → pedals → cab → amp, 4 levels, each with confidence)
3. Listen-before-you-turn A/B preview (category exclusive, NeuralAudio on-device)
4. Pedal Chain Coach with exception rules
5. Scene re-adaptation (Bedroom / Rehearsal / Gig)
6. Whisper Notes teaching on every suggestion
7. Transparent pricing (3 places)
8. Weekly Tone Drops (5 new songs/week)

---

## Competitive Analysis

| App | Strengths | Weaknesses | Our Advantage |
|-----|-----------|------------|---------------|
| ToneAdapt | $25K/mo, 100K signups, song+device→knob settings | 100% manual gear entry (biggest friction); no preview; no pedal chain order; no "why" teaching; multi-region pricing chaos | Photo entry (GearSnap); full-chain engine; A/B preview; transparent pricing |
| ToneTwin / Tone Adapt Pro | 10,000+ tones, cheap weekly sub | Manual-style unverified dumps; no preview; shallow fast-follow | Verified recipes with confidence + Whisper Notes |
| Tonebridge (Ultimate Guitar) | Category veteran, free+IAP, per-song presets | Forum-verified bugs (transpose loss, preview pitch errors); presets don't adapt to YOUR rig | Full-chain adaptation to user's actual gear |
| ChatGPT (generic) | Free-form conversation | Founder-verified "low accuracy and unstable"; no device context | Deterministic local engine + confidence; AI never enters adaptation path |
| AmpliTube / BIAS FX / Tonex | Pro audio engines, huge model libraries | Steep learning curve ("another instrument"); misaligned with "sound like that song" goal | Zero-learning answer machine |
| Forums / YouTube | Free | Hours per song; settings are for "someone else's rig" | Instant, adapted to your rig |

---

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | Onboarding (60s activation) | 1. Welcome "Your amp has secrets." → 2. Build Rig: GearSnap photo OR manual pick (brand→model 2-level menu, pedals skippable) → 3. Pickup type: 2 big buttons (single coil/humbucker, 3s) → 4. Pick a song → 5. First ToneMatch result | Photo or picker selections, pickup choice | Rig assembly; recognition routing; confirmation UI | Completed UserRig; navigates to song picker | SwiftData `Rig`, `GearItem` | First result reachable ≤ 60s; fallback path never dead-ends |
| 2 | Today (Home) | Open app → "Pick a song, sound like the record." → Weekly Tone Drops wall + search → tap a song | Tap / search text | Song library query; drops ordering (newest first) | Song cards grid; search results | Bundled JSON `ToneRecipe` | Song wall renders < 1s from local store; search matches title/artist/tags |
| 3 | Rig Management | Rig tab → view/edit guitar, amp, cab, pedals → change any item → result re-adapts instantly | Picker selections, custom gear entry | Rig validation; re-run ToneMatchEngine on change | Updated Rig page; live re-adaptation | SwiftData `Rig`, `GearItem` | Editing gear re-computes open recipe immediately; custom gear allowed |
| 4 | ToneMatch Engine (result page) | Select song → 6 big skeuomorphic knobs light up with suggested values → user compares & turns real knobs, taps each to confirm (lights up, haptic) → all lit → "Dialed In ✅" celebration + share card CTA | Song selection + user rig | `ToneMatchEngine.adapt()`: L1 pickup diff → L2 pedal personality → L3 cab brightness → L4 amp family; confidence per rule; guard: clamp 0–10, conflict resolution by confidence, unknown gear → "generic advice" warning (never fake precision) | Knob values (Int 0–10), per-knob `KnobAdjust` list, overall confidence badge, warnings | SwiftData `MatchHistory` | Pure function, 100% unit tested, zero AI/network in path; unknown devices show generic-advice banner |
| 5 | Whisper Notes | Any suggestion row → tap chevron → expand "why" card | `KnobAdjust.reason` strings | Static content display | Expanded educational card | Bundled rule tables (JSON) | Every knob suggestion has an expandable reason; content matches rule table |
| 6 | GearSnap photo recognition | 1. Camera 3 modes (headstock / amp panel / pedalboard) → 2. Capture → 3. Scan shimmer animation → 4. Top3 candidate cards with confidence → 5. Confirm or "none of these → manual pick" (never dead end) | JPEG photo data | Router: free tier → Apple Foundation Models on-device rough recognition (5/day); Pro → GLM-5.3-Flash vision model-level (Top3 + confidence); ≥85% auto-highlight confirm | Confirmed `GearItem` merged into Rig | SwiftData `GearItem`; recognition counters (UserDefaults) | AI result NEVER auto-saves without confirmation UI; network/AI failure never blocks (manual fallback); free tier counters enforced locally |
| 7 | Pedal Chain Coach | Chain section on result page OR new pedal added → horizontal draggable pedal strip → exception hint cards | User pedal list | `ChainOrderEngine.order()`: conventional order (Tuner→Filter→Comp→Gain→Mod→Time→Reverb) + exceptions (wah-after-fuzz etc.) | Ordered chain + per-step "why" + exception warnings | Derived (no persistence needed) | Deterministic sorting unit tested; fuzz+wah coexistence shows explanation card |
| 8 | Free quota metering | App launch → any full ToneMatch → counter decrements → at 0 → value-first Paywall (shows GearSnap 5s vs manual 10min comparison) | Local date + counter | Daily reset check (local calendar day); no account | Quota state; Paywall trigger | UserDefaults: lastMatchDate, matchesToday | Exactly 1 full match/day free; browsing library always free; counter survives relaunch; resets at local midnight |
| 9 | Paywall / Pricing page | 1. Trigger (2nd GearSnap attempt / quota out / scene tier) → 2. Three-tier cards + "1 free match every day, forever" banner → 3. Purchase → 4. Manage subscriptions link | StoreKit 2 products | Entitlement evaluation; transaction verification | Unlocked entitlements; price display ($9.99/mo, $49.99/yr + 7-day trial, $39.99 BYO lifetime) | StoreKit 2 entitlements | Legal links (Privacy + Terms) functional; auto-renew disclosure text present; NO lifetime option on GLM-consuming Pro tiers (BYO only) |
| 10 | Scene re-adaptation (Pro) | Rig page scene cards (Bedroom/Rehearsal/Gig) → tap → recipe re-adapts | Scene selection | Scene strategy: Bedroom adds dynamic gain compensation, Gig trims level | Re-adapted knob values with delta annotations | SwiftData `Rig.scene` | One tap re-runs engine; Bedroom audibly compensates low-volume dynamics |
| 11 | A/B Preview (Pro) | Result page ▶️ button → dual-track playback: target tone vs your adapted tone → toggle A/B → knobs animate to corresponding values | Bundled NAM captures (curated subset) + IR files; adapted knob values | `AudioEngine` module: AVAudioEngine + NeuralAudio C++ (MIT) via bridging header; process isolation; try/catch boundary | Audio playback; knob UI animation sync | Bundled assets (read-only) | Plays without network; audio module crash never takes down app; labeled "modeled approximation" |
| 12 | Weekly Tone Drops | Today wall "New this week" section → 5 curated songs/week (TikTok-hot BGMs first) | Bundled curated content | Weekly ordering by date | Drop cards; tap → match | Bundled JSON | 5 new recipes marked weekly; content labeled with source attribution |
| 13 | Share card | "Dialed In" state → tap share → vertical poster generated → UIActivityViewController | Knob values, song title, user amp model | `UIGraphicsImageRenderer` vertical card ("Dialed In ✅ Sweet Child — on my $150 amp") | Shared image | None (ephemeral) | Card renders < 1s; no brand logo graphics; text-only brand mention allowed |
| 14 | Settings | Settings tab → pricing transparency (matches store), manage subscription (showManageSubscriptions), contact support, about (MIT attribution + NAM model credits), legal pages, version (dynamic via Bundle.main.infoDictionary) | Taps | Link out / in-app sheets | Settings screens | — | Version reads Bundle (never hardcoded); MIT attribution present; manage subscriptions functional |

### Sub-Features & Detail Interactions

| # | Parent Feature | Sub-Feature | Detail Description | Interaction Pattern |
|---|---------------|-------------|-------------------|--------------------|
| 2.1 | Today | Search | Search songs by title/artist/tag | TextField live filter |
| 2.2 | Today | Hot wall | Curated popular songs first, Weekly Tone Drops section on top | Vertical scroll grid |
| 4.1 | ToneMatch | Knob confirm-lighting | Suggested values pre-filled; user compares & taps to confirm; each lights with haptic (0.3s stagger) | Tap; haptics; sequential light-up |
| 4.2 | ToneMatch | Dialed In celebration | All knobs lit → indicator breathing glow + confetti + share CTA | Celebration overlay |
| 4.3 | ToneMatch | Confidence badge | Overall confidence % + per-knob badges | Badge chip |
| 4.4 | ToneMatch | Unknown gear guard | Out-of-library gear → "Generic advice" banner with explicit confidence | Banner, never fake numbers |
| 6.1 | GearSnap | 3 capture modes | Headstock / amp panel / pedalboard framing guides | Segmented mode selector + overlay |
| 6.2 | GearSnap | Scan shimmer | Micro-light sweep animation during recognition | Animation, 2–5s |
| 6.3 | GearSnap | Top3 confirm | Candidate cards with brand/model/confidence; tap to confirm; "none → manual pick" escape | Card tap; never a dead end |
| 9.1 | Paywall | Value-first display | GearSnap 5s vs manual 10min comparison shown before purchase prompt | Comparison layout |
| 14.1 | Settings | Pricing transparency | Full price table visible in-app (matches website + store page) | Static page |
| 14.2 | Settings | Legal | Privacy Policy, Terms (EULA), support email links | Safari/sheet links |

### Cross-Feature Dependencies

| Dependency | Source Feature | Target Feature | Data Passed | Trigger Condition |
|------------|---------------|----------------|-------------|-------------------|
| Onboarding → first match | Onboarding | ToneMatch Engine | Completed `Rig` | Rig confirmed |
| GearSnap → Rig | GearSnap | Rig Management | Confirmed `GearItem` | User confirms candidate |
| Rig change → re-adapt | Rig Management | ToneMatch Engine | Updated `Rig` | Any gear edit while recipe open |
| Scene change → re-adapt | Scene re-adaptation | ToneMatch Engine | Scene enum | Scene card tap |
| Quota out → Paywall | Free quota metering | Paywall | Trigger context | matchesToday ≥ 1 or 2nd GearSnap |
| Purchase → unlock | Paywall | GearSnap GLM / A/B / Scenes | Entitlement state | Successful StoreKit transaction |
| Chain Coach → result page | Pedal Chain Coach | ToneMatch result | Ordered chain + warnings | Chain displayed/edited |
| Whisper Notes ← engine | ToneMatch Engine | Whisper Notes | `KnobAdjust.reason` | Any suggestion rendered |
| Share ← Dialed In | ToneMatch result | Share card | Knobs + song + amp model | All knobs confirmed |

**⚠️ VERIFICATION CHECK**: Guide §3.3 MUST items 1–8 map to features 1–9, 13, 14 above; SHOULD items 9–12 map to features 10–12 (implemented in MVP because Pro pricing promises them — App Store Guideline 2.1 completeness). Apple Watch/Widget (SHOULD #12) deferred to month 2, NOT in this build. Count matches: 14 primary features ✅

---

## ⚠️ App Store Compliance — AI Features

### Apple Intelligence (Default Free AI Backend)
- This app uses Apple Intelligence (on-device Foundation Models + Private Cloud Compute) as the free-tier AI backend for GearSnap rough recognition. On supported devices (iPhone 15 Pro+, iOS 26+), works immediately after download with zero configuration. **Min iOS is 26.0 so all devices qualify.**
- **Simulator**: Apple Intelligence is not available on simulators. For testing, configure a BYO API key or use manual fallback path.

### GLM Cloud AI (Pro-tier backend)
- GearSnap model-level recognition + long-tail song generation use **GLM-5.3-Flash** via the **glm-api-config skill standard** (config repo `https://github.com/asunnyboy861/GLM-Cloudflare`): Worker URL primary/backup, appId=`ampwhisper`, userId (Keychain), GLM three behavior rules (thinking.level always sent / max_tokens text≥4096 vision≥8192 / response_format json_object), production uses `jwsRepresentation` from `Transaction.currentEntitlements` (NEVER jsonRepresentation).
- ⚠️ PHASE 4+5 MUST invoke `glm-api-config` skill to register Bundle ID `com.zzoutuo.AmpWhisper` into worker D1 whitelist, inject devKey into gitignored local secret, verify E2E (200/400/401/405).

### BYO API Key (Lifetime tier, $39.99)
- Users configure their own provider: GLM (Z.ai) / OpenAI / Claude / Gemini / DeepSeek / custom OpenAI-compatible endpoint (6 types, per guide §7.6).
- `BYOProviderConfig` (id/baseURL/apiKey in Keychain/textModel/visionModel/enabled); `OpenAICompatibleAdapter` + `AnthropicAdapter` (native `x-api-key`).
- Vision tasks (GearSnap) route ONLY to providers with `visionModel != nil`; explicit message if no enabled provider has vision — never silent failure.
- Keys in Keychain only; connectivity test shows latency/failure reason; BYO bypasses shared worker, no quota limits.

### Guideline 2.1(a) — App Completeness
1. Create `app_review_info.md` with demo configuration instructions
2. NEVER show clickable AI buttons that error when no backend is available — every AI path has a manual fallback that always works
3. Dead code ban: no free-generation counters for AI itself (free quota meters ToneMatch matches, an app feature, not AI generations)

---

## ⚠️ App Store Compliance — Subscriptions

### Guideline 3.1.2(c) — Subscription Information (Paywall MUST contain)
- Functional link to Privacy Policy + Terms of Use (EULA)
- Subscription title, length, price for each tier; auto-renewal disclosure text
- Tiers: Pro Monthly $9.99 / Pro Annual $49.99 with 7-day free trial / BYO Lifetime $39.99 (non-consumable)
- **NO lifetime option on Pro GLM tiers** (consumption cost); lifetime only on BYO tier
- `showManageSubscriptions` embedded in Settings
- Subscription value framing: "Unlock AmpWhisper Pro features" — feature-led, not AI-usage-led

### Pricing transparency (guide §8)
- Same prices shown in 3 places: website, App Store metadata, in-app Paywall
- GLM quota exhaustion degrades gracefully to Apple on-device with explicit "slightly lower precision" notice — features never hard-break

---

## Apple Design Guidelines Compliance

- **Dark-first** (Deep Tolex `#1C1B1A` background) — rehearsal/stage context
- **Amber `#FFB020`** (lit/complete) + Cream `#F5EFE0` (knob markings); skeuomorphic knob caps
- **iOS 26 Liquid Glass** styling; SF Pro body; monospaced numerals for knob values (speedometer feel)
- **Motion**: knobs light sequentially (0.3s each, haptic); all lit → indicator breathing + "Dialed In ✅"; A/B toggle animates knobs smoothly between value sets
- **Information density**: result page = 6 big knobs + 1 chain strip + 1 preview button; everything else collapsed into Whisper Notes
- **Accessibility**: VoiceOver announces knob as "Gain 7 of 10"; Dynamic Type; ≥44pt touch targets

---

## Technical Architecture

- **Language**: Swift 5.9+ (Swift 6 mode compatible)
- **UI**: SwiftUI + custom skeuomorphic knob component (`KnobDial`)
- **Data**: SwiftData (`Rig`, `GearItem`, `ToneRecipe`, `MatchHistory`) + bundled JSON device library (1000+ entries: 50 guitars/100 cabs/60 pedals minimum, with family fields) + external rule tables (JSON, hot-updatable)
- **Deterministic core**: `ToneMatchEngine` (pure functions, 4-level adaptation, guards) + `ChainOrderEngine` (conventional order + exceptions) — **zero AI, zero network**
- **On-device AI**: Foundation Models (Apple Intelligence) — rough recognition
- **Cloud AI**: GLM-5.3-Flash via glm-api-config standard
- **Audio**: NeuralAudio (MIT, C++) via bridging header in isolated `AudioEngine` module; AVAudioEngine dual-track A/B; bundled NAM captures + convolution IRs; MIT attribution in About page
- **Payments**: StoreKit 2 native (guide mentioned RevenueCat; engineering decision per skill standard: StoreKit 2 only, no external account dependency — recorded as override)
- **Sharing**: `UIGraphicsImageRenderer` vertical poster
- **Version**: always read from `Bundle.main.infoDictionary` — never hardcoded

### Adaptation Rule Tables (seed data, guide §7.3 — content asset, JSON external)

| Difference | Conversion | Confidence | Whisper Note |
|---|---|---|---|
| Humbucker → single coil | gain −1, treble +1 | 0.8 | "Single coils are lower output and brighter — trade gain for clarity" |
| Single coil → humbucker | gain +1, treble −1 | 0.8 | "Humbuckers run hotter and darker — add bite back" |
| TS-type → transparent overdrive | gain +1, middle −2 | 0.75 | "The TS mid-hump is gone — let the amp supply mids" |
| Transparent → Fuzz | gain −2, tone +1, chain warning wah-after | 0.6 | "Fuzz wants a cleaner push" |
| Marshall → Fender family | bass +1, middle −1, gain +1 | 0.7 | "Fender mids are scooped — push them back" |
| Closed → open-back cab | presence +1 | 0.65 | "Open-back cabs are looser" |

### Code Rules (guide §7.7 — binding)
1. Adaptation pure-function: `ToneMatchEngine` depends only on inputs; one unit test per rule-table row; rule tables are content assets (JSON external)
2. AI three-nevers: never in adaptation path, never auto-save to library, never output without confidence (<85% → Top3 confirm)
3. Unknown ≠ fake: out-of-library devices output "generic advice" + explicit confidence — never pretend precision
4. Int knob scale everywhere (0–10); no floats in UI values
5. Audio engine isolated in own module with bridging header; MIT attribution in About
6. Trademark compliance: text-only brand/model mentions (nominative fair use); no logo graphics on share cards
7. VoiceOver on all custom controls; Dynamic Type
8. No hardcoded version strings

---

## Module Structure

```
AmpWhisper/
├── AmpWhisperApp.swift           // @main, SwiftData container
├── Models/
│   ├── GearItem.swift            // brand, model, kind, pickupType, pedalFamily, ampFamily, cabBrightness
│   ├── Rig.swift
│   ├── ToneRecipe.swift          // song, artist, baseKnobs, rigSignature, chain, source attribution
│   ├── MatchHistory.swift
│   └── Enums.swift               // GearKind, PickupType, PedalFamily, AmpFamily, Scene
├── Engine/
│   ├── ToneMatchEngine.swift     // pure functions, 4-level, guarded
│   ├── ChainOrderEngine.swift
│   └── RuleTables.json           // external, hot-updatable
├── Resources/
│   ├── DeviceLibrary.json        // 1000+ entries
│   └── Recipes/                  // 300 song recipes JSON
├── Services/
│   ├── AIRouter.swift            // Apple FM ↔ GLM ↔ BYO decision logic
│   ├── GLMService.swift          // glm-api-config standard client
│   ├── BYOProviderConfig.swift / OpenAICompatibleAdapter.swift / AnthropicAdapter.swift
│   ├── EntitlementManager.swift  // StoreKit 2
│   ├── QuotaManager.swift        // free-tier daily counters (UserDefaults)
│   └── ShareCardRenderer.swift
├── AudioEngine/                  // isolated module
│   ├── AudioEngine.swift         // AVAudioEngine A/B dual-track
│   ├── NeuralAudioBridge.h / NeuralAudio C++ sources (MIT)
│   └── NAMCaptures/ + IRs/
├── Views/
│   ├── Onboarding/
│   ├── Today/ (song wall, drops, search)
│   ├── GearSnap/ (camera, 3 modes, Top3 candidates)
│   ├── Match/ (KnobDial result page, chain, notes, celebration)
│   ├── Rig/ (gear lists, scene cards)
│   ├── Paywall/
│   └── Settings/ (pricing, BYO, about, legal)
└── ViewModels/
```

---

## ⚠️ Data Flow Diagram (Every Feature's Data Lifecycle)

```
Feature: ToneMatch (core loop)
┌───────────────────────────────────────────────────────────┐
│  User Input: song tap on Today wall                       │
│       │                                                   │
│  ViewModel: MatchViewModel loads ToneRecipe + Rig         │
│       │                                                   │
│  Engine: ToneMatchEngine.adapt(recipe, rig)  [PURE]       │
│  └── L1 pickup → L2 pedal → L3 cab → L4 amp family        │
│  └── apply deltas → clamp 0–10 → resolve conflicts        │
│  └── ChainOrderEngine.order(pedals) + exception notes     │
│       │                                                   │
│  Persistence: MatchHistory saved (SwiftData)              │
│  Quota: QuotaManager.consumeMatch() (UserDefaults)        │
│       │                                                   │
│  Display: 6 KnobDials + confidence badge + chain strip    │
│       │                                                   │
│  Cross: knob values → AudioEngine (A/B track B);          │
│         Dialed In state → ShareCardRenderer               │
└───────────────────────────────────────────────────────────┘

Feature: GearSnap
Photo capture → JPEG Data → AIRouter (entitlement + quota + network)
  ├─ Pro + GLM ok → GLMService vision (json_object, Top3) ─┐
  ├─ Free → Apple FM rough (counter 5/day) ────────────────┤
  └─ fail → degrade chain: GLM→Apple FM→manual, w/ notice ─┤
                                                           ▼
                            CandidateConfirmView (ALWAYS) → user picks
                                                           │
                                        GearItem saved to SwiftData Rig → engine re-runs
```

**Anti-error principles (code rules)**: 1) AI never enters adaptation path; 2) AI results never auto-save (confirmation UI always); 3) unknown gear → explicit generic advice with confidence, never fake precision; 4) everything re-computable and reversible.

---

## Implementation Flow

1. Project skeleton: SwiftUI + SwiftData, iOS 26.0, Bundle `com.zzoutuo.AmpWhisper` (xcodegen)
2. Models + SwiftData schema; seed device library JSON + 300 recipe JSONs
3. `ToneMatchEngine` + `ChainOrderEngine` + rule tables + full unit tests
4. Onboarding + Rig management UI
5. Today wall + search + recipe browsing
6. Match result page: KnobDial component, lighting interaction, Whisper Notes, celebration, share card
7. GearSnap: camera modes, AIRouter, Apple FM + GLM integration (glm-api-config standard), Top3 confirmation
8. Quota manager + Paywall (StoreKit 2, 3 tiers) + entitlement-gated features
9. A/B preview: AudioEngine module + NeuralAudio C++ bridging + bundled captures
10. Scene tiers, Chain Coach UI, Settings (BYO config, legal, pricing page)
11. Build/test on iPhone + iPad simulators, fix, GitHub push

---

## Build & Deployment Checklist

- [x] us.md complete with feature inventory + data flows
- [ ] PHASE 2: xcodegen project, icon (Agnes primary / Wanx fallback), capabilities (camera usage string, no iCloud/Watch for MVP)
- [ ] PHASE 3: price.md — Free / Pro $9.99 mo / Pro $49.99 yr (7d trial) / BYO $39.99 lifetime; Terms page required
- [ ] PHASE 4+5: full codebase + IAP + contact support + AI modules (glm-api-config + BYO template + compliance validation)
- [ ] PHASE 6: simulator build/test, GitHub push (single repo, /docs for policies)
- [ ] PHASE 7: policy pages to GitHub Pages (privacy, terms, support, landing)
- [ ] PHASE 8: ASO keytext (Title fixed: AmpWhisper; Subtitle: Guitar Tone Matched to You; keywords: amp settings, guitar tone, pedal order, effect chain, tone match, guitar gear, rig, distortion, pedalboard, amp simulator)
- [ ] PHASE 8.5: launch checklist
- [ ] PHASE 8.8: release audit — READY verdict required
- [ ] Store materials: 6 screenshots (Today/GearSnap/Result/Chain Coach/Preview/Pricing) — user handles screenshots; privacy label "Data Not Collected"; age 4+
- [ ] Pre-launch: verify GLM key validity on shared worker (glm-api-config standard)
