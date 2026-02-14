# POC spec: livekit + sarvam + gemini 
## goal

validate the real-time voice pipeline end-to-end. user speaks (english or malayalam) into the ios app, sarvam stt transcribes, gemini generates a malayalam language-tutor response (text), sarvam tts speaks it back.

## architecture

```
┌─────────────────────┐         ┌──────────────────┐         ┌─────────────────────────┐
│  ios app (tota)     │ WebRTC  │  livekit cloud    │  jobs   │  python agent (local)   │
│                     │◄───────►│  (SFU server)     │◄───────►│                         │
│  - mic capture      │         │  - routes audio   │         │  - sarvam stt (saaras:v3)│
│  - audio playback   │         │  - manages rooms  │         │  - gemini 3 flash llm   │
│  - transcript ui    │         │                   │         │  - sarvam tts (bulbul:v3)│
│  - agent visualizer │         │                   │         │                         │
└─────────────────────┘         └──────────────────┘         └─────────────────────────┘
```

the ios client is a thin ui layer. all ai processing (stt → llm → tts) happens server-side in the python agent. livekit sdk handles all complexity.

---

## 1. python agent (`agent/`)

### `agent/src/agent.py`

```python
import logging

from dotenv import load_dotenv
from livekit.agents import JobContext, WorkerOptions, cli
from livekit.agents.voice import Agent, AgentSession
from livekit.plugins import google, sarvam

load_dotenv()
logger = logging.getLogger("tota-agent")
logger.setLevel(logging.INFO)


class MalayalamTutor(Agent):
    def __init__(self) -> None:
        super().__init__(
            instructions="""You are a friendly Malayalam language tutor. Your student is an English speaker learning Malayalam.

Rules:
- Speak primarily in Malayalam, using simple sentences appropriate for a beginner
- When the student speaks in English, respond in Malayalam with a translation
- When the student speaks in Malayalam, acknowledge what they said, correct any mistakes gently, and continue the conversation
- If the student asks for help or says they don't understand, explain briefly in English, then repeat in Malayalam
- Keep responses short (1-2 sentences) for natural conversation flow
- Be encouraging and patient
- Do not use emojis, asterisks, or markdown formatting""",
            stt=sarvam.STT(
                language="unknown",
                model="saaras:v3",
                mode="transcribe",
            ),
            llm=google.LLM(
                model="gemini-3-flash-preview",
            ),
            tts=sarvam.TTS(
                target_language_code="ml-IN",
                model="bulbul:v3",
                speaker="kavitha",
            ),
        )

    async def on_enter(self):
        self.session.generate_reply()


async def entrypoint(ctx: JobContext):
    logger.info(f"User connected to room: {ctx.room.name}")
    session = AgentSession(
        turn_detection="stt",
        min_endpointing_delay=0.07,
    )
    await session.start(agent=MalayalamTutor(), room=ctx.room)


if __name__ == "__main__":
    cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint))
```

**key decisions from sarvam docs:**
- `language="unknown"` — auto-detects english/malayalam
- `turn_detection="stt"` — delegates endpointing to sarvam (do NOT pass VAD)
- `min_endpointing_delay=0.07` — 70ms, recommended for sarvam latency
- `speaker="kavitha"` — female voice, south indian name. alternatives: priya, kavya, shruti
- `on_enter` calls `generate_reply()` so agent greets user first

### `agent/pyproject.toml`

```toml
[project]
name = "tota-agent"
version = "0.1.0"
requires-python = ">=3.10, <3.14"
dependencies = [
    "livekit-agents[sarvam,google]~=1.3",
    "python-dotenv",
]
```

### `agent/.env.example`

```
LIVEKIT_URL=wss://your-project.livekit.cloud
LIVEKIT_API_KEY=APIxxxxxxxx
LIVEKIT_API_SECRET=xxxxxxxxxxxxxxxxxxxx
SARVAM_API_KEY=your-sarvam-api-key
GOOGLE_API_KEY=your-gemini-api-key
```

### run commands

```bash
cd agent
uv sync                              # install deps
uv run python src/agent.py dev       # connect to livekit cloud, wait for participants
uv run python src/agent.py console   # test locally with mic/speaker (no ios app needed)
```

---

## 2. ios client (tota xcode project)

### spm dependencies to add

| package | url | version |
|---------|-----|---------|
| LiveKit | `https://github.com/livekit/client-sdk-swift` | 2.12.0+ |
| LiveKitComponents | `https://github.com/livekit/components-swift` | 0.1.6+ |

### info.plist additions

```xml
<key>NSMicrophoneUsageDescription</key>
<string>tota needs your microphone to practice speaking</string>
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
<key>LiveKitSandboxId</key>
<string>$(LIVEKIT_SANDBOX_ID)</string>
```

### xcconfig for secrets

**`tota/tota/.env.xcconfig`** (gitignored):
```
LIVEKIT_SANDBOX_ID=sandbox-xxxxxxxx
```

**`tota/tota/tota.xcconfig`**:
```
#include ".env.xcconfig"
```

the xcconfig is referenced as the base configuration in the xcode project build settings.

### new files under `tota/tota/POC/`

#### `POCConfig.swift`

```swift
import Foundation

enum POCConfig {
    static let sandboxID = Bundle.main.object(forInfoDictionaryKey: "LiveKitSandboxId") as? String ?? ""
}
```

#### `POCView.swift` — root poc screen

```swift
import LiveKit
import LiveKitComponents
import SwiftUI

struct POCView: View {
    @EnvironmentObject private var session: Session
    @EnvironmentObject private var localMedia: LocalMedia

    var body: some View {
        ZStack {
            if session.isConnected {
                VStack(spacing: 0) {
                    POCAgentView()
                    POCTranscriptView()
                    POCControlBar()
                }
            } else {
                startView()
            }
        }
        .background(Color(.systemBackground))
    }

    private func startView() -> some View {
        VStack(spacing: 24) {
            Text("tota")
                .font(.largeTitle.weight(.bold))
            Text("malayalam language tutor")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            AsyncButton {
                await session.start()
            } label: {
                Text("start conversation")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            } busyLabel: {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
    }
}
```

#### `POCAgentView.swift` — agent audio visualizer

```swift
import LiveKit
import LiveKitComponents
import SwiftUI

struct POCAgentView: View {
    @EnvironmentObject private var session: Session

    var body: some View {
        VStack(spacing: 12) {
            if let audioTrack = session.agent.audioTrack {
                BarAudioVisualizer(
                    audioTrack: audioTrack,
                    agentState: session.agent.agentState ?? .listening,
                    barCount: 5,
                    barSpacingFactor: 0.05,
                    barMinOpacity: 0.1
                )
                .frame(maxWidth: 300, maxHeight: 120)
            } else {
                BarAudioVisualizer(
                    audioTrack: nil,
                    agentState: .listening,
                    barCount: 5,
                    barMinOpacity: 0.1
                )
                .frame(maxWidth: 300, maxHeight: 120)
            }

            if let state = session.agent.agentState {
                Text(stateLabel(state))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func stateLabel(_ state: AgentState) -> String {
        switch state {
        case .listening: "listening..."
        case .thinking: "thinking..."
        case .speaking: "speaking..."
        default: ""
        }
    }
}
```

#### `POCTranscriptView.swift` — scrollable transcript

```swift
import LiveKitComponents
import SwiftUI

struct POCTranscriptView: View {
    @EnvironmentObject private var session: Session

    var body: some View {
        ChatScrollView { message in
            switch message.content {
            case let .userTranscript(text), let .userInput(text):
                userBubble(text)
            case let .agentTranscript(text):
                agentBubble(text)
            }
        }
        .padding(.horizontal)
    }

    private func userBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 60)
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                .padding(12)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func agentBubble(_ text: String) -> some View {
        HStack {
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer(minLength: 60)
        }
    }
}
```

#### `POCControlBar.swift` — mic toggle + disconnect

```swift
import LiveKit
import LiveKitComponents
import SwiftUI

struct POCControlBar: View {
    @EnvironmentObject private var session: Session
    @EnvironmentObject private var localMedia: LocalMedia

    var body: some View {
        HStack(spacing: 32) {
            Button {
                Task { await localMedia.toggleMicrophone() }
            } label: {
                Image(systemName: localMedia.isMicrophoneEnabled ? "microphone.fill" : "microphone.slash.fill")
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }

            Button {
                Task {
                    await session.end()
                    session.restoreMessageHistory([])
                }
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.red)
                    .clipShape(Circle())
            }
        }
        .padding()
        .padding(.bottom, 8)
    }
}
```

### modified files

#### `totaApp.swift` — inject session + localMedia

```swift
import LiveKit
import LiveKitComponents
import SwiftUI

@main
struct totaApp: App {
    private let session = Session(
        tokenSource: SandboxTokenSource(id: POCConfig.sandboxID).cached()
    )

    var body: some Scene {
        WindowGroup {
            POCView()
                .environmentObject(session)
                .environmentObject(LocalMedia(session: session))
        }
    }
}
```

#### `ContentView.swift` — unused during poc, keep as-is

---

## 3. setup steps (manual, outside codebase)

### step 1: livekit cloud
1. sign up at https://cloud.livekit.io/
2. create a project
3. copy `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`

### step 2: enable sandbox token server
1. livekit cloud → sandbox → token server template
2. enable it, copy the sandbox ID

### step 3: sarvam api key
1. sign up at https://www.sarvam.ai/
2. get api key from https://dashboard.sarvam.ai/key-management

### step 4: gemini api key
1. go to https://aistudio.google.com/apikey
2. create a key (free tier: 15 rpm for flash)

### step 5: python tooling
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh   # install uv
```

### step 6: configure secrets
```bash
# python agent
cp agent/.env.example agent/.env
# fill in LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET, SARVAM_API_KEY, GOOGLE_API_KEY

# ios app
echo 'LIVEKIT_SANDBOX_ID="your-sandbox-id"' > tota/tota/.env.xcconfig
```

---

## 4. file changes summary

### new files
| path | description |
|------|-------------|
| `agent/src/agent.py` | python voice agent |
| `agent/pyproject.toml` | python deps |
| `agent/.env.example` | api key template |
| `tota/tota/POC/POCView.swift` | root poc screen |
| `tota/tota/POC/POCAgentView.swift` | agent audio visualizer |
| `tota/tota/POC/POCControlBar.swift` | mic toggle + disconnect |
| `tota/tota/POC/POCTranscriptView.swift` | live transcript |
| `tota/tota/POC/POCConfig.swift` | livekit connection config |
| `tota/tota/.env.xcconfig` | sandbox id (gitignored) |
| `tota/tota/tota.xcconfig` | includes .env.xcconfig |

### modified files
| path | change |
|------|--------|
| `tota/tota/totaApp.swift` | inject Session + LocalMedia, route to POCView |
| `tota/tota.xcodeproj/project.pbxproj` | add SPM deps (livekit sdk + components) |
| `tota/tota/Info.plist` | mic permission, background audio, sandbox id |
| `.gitignore` | add `.env.xcconfig` |

---

## 5. verification

1. **agent standalone**: `uv run python src/agent.py console` — speak into mic, agent responds in malayalam
2. **ios → agent**: run agent with `dev`, launch ios app on simulator, tap start, speak — hear malayalam tutor response
3. **transcript**: both user speech and agent speech appear in transcript view
4. **interruption**: speak while agent is talking — agent stops and listens
5. **language detection**: speak english → agent responds in malayalam. speak malayalam → agent corrects/continues

---

## 6. open questions

| question | recommendation |
|----------|----------------|
| tts voice choice? | "kavitha" (female, south indian). alternatives: priya, kavya, shruti. can test during poc |
| should agent greet first? | yes — `on_enter` calls `generate_reply()` so agent says hello in malayalam |
| xcconfig vs hardcoded sandbox id? | xcconfig (matches livekit starter template pattern, keeps secrets out of git) |
| do we need the info.plist file or can we use build settings? | need explicit Info.plist for `LiveKitSandboxId` variable substitution and `UIBackgroundModes` |

# References
- https://github.com/livekit-examples/agent-starter-swift
- https://docs.sarvam.ai/api-reference-docs/integration/build-voice-agent-with-live-kit