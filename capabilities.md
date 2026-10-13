# AmpWhisper — 配置文档

生成时间：2026-10-13

---

## 一、⚠️ 手动配置（不配置则对应功能无法上线）

> **重要说明**：App 核心功能（音色匹配引擎、设备库、链序教练、每日免费匹配、客服反馈）已全部自动配置，下载即可用。以下是你**必须手动完成**的上架前配置。

### 🔵 IAP StoreKit 配置（App Store Connect 创建产品）

**影响功能**：不创建 IAP 产品，用户无法完成订阅/买断购买，Paywall 会显示"购买选项暂不可用"。

**已自动配置部分**：
- ✅ `PurchaseManager.swift` 已实现 StoreKit 2，Product ID 与 price.md 完全一致
- ✅ Paywall/Settings 已含 Restore Purchases 与 Manage Subscription（showManageSubscriptions）
- ✅ 免费层本地计数（QuotaManager）不依赖 IAP

**手动配置步骤**：
1. 打开 [App Store Connect](https://appstoreconnect.apple.com) → 我的 App → **AmpWhisper**（需先在 ASC 创建 App 记录，Bundle ID 选 `com.zzoutuo.AmpWhisper`）
2. 左侧 **Features → In-App Purchases → "+"** 创建订阅组 **AmpWhisper Pro**
3. 按下表创建 2 个自动续期订阅 + 1 个非消耗型：

| 产品 | Reference Name | Product ID | 类型 | 价格 |
|------|---------------|-----------|------|------|
| 月订阅 | AmpWhisper Pro Monthly | `com.zzoutuo.AmpWhisper.pro.monthly` | Auto-Renewable | $9.99/月 |
| 年订阅 | AmpWhisper Pro Annual | `com.zzoutuo.AmpWhisper.pro.yearly` | Auto-Renewable | $49.99/年 |
| BYO 买断 | AmpWhisper BYO Lifetime | `com.zzoutuo.AmpWhisper.byo.lifetime` | Non-Consumable | $39.99 一次性 |

4. Display Name / Description（≤35/≤55 字符，从 `price.md` 原样复制）：
   - Monthly: `AmpWhisper Pro Monthly` / `Unlimited tone matches, GearSnap and A/B preview`
   - Annual: `AmpWhisper Pro Annual` / `All Pro features with a 7-day free trial`（并在订阅组为年订阅设置 **7 天免费试用** 引荐优惠）
   - Lifetime: `AmpWhisper BYO Lifetime` / `One-time unlock; AI runs on your own API key`
5. ⚠️ 年订阅试用设置：订阅组 → Yearly → **Offer Type: Free Trial → 7 Days**
6. ⚠️ 年订阅需在 App Store Connect 的 **Subscription → Review Notes / EULA** 关联 Terms：https://asunnyboy861.github.io/AmpWhisper/terms.html
7. 本地测试：Xcode → File → New → File → StoreKit Configuration File，按上表添加 3 个产品后可在模拟器验证购买流
8. ⚠️ 禁止给 Pro 月/年订阅提供终身买断（含 GLM 云成本）；终身买断仅限 BYO 档

### 🟢 App Store Connect 审核信息配置

**影响功能**：不配置则审核员无法测试购买与 AI 识别（Guideline 2.1(a) 拒审风险）。

**配置步骤**：
1. ASC → AmpWhisper → **App Review Information**
2. **Notes** 字段：粘贴项目根目录 `app_review_info.md` 的 "Review Notes" 全部内容（含混合 AI 路由说明、中国区合规声明、订阅测试产品 ID）
3. **Privacy Policy URL**：https://asunnyboy861.github.io/AmpWhisper/privacy.html
4. **Support URL**：https://asunnyboy861.github.io/AmpWhisper/support.html
5. **Marketing URL**：https://asunnyboy861.github.io/AmpWhisper/
6. ⚠️ EULA：可使用标准 Apple EULA，或在 Custom EULA 填 Terms 链接内容
7. 上架后（拿到 Apple ID 数字）更新 `docs/index.html` 中的 `[APP_STORE_ID]` 为真实 ID，下载按钮自动变为可用链接

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| Camera | NSCameraUsageDescription 已配置（GearSnap 拍照） | ✅ 已配置 |
| Photo Library | NSPhotoLibraryUsageDescription 已配置（相册选图识别） | ✅ 已配置 |
| In-App Purchase | StoreKit 2 无需 entitlement 文件 | ✅ 已配置 |
| Outgoing Network Connections | 客服反馈 + GLM 云识别需要，HTTPS 默认放行 | ✅ 已配置 |
| PrivacyInfo.xcprivacy | UserDefaults CA92.1 + FileTimestamp C617.1，无追踪无收集 | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | https://msg.calcs.top/api/feedback（Cloudflare Workers），POST 5 字段 | ✅ 已部署并接入 |
| GLM 云识别共享 Worker | appId=`ampwhisper`，Bundle ID 已注册 D1 白名单，E2E 200/400/401/405 全通过 | ✅ 已配置 |
| GLM 密钥文件 | GLMProxySecret.txt 已 gitignore + Release 构建排除（已实测 Release 产物无此文件），生产走 StoreKit JWS 通道 | ✅ 已配置 |
| 政策页 | Landing/Support/Privacy/Terms 四页 GitHub Pages 已上线 | ✅ 已部署 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | 确定性 ToneMatch 四级引擎 + 链序教练 + 场景三档 + 分享卡，11/11 单测通过 | ✅ 已完成 |
| 数据资产 | 279 条真实设备库 + 544 首真实歌曲配方 + 规则表 JSON（可热更） | ✅ 已完成 |
| ContactSupportView | 7 主题磁贴、必填校验、隐私微copy、成功/失败反馈 | ✅ 已完成 |
| PurchaseManager | StoreKit 2 反应式绑定（$isPro.assign）+ currentEntitlement(for:) | ✅ 已完成 |
| AI 模块 | BYO 六供应商适配器 + Apple 端侧 OCR + GLM 云识别 + Keychain 存储 | ✅ 已完成 |
| 合规验证 | ios-custom-ai-config 13 项全 PASS；glm-api-config 验收全通过 | ✅ 已完成 |
| QA 迭代 | Step 11：9 issues 修复，improvement_plan_1.md，iPad+iPhone 构建通过 | ✅ 已完成 |

### 💡 使用提示（非开发者配置，App 内操作即可）

**AI 识别**：免费层默认走 Apple 端侧识别（每天 5 次）+ 1 次云识别体验；Pro 用户自动走共享云识别。BYO 买断用户在 **Settings → Configure Your Own AI Provider** 输入自己的 Key（GLM/OpenAI/Claude/Gemini/DeepSeek/自定义），Key 存 Keychain。均为用户操作，无需开发者配置。

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/AmpWhisper | ✅ 已推送 |
| GitHub Pages | 4 页已上线（built） | ✅ 已部署 |
| App Store 元数据 | keytext.md 全部验证通过（关键词 100/100） | ✅ 已生成 |
| 定价配置 | price.md 三档 + 免费 | ✅ 已生成 |

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据，人工配置项已重组到 Section 一。

### Analysis

基于操作指南与 us.md 关键词检测：
- "拍照/相机/拍一张"（GearSnap）→ Camera usage description
- 相册兜底选图 → Photo Library usage description
- "订阅/买断/IAP"（§8 四档定价）→ StoreKit 2
- 麦克风：MVP 无录音对比 → 不需要
- iCloud / Watch / 推送 / App Groups / HealthKit / 定位 / Siri：指南未要求 → 不配置

### No Configuration Needed

- iCloud/CloudKit — 本地 SwiftData 优先
- Apple Watch — 指南 month-2 范围，本次构建不含
- Push / App Groups / Background Modes / HealthKit / Location / Siri — 指南无要求
- 麦克风 — A/B 试听仅播放内置合成音频

### Verification

- 构建验证：✅ iPhone 18 Pro Max (iOS 27) + iPad Pro 13" (M5) BUILD SUCCEEDED
- 签名验证：✅ generic/platform=iOS（Apple Development: he zhou, VX3Q75X27B），DEVELOPMENT_TEAM=JP4TN5PTS3 项目级
- 单元测试：✅ 11/11 通过
- 隐私清单：✅ App target 覆盖
