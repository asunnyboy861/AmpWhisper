# Pricing Configuration

## Monetization Model: Subscription (IAP) + Non-Consumable BYO Buyout

Free tier with 1 full ToneMatch per day; auto-renewable Pro subscriptions (monthly/annual) unlock unlimited matches and Pro features; a separate non-consumable "BYO Lifetime" buyout routes AI through the user's own API keys. Per guide §8: Pro GLM tiers NEVER offer lifetime (cloud consumption cost); BYO tier has no marginal cost so lifetime is allowed.

## Subscription Group
- **Group Name**: AmpWhisper Pro
- **Reference Name**: AmpWhisper Pro
- **Products in group**: AmpWhisper Pro Monthly, AmpWhisper Pro Annual (auto-renewable only; the non-consumable BYO Lifetime is NOT in this group)

## Subscription Tiers (Auto-Renewable)

### 1. Monthly Subscription
- **Reference Name**: AmpWhisper Pro Monthly
- **Product ID**: `com.zzoutuo.AmpWhisper.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $9.99 USD per month
- **Display Name**: `AmpWhisper Pro Monthly` (22 chars, ≤35 ✅)
- **Description**: `Unlimited tone matches, GearSnap and A/B preview` (48 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: AmpWhisper Pro
- **Restore Purchases**: ✅ Required

### 2. Yearly Subscription (Primary)
- **Reference Name**: AmpWhisper Pro Annual
- **Product ID**: `com.zzoutuo.AmpWhisper.pro.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $49.99 USD per year (58% savings vs monthly)
- **Display Name**: `AmpWhisper Pro Annual` (21 chars, ≤35 ✅)
- **Description**: `All Pro features with a 7-day free trial` (40 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: AmpWhisper Pro (same group as monthly)
- **Restore Purchases**: ✅ Required

## One-Time Purchases (Non-Consumable)

### 1. BYO Lifetime
- **Reference Name**: AmpWhisper BYO Lifetime
- **Product ID**: `com.zzoutuo.AmpWhisper.byo.lifetime`
- **Type**: Non-consumable (one-time purchase, permanently unlocked)
- **Price**: $39.99 USD (one-time)
- **Display Name**: `AmpWhisper BYO Lifetime` (23 chars, ≤35 ✅)
- **Description**: `One-time unlock; AI runs on your own API key` (44 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Differentiation Note**: BYO Lifetime unlocks the same core Pro feature set (unlimited ToneMatch, A/B preview, scene tiers) but AI features (GearSnap recognition, long-tail generation) run exclusively through the user's own configured provider keys (GLM/OpenAI/Claude/Gemini/DeepSeek/custom OpenAI-compatible). It does NOT include the shared GLM cloud quota that Pro subscriptions provide — users must supply their own key in Settings. Pro subscriptions do NOT offer lifetime (shared GLM consumption cost).

## Free Tier (Default)
- **Price**: Free
- **Features**:
  - Browse the full song recipe library (300 songs at launch + Weekly Tone Drops)
  - 1 full ToneMatch per day (local counting, no account)
  - Pedal Chain Coach ordering + exception hints
  - Whisper Notes on the daily match
  - Apple on-device rough gear recognition: 5/day
  - GLM model-level recognition: 1 free trial
  - Share card generation
- **Conversion hooks**:
  - "GearSnap recognizes your amp in about 5 seconds — typing it by hand takes 10 minutes."
  - "Hear the target tone before you turn a single knob."
  - "One full match every day, free forever."

## Pro Features Unlocked (All Paid Tiers)

Cross-referenced with capabilities.md (camera ✅, photo library ✅, StoreKit 2 ✅ — all implemented in MVP; no iCloud/Watch listed).

| Feature | Free | Pro (Monthly/Annual) | BYO Lifetime |
|---------|:----:|:--------------------:|:------------:|
| Browse song library + Weekly Tone Drops | ✅ | ✅ | ✅ |
| Full ToneMatch | 1/day | ✅ Unlimited | ✅ Unlimited |
| Pedal Chain Coach | ✅ | ✅ | ✅ |
| Whisper Notes | Daily match only | ✅ Full unlock | ✅ Full unlock |
| Share card | ✅ | ✅ | ✅ |
| GearSnap Apple on-device rough recognition | 5/day | ✅ Unlimited | ✅ Unlimited |
| GearSnap GLM model-level recognition | 1 trial | ✅ Unlimited (shared GLM) | ❌ BYO key only (user's provider) |
| A/B Preview (NeuralAudio) | ❌ | ✅ Full library | ✅ Full library |
| Scene tiers (Bedroom/Rehearsal/Gig) | ❌ | ✅ | ✅ |
| BYO multi-provider AI config | ❌ | ❌ | ✅ |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to paid subscription)
- **Available for**: Pro Annual ($49.99/yr) only

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription apps must have Terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView (same prices shown on website + App Store metadata)
- [x] Free trial terms included (7-day trial on Pro Annual)
- [x] Restore purchases functionality implemented
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options (no competitor price comparisons in paywall copy)
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] IAP type purity: non-consumable BYO Lifetime listed separately from auto-renewable group
- [x] No lifetime option on GLM-consuming Pro tiers (BYO tier only)
- [x] GLM quota exhaustion degrades gracefully to Apple on-device with explicit notice — features never hard-break
- [x] Subscription value framing is feature-led ("Unlock AmpWhisper Pro features"), never "unlimited AI generations"
