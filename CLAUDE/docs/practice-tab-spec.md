# Practice Tab — Implementation Spec

## Overview

The Practice tab lets users choose a language to learn, pick a conversation scenario, select a voice, and have a real-time voice conversation with an AI tutor. This is the first production feature built on top of the working POC.

---

## Current State (what exists)

### Working POC agent (`agent/src/agent.py`)
- Uses `AgentServer` + `@server.rtc_session()` (LiveKit v1.4 pattern)
- Pipeline: Sarvam STT (`saaras:v3`, verbatim mode) → Gemini LLM (`gemini-3-flash-preview`) → Sarvam TTS (`bulbul:v3`, speaker `kavya`)
- `turn_detection="stt"` with `min_endpointing_delay=0.07`
- Hardcoded to Malayalam only
- Sarvam STT needs monkey-patch for `mode` and endpoint override (plugin hasn't released `mode=` param yet)
- Console logging via `user_input_transcribed` and `conversation_item_added` session events

### Working POC iOS app (`tota/tota/POC/`)
- `POCView.swift` — start screen → connected session
- `POCAgentView.swift` — `BarAudioVisualizer` showing agent state
- `POCTranscriptView.swift` — `ChatScrollView` with user/agent bubbles
- `POCControlBar.swift` — mic toggle + end call
- `POCConfig.swift` — reads `LiveKitSandboxId` from Info.plist
- `totaApp.swift` — creates `Session` with `SandboxTokenSource`, injects as `@EnvironmentObject`
- Uses LiveKit (`client-sdk-swift`) and LiveKitComponents (`components-swift`) SPM packages

### Key config files
- `agent/.env.local` — LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET, SARVAM_API_KEY, GOOGLE_API_KEY
- `tota/tota/.env.xcconfig` — LIVEKIT_SANDBOX_ID
- `tota/tota/tota.xcconfig` — `#include ".env.xcconfig"`
- `tota/tota/Info.plist` — NSMicrophoneUsageDescription, UIBackgroundModes (audio), LiveKitSandboxId

---

## What to Build

### Supported Languages

| Language | Sarvam STT language code | Sarvam TTS target_language_code | Script example |
|----------|--------------------------|----------------------------------|----------------|
| Malayalam | `ml-IN` (or `unknown`) | `ml-IN` | മലയാളം |
| Kannada | `kn-IN` (or `unknown`) | `kn-IN` | ಕನ್ನಡ |
| Hindi | `hi-IN` (or `unknown`) | `hi-IN` | हिन्दी |
| Tamil | `ta-IN` (or `unknown`) | `ta-IN` | தமிழ் |
| Telugu | `te-IN` (or `unknown`) | `te-IN` | తెలుగు |

Use `language="unknown"` for STT so Sarvam auto-detects (user may speak English or the target language).

### Available TTS Voices (bulbul:v3)

**Female:** kavya, ritu, pooja, simran, ishita, shreya, priya, neha, roopa, amelia, sophia

**Male:** shubh, rahul, amit, ratan, rohan, dev, manan, sumit, aditya, kabir, varun, aayan, ashutosh, advait

Recommend offering 3-4 voices initially: kavya (female), priya (female), rohan (male), aditya (male).

### Scenario Presets

| Scenario | Description | System prompt context |
|----------|-------------|----------------------|
| Free conversation | Open-ended chat | General tutor instructions |
| At a restaurant | Ordering food, asking for menu | Restaurant vocabulary, food items, polite requests |
| Asking for directions | Getting around a city | Direction words, landmarks, transport |
| Shopping at a market | Bargaining, asking prices | Numbers, prices, common goods |
| Meeting someone new | Introductions, small talk | Greetings, name, where from, occupation |
| At the doctor | Describing symptoms | Body parts, feelings, common ailments |
| Custom | User describes their scenario | User's description injected into system prompt |

---

## Architecture

### How the iOS app talks to the agent

```
iOS app                          LiveKit Cloud                    Python agent
────────                         ─────────────                    ────────────
1. User picks language,
   scenario, voice
2. Sets participant
   attributes:
   {
     "language": "ml-IN",
     "scenario": "restaurant",
     "voice": "kavya"
   }
3. session.start()  ──────────►  creates room  ──────────────►  entrypoint(ctx)
                                                                 reads participant
                                                                 attributes
                                                                 configures STT/LLM/TTS
                                                                 accordingly
```

**Key mechanism: participant attributes.** The iOS app sets attributes on the local participant before/when connecting. The Python agent reads these in the entrypoint to configure the session dynamically.

### LiveKit participant attributes (iOS side)

LiveKitComponents' `Session` wraps the LiveKit Room. When using `SandboxTokenSource`, participant attributes can be set via the token request. Alternatively, after connecting, use:

```swift
try await session.room.localParticipant.setAttributes([
    "language": "ml-IN",
    "scenario": "restaurant",
    "voice": "kavya"
])
```

However, since the agent needs these BEFORE it starts the AgentSession, the cleaner approach is to pass them as **room metadata** or via the **sandbox token request body**. Check `SandboxTokenSource` API for passing metadata.

**Simpler alternative if attribute timing is tricky:** encode the settings in the room name or use a fixed set of agent configurations dispatched by agent_name. For the hackathon, the simplest approach may be to have the iOS app send a text message via LiveKit data channel right after connecting, and have the agent wait for it before starting the session.

### Recommended approach for hackathon

Use **participant attributes** set in the token. The `SandboxTokenSource` supports passing attributes. The agent reads them with:

```python
@server.rtc_session()
async def entrypoint(ctx: agents.JobContext):
    await ctx.connect()
    participant = await ctx.wait_for_participant()

    language = participant.attributes.get("language", "ml-IN")
    scenario = participant.attributes.get("scenario", "free")
    voice = participant.attributes.get("voice", "kavya")

    # Configure session based on these values
    session = AgentSession(
        stt=_make_stt(),
        llm=google.LLM(model="gemini-3-flash-preview"),
        tts=sarvam.TTS(
            target_language_code=language,
            model="bulbul:v3",
            speaker=voice,
        ),
        turn_detection="stt",
        min_endpointing_delay=0.07,
    )

    agent = LanguageTutor(language=language, scenario=scenario)
    await session.start(agent=agent, room=ctx.room)
```

---

## Implementation Plan

### Step 1: Refactor the Python agent for multi-language support

**File: `agent/src/agent.py`**

Replace the hardcoded `MalayalamTutor` with a configurable `LanguageTutor`:

```python
LANGUAGE_NAMES = {
    "ml-IN": "Malayalam",
    "kn-IN": "Kannada",
    "hi-IN": "Hindi",
    "ta-IN": "Tamil",
    "te-IN": "Telugu",
}

SCENARIO_PROMPTS = {
    "free": "",
    "restaurant": "The conversation takes place at a restaurant. Focus on food ordering vocabulary, menu items, and polite requests.",
    "directions": "The conversation is about asking for and giving directions. Focus on direction words, landmarks, and transport.",
    "shopping": "The conversation takes place at a market. Focus on prices, bargaining, numbers, and common goods.",
    "introductions": "The conversation is about meeting someone new. Focus on greetings, names, where you're from, and occupations.",
    "doctor": "The conversation takes place at a doctor's office. Focus on body parts, symptoms, and describing how you feel.",
}

class LanguageTutor(Agent):
    def __init__(self, language: str = "ml-IN", scenario: str = "free") -> None:
        lang_name = LANGUAGE_NAMES.get(language, "Malayalam")
        scenario_context = SCENARIO_PROMPTS.get(scenario, "")

        super().__init__(
            instructions=f"""You are a friendly {lang_name} language tutor. Your student is an English speaker learning {lang_name}.

Rules:
- ALWAYS write {lang_name} words in {lang_name} script, NEVER in Latin/English transliteration
- You can mix English and {lang_name} in your responses. Use English for explanations and {lang_name} script for the {lang_name} parts
- When the student speaks in English, teach them the {lang_name} equivalent
- When the student speaks in {lang_name}, acknowledge it, correct mistakes gently, and continue
- If the student asks for help, explain in English and give the {lang_name} in native script
- Keep responses short (1-2 sentences) for natural conversation flow
- Be encouraging and patient
- Do not use emojis, asterisks, or markdown formatting
{f"Scenario context: {scenario_context}" if scenario_context else ""}""",
        )
        self._lang_name = lang_name

    async def on_enter(self):
        await self.session.generate_reply(
            instructions=f"Greet the user warmly in {self._lang_name}, then briefly in English. Introduce yourself as their {self._lang_name} tutor."
        )
```

The entrypoint reads participant attributes and configures the agent dynamically. The `_make_stt()` function and Sarvam patch remain unchanged.

### Step 2: Build the Practice tab UI (iOS)

All new files go under `tota/tota/Practice/`. The POC files remain under `tota/tota/POC/` as reference.

#### File structure

```
tota/tota/Practice/
├── PracticeTab.swift           # Tab root — shows setup or active session
├── PracticeSetupView.swift     # Language, scenario, voice picker
├── PracticeSessionView.swift   # Active conversation (reuses POC patterns)
├── PracticeAgentView.swift     # Audio visualizer (similar to POCAgentView)
├── PracticeTranscriptView.swift # Chat bubbles (similar to POCTranscriptView)
├── PracticeControlBar.swift    # Mic, end, translate buttons
└── PracticeModels.swift        # Language, Scenario, Voice data models
```

#### `PracticeModels.swift`

```swift
import Foundation

struct Language: Identifiable, Hashable {
    let id: String          // "ml-IN"
    let name: String        // "malayalam"
    let nativeName: String  // "മലയാളം"
}

struct Scenario: Identifiable, Hashable {
    let id: String          // "restaurant"
    let name: String        // "at a restaurant"
    let icon: String        // SF Symbol name
    let description: String
}

struct Voice: Identifiable, Hashable {
    let id: String          // "kavya"
    let name: String        // "kavya"
    let gender: String      // "female"
}

enum PracticeData {
    static let languages: [Language] = [
        Language(id: "ml-IN", name: "malayalam", nativeName: "മലയാളം"),
        Language(id: "kn-IN", name: "kannada", nativeName: "ಕನ್ನಡ"),
        Language(id: "hi-IN", name: "hindi", nativeName: "हिन्दी"),
        Language(id: "ta-IN", name: "tamil", nativeName: "தமிழ்"),
        Language(id: "te-IN", name: "telugu", nativeName: "తెలుగు"),
    ]

    static let scenarios: [Scenario] = [
        Scenario(id: "free", name: "free conversation", icon: "bubble.left.and.bubble.right", description: "open-ended practice"),
        Scenario(id: "restaurant", name: "at a restaurant", icon: "fork.knife", description: "ordering food, asking for the menu"),
        Scenario(id: "directions", name: "asking for directions", icon: "map", description: "getting around a city"),
        Scenario(id: "shopping", name: "shopping at a market", icon: "bag", description: "bargaining, asking prices"),
        Scenario(id: "introductions", name: "meeting someone new", icon: "person.2", description: "introductions and small talk"),
        Scenario(id: "doctor", name: "at the doctor", icon: "stethoscope", description: "describing symptoms"),
    ]

    static let voices: [Voice] = [
        Voice(id: "kavya", name: "kavya", gender: "female"),
        Voice(id: "priya", name: "priya", gender: "female"),
        Voice(id: "rohan", name: "rohan", gender: "male"),
        Voice(id: "aditya", name: "aditya", gender: "male"),
    ]
}
```

#### `PracticeSetupView.swift`

A single scrollable screen with three sections:
1. **Language picker** — horizontal scroll of language cards, each showing native script name
2. **Scenario picker** — grid of scenario cards with icons
3. **Voice picker** — simple segmented or chip selector
4. **Start button** — large, bottom-anchored

Design: minimalist, lowercase text throughout, use brand color for selections.

When "start" is tapped:
1. Store selections
2. Create/configure the `Session` with participant attributes
3. Navigate to `PracticeSessionView`

#### `PracticeSessionView.swift`

Reuse the exact same layout as `POCView` (connected state):
- `PracticeAgentView` (visualizer) at top
- `PracticeTranscriptView` (chat bubbles) in middle
- `PracticeControlBar` at bottom

These are nearly identical to the POC versions. The only differences:
- `PracticeControlBar` may add a "translate" button that shows English translation of the last agent message
- Back button to return to setup (ends session)

#### `PracticeTab.swift`

```swift
struct PracticeTab: View {
    @State private var isInSession = false
    @State private var selectedLanguage: Language = PracticeData.languages[0]
    @State private var selectedScenario: Scenario = PracticeData.scenarios[0]
    @State private var selectedVoice: Voice = PracticeData.voices[0]

    var body: some View {
        if isInSession {
            PracticeSessionView(onEnd: { isInSession = false })
        } else {
            PracticeSetupView(
                language: $selectedLanguage,
                scenario: $selectedScenario,
                voice: $selectedVoice,
                onStart: { isInSession = true }
            )
        }
    }
}
```

### Step 3: Modify `totaApp.swift` for tab-based navigation

Replace the current POCView-only setup with a `TabView`. For now, only the Practice tab is functional:

```swift
@main
struct totaApp: App {
    // Session will be created dynamically based on practice settings

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("practice", systemImage: "mic.fill") {
                    PracticeTab()
                }
                Tab("learn", systemImage: "book.fill") {
                    Text("coming soon")
                }
                Tab("today", systemImage: "calendar") {
                    Text("coming soon")
                }
                Tab("stats", systemImage: "chart.bar.fill") {
                    Text("coming soon")
                }
            }
        }
    }
}
```

**Important:** The `Session` and `LocalMedia` objects need to be created when the user starts a practice session (not at app launch), because the participant attributes depend on the user's language/scenario/voice selection. Either:
- Create `Session` in `PracticeTab` when starting, passing attributes
- Or create a wrapper that manages the LiveKit session lifecycle

### Step 4: Session management with participant attributes

The key challenge is passing the user's selections (language, scenario, voice) to the Python agent. Here's how:

**Option A: Participant attributes via token request (cleanest)**

Check if `SandboxTokenSource` supports passing participant attributes in the token request body. If so:

```swift
let tokenSource = SandboxTokenSource(
    id: POCConfig.sandboxID,
    // Pass attributes in token request if supported
)
```

**Option B: Set attributes after connecting, agent waits**

```swift
// iOS: after session.start()
try await session.room.localParticipant.setAttributes([
    "language": selectedLanguage.id,
    "scenario": selectedScenario.id,
    "voice": selectedVoice.id,
])
```

```python
# Agent: wait for attributes
participant = await ctx.wait_for_participant()

# Poll until attributes are set (they may arrive after connection)
import asyncio
for _ in range(50):  # 5 second timeout
    language = participant.attributes.get("language")
    if language:
        break
    await asyncio.sleep(0.1)
```

**Option B is recommended for the hackathon** — it's simpler and doesn't require investigating SandboxTokenSource internals.

---

## Design Guidelines

From initial instructions:
- Lowercase text everywhere
- Minimalistic with consistent design language
- Use native iOS components (SwiftUI)
- Brand color for accents (set in Assets.xcassets)
- No emojis in UI text
- Snappy, performant feel

---

## File Changes Summary

### New files
| Path | Description |
|------|-------------|
| `tota/tota/Practice/PracticeModels.swift` | Language, Scenario, Voice data models |
| `tota/tota/Practice/PracticeTab.swift` | Tab root — setup vs active session |
| `tota/tota/Practice/PracticeSetupView.swift` | Picker UI for language, scenario, voice |
| `tota/tota/Practice/PracticeSessionView.swift` | Active voice session (similar to POCView) |
| `tota/tota/Practice/PracticeAgentView.swift` | Audio visualizer |
| `tota/tota/Practice/PracticeTranscriptView.swift` | Chat transcript bubbles |
| `tota/tota/Practice/PracticeControlBar.swift` | Session controls |

### Modified files
| Path | Change |
|------|--------|
| `agent/src/agent.py` | Replace `MalayalamTutor` with configurable `LanguageTutor`, read participant attributes |
| `tota/tota/totaApp.swift` | Switch from POCView to TabView with PracticeTab |

### No changes needed
| Path | Reason |
|------|--------|
| `tota/tota/POC/*` | Keep as reference, don't delete |
| `agent/pyproject.toml` | Dependencies unchanged |
| `tota/tota/Info.plist` | Already has mic permission and sandbox ID |

---

## Caveats & Gotchas from POC

1. **Sarvam STT `mode` param not released yet** — the monkey-patch in `_patch_sarvam_stt_for_mode()` and endpoint override in `_make_stt()` must be kept until livekit-plugins-sarvam releases mode support. Do not remove these.

2. **Sarvam TTS model name** — `bulbul:v3` works but the plugin's type literal only lists `bulbul:v2` and `bulbul:v3-beta`. Pass as string, ignore the "Unknown model" warning.

3. **LLM must output native script** — the system prompt MUST instruct Gemini to write in native script (e.g. മലയാളം) not transliteration (e.g. "namaskaram"). Otherwise TTS produces garbled output.

4. **`--log-level ERROR`** — always pass this flag when running the agent to suppress noise. The custom `tota` logger handles useful output.

5. **Python 3.13** — use Python 3.13 (not 3.14) for the agent. The `dev` mode has an event loop issue on 3.14 despite v1.4 claiming support.

6. **`text_content` is a property** — on `ChatMessage`, access `msg.text_content` not `msg.text_content()`. It's a string property, not a method.

7. **iOS deployment target** — iOS 26, Xcode 26.2. All SwiftUI code should use latest APIs.
