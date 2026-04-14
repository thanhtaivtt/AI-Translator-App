<p align="center">
  <img src="assets/aitranslator.png" alt="AI Translator" width="128" height="128" style="border-radius: 22px;">
</p>

<h1 align="center">AI Translator</h1>

<p align="center">
  <strong>A native macOS translation app powered by LLMs</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2015.4+-blue?style=flat-square&logo=apple" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.0-orange?style=flat-square&logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-✓-blue?style=flat-square" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Dependencies-Zero-green?style=flat-square" alt="No Dependencies">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" alt="License">
</p>

<p align="center">
  Translate text instantly using AI language models. Built with SwiftUI, zero external dependencies, and a plugin architecture that makes adding new AI providers effortless.
</p>

---

## ✨ Features

- 🌐 **AI-Powered Translation** — Leverages LLMs (OpenAI GPT-4o, GPT-4.1, etc.) for high-quality, context-aware translations
- ⚡ **Real-time Streaming** — See translations appear word-by-word as the AI generates them
- 🔌 **Extensible Provider System** — Add new AI providers (Google Gemini, Anthropic Claude, etc.) with just one file
- 📋 **Tab-based Interface** — Clean 3-tab layout: Translate, History, Settings
- 🕐 **Translation History** — All translations saved locally with search and detail view (SwiftData)
- 🔐 **Secure API Key Storage** — Keys stored in macOS Keychain, never in plain text
- 🌍 **12+ Languages** — Vietnamese, English, Japanese, Korean, Chinese, French, German, Spanish, Thai, Portuguese, Russian, Italian
- ⌨️ **Keyboard Shortcuts** — `⌘↵` to translate instantly
- 🎨 **Native macOS Design** — Follows Apple Human Interface Guidelines with dark/light mode support
- 📦 **Zero Dependencies** — No SPM packages, no CocoaPods, no Carthage. Pure Apple frameworks only.

## 🖥️ Screenshots

> _Run the app and add your screenshots here_

## 📋 Requirements

- **macOS** 15.4 or later
- **Xcode** 16.3 or later
- **OpenAI API Key** ([Get one here](https://platform.openai.com/api-keys))

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/thanhtaivtt/AI-Translator-App.git
cd AI-Translator-App
```

### 2. Open in Xcode

```bash
open AITranslator.xcodeproj
```

### 3. Build & Run

Press `⌘R` in Xcode, or:

```bash
xcodebuild -project AITranslator.xcodeproj -scheme AITranslator -configuration Debug build
```

### 4. Configure API Key

1. Go to the **Settings** tab
2. Enter your OpenAI API key
3. Click **Save** — the key is stored securely in your Mac's Keychain
4. Switch to the **Translate** tab and start translating!

## 🏗️ Architecture

```
AITranslator/
├── Models/                     # Data models
│   ├── Language.swift          # Supported languages enum
│   ├── LLMModel.swift          # AI model representation
│   ├── AppSettings.swift       # Settings & defaults
│   └── TranslationRecord.swift # SwiftData history model
│
├── Protocols/
│   └── LLMProvider.swift       # ⭐ Core provider protocol
│
├── Providers/                  # AI provider implementations
│   ├── ProviderRegistry.swift  # Provider management
│   └── OpenAI/
│       ├── OpenAIProvider.swift # OpenAI Chat Completions + SSE
│       └── OpenAIModels.swift  # API request/response models
│
├── Services/
│   ├── TranslationService.swift # Translation orchestration
│   ├── SettingsManager.swift    # UserDefaults + Keychain
│   └── HistoryStore.swift       # SwiftData persistence
│
├── ViewModels/                 # MVVM ViewModels
│   ├── TranslationViewModel.swift
│   ├── HistoryViewModel.swift
│   └── SettingsViewModel.swift
│
├── Views/
│   ├── TranslateView.swift     # Split-panel translation UI
│   ├── HistoryView.swift       # History list + detail
│   ├── SettingsView.swift      # App configuration
│   └── Components/
│       ├── LanguagePicker.swift
│       └── TranslationCard.swift
│
├── Extensions/
│   └── Color+Theme.swift       # Color palette & view modifiers
│
├── AITranslatorApp.swift       # App entry point
└── ContentView.swift           # Root TabView
```

### Design Principles

| Principle | Implementation |
|-----------|---------------|
| **Protocol-Oriented** | `LLMProvider` protocol defines the contract for all AI providers |
| **MVVM** | Clean separation between Views, ViewModels, and Services |
| **Dependency Injection** | All dependencies injected via initializers |
| **Zero Dependencies** | URLSession for networking, Security framework for Keychain, SwiftData for persistence |
| **Observable** | Swift Observation framework (`@Observable`) for reactive UI |

## 🔌 Adding a New Provider

Adding support for a new AI provider (e.g., Google Gemini) requires only **2 steps**:

### Step 1: Create the provider

```swift
// Providers/Gemini/GeminiProvider.swift
final class GeminiProvider: LLMProvider {
    let id = "gemini"
    let displayName = "Google Gemini"
    let requiresAPIKey = true
    
    func translate(text: String, from: Language, to: Language, 
                   model: String, customPrompt: String?) async throws -> String {
        // Your implementation
    }
    
    func translateStream(text: String, from: Language, to: Language,
                         model: String, customPrompt: String?) -> AsyncThrowingStream<String, Error> {
        // Your streaming implementation
    }
    
    func availableModels() -> [LLMModel] {
        [LLMModel(id: "gemini-pro", name: "Gemini Pro", providerId: id)]
    }
}
```

### Step 2: Register it

```swift
// In ProviderRegistry.swift → registerDefaults()
func registerDefaults(settingsManager: SettingsManager) {
    register(OpenAIProvider(settingsManager: settingsManager))
    register(GeminiProvider(settingsManager: settingsManager))  // ← Add this line
}
```

That's it! The UI automatically picks up the new provider in Settings.

## 🌍 Supported Languages

| Language | Code | Flag |
|----------|------|------|
| Auto Detect | `auto` | 🔍 |
| Tiếng Việt | `vi` | 🇻🇳 |
| English | `en` | 🇺🇸 |
| 日本語 | `ja` | 🇯🇵 |
| 한국어 | `ko` | 🇰🇷 |
| 中文 | `zh` | 🇨🇳 |
| Français | `fr` | 🇫🇷 |
| Deutsch | `de` | 🇩🇪 |
| Español | `es` | 🇪🇸 |
| ไทย | `th` | 🇹🇭 |
| Português | `pt` | 🇧🇷 |
| Русский | `ru` | 🇷🇺 |
| Italiano | `it` | 🇮🇹 |

## ⚙️ Settings

| Setting | Description | Default |
|---------|-------------|---------|
| **Provider** | AI service to use | OpenAI |
| **Model** | Specific model | gpt-4o-mini |
| **Translation Mode** | Auto (on typing) or Manual (button) | Manual |
| **Auto-translate Delay** | Debounce delay for auto mode | 0.8s |
| **Default Source Language** | Initial source language | Auto Detect |
| **Default Target Language** | Initial target language | Vietnamese |
| **Custom System Prompt** | Override the translation prompt | (built-in) |

## 🔒 Security

- **API keys** are stored in the macOS **Keychain** via the Security framework
- The app runs in an **App Sandbox** with only `network.client` entitlement
- No data is sent anywhere except to the configured AI provider's API
- All translation history is stored **locally** on your machine using SwiftData

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| UI Framework | SwiftUI |
| Persistence | SwiftData |
| Networking | URLSession (native) |
| Streaming | Server-Sent Events (SSE) parser |
| Security | Keychain (Security framework) |
| Reactivity | Swift Observation (@Observable) |
| Settings | UserDefaults |
| Min Target | macOS 15.4 |

## 🤝 Contributing

Contributions are welcome! Here are some ideas:

- [ ] Add **Google Gemini** provider
- [ ] Add **Anthropic Claude** provider
- [ ] Add **local Ollama** provider (offline translation)
- [ ] Add **global keyboard shortcut** for quick translation
- [ ] Add **menu bar** integration
- [ ] Add **file translation** (drag & drop documents)
- [ ] Add **text-to-speech** for translated text
- [ ] Localize the app UI

### Development

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/gemini-provider`)
3. Commit your changes (`git commit -m 'Add Gemini provider'`)
4. Push to the branch (`git push origin feature/gemini-provider`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## 👤 Author

**TaiVT** — [@thanhtaivtt](https://github.com/thanhtaivtt)

---

<p align="center">
  Made with ❤️ and Swift
</p>
