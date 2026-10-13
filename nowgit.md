# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | AmpWhisper |
| **Git URL** | git@github.com:asunnyboy861/AmpWhisper.git |
| **Repo URL** | https://github.com/asunnyboy861/AmpWhisper |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/AmpWhisper/ | ✅ Active |
| Support | https://asunnyboy861.github.io/AmpWhisper/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/AmpWhisper/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/AmpWhisper/terms.html | ✅ Active |

## Repository Structure

```
AmpWhisper/
├── AmpWhisper.xcodeproj/          # Xcode Project (xcodegen)
├── AmpWhisper/                    # Swift Source Files
│   ├── Models/                    # GearItem, Rig, ToneRecipe, MatchHistory (SwiftData)
│   ├── Engine/                    # ToneMatchEngine + ChainOrderEngine (pure functions)
│   ├── Services/                  # GLMService, BYO adapters, PurchaseManager, QuotaManager
│   ├── AudioEngine/               # A/B preview (isolated module)
│   ├── Views/                     # Today, Match, Rig, GearSnap, Paywall, Settings
│   ├── Resources/                 # DeviceLibrary.json (279), Recipes.json (544), RuleTables.json
│   └── AmpWhisperApp.swift
├── AmpWhisperTests/               # Engine unit tests (Swift Testing)
├── docs/                          # Policy Pages (GitHub Pages source) — added in PHASE 7
├── .github/workflows/deploy.yml   # Pages deployment — added in PHASE 7
├── project.yml                    # xcodegen source of truth
├── us.md                          # English development guide
├── capabilities.md                # Capability configuration record
├── icon.md                        # App icon generation record
├── price.md                       # Pricing configuration
├── app_review_info.md             # ⚠️ EXCLUDED from repo (.gitignore — review notes)
├── nowgit.md                      # This file
├── keytext.md                     # ⚠️ EXCLUDED from repo (.gitignore — confidential ASO strategy)
└── GLMProxySecret.txt             # ⚠️ EXCLUDED from repo (.gitignore + Release exclusion — dev key)
```
