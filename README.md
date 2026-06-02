# Blitztext App — Offline Fork (Ollama + WhisperKit)

> **This is a fork of [cmagnussen/blitztext-app](https://github.com/cmagnussen/blitztext-app) modified to run 100% offline — no OpenAI API key required.**

Blitztext App is an experimental open-source macOS menubar app for turning speech into text.

Press a hotkey, speak, get text back, optionally rewrite it, and paste it into the app you were using. Everything runs on your machine.

## What Changed From Upstream

| Component | Upstream | This Fork |
|-----------|----------|-----------|
| Transcription | OpenAI Whisper API or WhisperKit | **WhisperKit only (local)** |
| Text rewriting | OpenAI GPT-4o / GPT-4o-mini | **Ollama (`qwen3.5:latest`)** |
| API key required | Yes | **No** |
| Internet required | Yes (online mode) | **No** |

All rewriting workflows (Blitztext+, $%&!, :)) now use `LocalTranscriptionService` for speech-to-text and Ollama's native `/api/chat` endpoint for text generation, with `think: false` to disable reasoning mode for fast responses (~1-5s).

## What It Does

- **Blitztext** (`fn + Shift`): record speech, transcribe locally via WhisperKit.
- **Blitztext+** (`fn + Control`): transcribe + improve text via Ollama.
- **Blitztext $%&!** (`fn + Option`): turn frustrated speech into a calm message via Ollama.
- **Blitztext :)** (`fn + Cmd`): transcribe + add emojis via Ollama.

## Important Notes

- macOS only.
- No OpenAI key needed — everything runs locally.
- Ollama must be running in the background (`open -a Ollama`).
- A WhisperKit CoreML model must be installed (see setup below).
- `./build.sh` creates a locally ad-hoc-signed development app.
- Not production ready. No warranty.

You are welcome to use, fork, adapt, and share this project under the license terms.

The intent is not to ship a one-click finished app. The intent is to make a real AI workflow understandable: clone it, build it, read the code, change it, break it, fix it, and suggest improvements. If you only want to download something and never look inside, this preview will probably feel rough. If you want to learn how a small native macOS AI app is put together, you are in the right place.

## Screenshots

<table>
  <tr>
    <td><img src="docs/screenshots/online-mode.png" alt="Blitztext online transcription mode" width="420"></td>
    <td><img src="docs/screenshots/local-mode.png" alt="Blitztext secure local transcription mode" width="420"></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/local-model-picker.png" alt="Blitztext local model picker" width="420"></td>
    <td><img src="docs/screenshots/settings-customize.png" alt="Blitztext settings and customization view" width="420"></td>
  </tr>
</table>

## Requirements

- macOS 14 or newer
- Xcode 16 or newer, with Command Line Tools installed
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- [Ollama](https://ollama.com) running locally with at least one LLM model
- A WhisperKit CoreML model (installed via the app or manually, see below)

The build pulls one Swift Package dependency automatically:

- [`argmax-oss-swift`](https://github.com/argmaxinc/argmax-oss-swift) (WhisperKit)

## Setup

### 1. Build and install

```bash
git clone https://github.com/albecabrera/blitztext-app.git
cd blitztext-app
./build.sh --install --run
```

### 2. Install Ollama and pull a model

```bash
# Install from https://ollama.com or via brew
brew install ollama
ollama pull qwen3.5:latest   # or any other model you prefer
```

Open Ollama so it runs in the background before using Blitztext.

### 3. Install a WhisperKit model

**Option A — from the app:** Settings → Anpassen → enable **Sicherer Lokaler Modus** → click install.

**Option B — via CLI:**

```bash
pip install "huggingface_hub[cli]"
mkdir -p "$HOME/Library/Application Support/Blitztext/models/whisperkit"
python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='argmaxinc/whisperkit-coreml',
    allow_patterns=['openai_whisper-small_216MB/*'],
    local_dir='$HOME/Library/Application Support/Blitztext/models/whisperkit'
)
"
```

Expected layout:

```text
~/Library/Application Support/Blitztext/models/whisperkit/
  openai_whisper-small_216MB/
    AudioEncoder.mlmodelc
    MelSpectrogram.mlmodelc
    TextDecoder.mlmodelc
```

### 4. Enable local mode

Settings → Anpassen → toggle **Sicherer Lokaler Modus** ON.

### 5. Grant permissions

- **Microphone**: required to record your voice.
- **Accessibility**: required to auto-paste results. Open System Settings → Privacy → Accessibility → enable Blitztext.

### Changing the Ollama model

Edit `BlitztextMac/Services/LLMService.swift`, line 1:

```swift
private let ollamaModel = "qwen3.5:latest"  // change to any ollama model name
```

Then rebuild: `./build.sh --install`

## Permissions

Blitztext asks for:

- **Microphone**: to record your voice.
- **Accessibility**: to paste the result back into the app you were using.

If you do not grant Accessibility permission, you can still copy results manually.

## Data Flow

Everything stays on your machine. No data leaves your Mac.

```text
Transcription:  Your Mac -> WhisperKit/CoreML (on device)
Text rewriting: Your Mac -> Ollama (localhost:11434)
```

## Project Structure

```text
BlitztextMac/
  App/          App lifecycle and paste handling
  Features/     Workflows, menu bar UI, settings
  Services/     Recording, Ollama calls, WhisperKit, hotkeys, local storage
  Views/        Shared SwiftUI views
build.sh        Local build script
docs/           Setup, privacy, roadmap notes
```

## Contributing

Contributions are welcome, especially if they make the preview easier to build, understand, or fork.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## Support And Roadmap

This preview has no formal support promise. See [SUPPORT.md](SUPPORT.md) for how to ask for help without sharing secrets.

The current direction is documented in [ROADMAP.md](ROADMAP.md). Maintainer-facing release checks live in [docs/open-source-preflight.md](docs/open-source-preflight.md).

## License

Code is released under the MIT License. See [LICENSE](LICENSE).

Project names, logos, and app icons are not automatically granted as trademarks or brand assets. See [TRADEMARKS.md](TRADEMARKS.md).

## Legal / Impressum & Datenschutz

This is an experimental, non-commercial open-source project, provided as-is under the MIT License without warranty or support. Nothing is sold here and no installation or operation is performed on your behalf.

The companion website (blitztext.de) is operated by Blackboat Internet GmbH:

- Impressum: https://www.blackboat.com/impressum
- Datenschutz / Privacy: https://www.blackboat.com/datenschutz
