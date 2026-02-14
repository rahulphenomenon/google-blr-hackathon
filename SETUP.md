# tota POC Setup Guide

Step-by-step instructions to get the Malayalam language tutor running end-to-end.

## Prerequisites

- Python 3.10+ with [uv](https://docs.astral.sh/uv/getting-started/installation/) installed
- Xcode 26+ with iOS 26 SDK
- A Mac with a microphone (or an iOS device/simulator)

## 1. Get API Keys

You need accounts and API keys from three services:

### LiveKit Cloud

1. Sign up at https://cloud.livekit.io/
2. Create a new project
3. Go to **Settings > Keys** and copy:
   - `LIVEKIT_URL` (looks like `wss://your-project.livekit.cloud`)
   - `LIVEKIT_API_KEY` (looks like `APIxxxxxxxx`)
   - `LIVEKIT_API_SECRET` (long random string)
4. Go to **Sandbox** in the left sidebar, enable the **Token Server** template, and copy the **Sandbox ID** (looks like `sandbox-xxxxxxxx`)

### Sarvam AI

1. Sign up at https://www.sarvam.ai/
2. Go to https://dashboard.sarvam.ai/key-management
3. Create an API key and copy it

### Google Gemini

1. Go to https://aistudio.google.com/apikey
2. Create a key (free tier gives 15 requests per minute for Flash models)

## 2. Configure Environment Files

### Python agent (`agent/.env.local`)

```bash
cp agent/.env.example agent/.env.local
```

Edit `agent/.env.local` and fill in your keys:

```
LIVEKIT_URL=wss://your-project.livekit.cloud
LIVEKIT_API_KEY=APIxxxxxxxx
LIVEKIT_API_SECRET=your-api-secret
SARVAM_API_KEY=your-sarvam-key
GOOGLE_API_KEY=your-gemini-key
```

### iOS app (`tota/tota/.env.xcconfig`)

Edit `tota/tota/.env.xcconfig` and fill in your Sandbox ID:

```
LIVEKIT_SANDBOX_ID = sandbox-xxxxxxxx
```

## 3. Install Python Dependencies

```bash
cd agent
uv sync
```

## 4. Download Model Files

```bash
uv run python src/agent.py download-files
```

## 5. Test the Agent (Terminal Only)

Run in console mode to test without the iOS app:

```bash
uv run python src/agent.py console
```

Speak into your microphone. The agent should respond in Malayalam. Press `Ctrl+C` to stop.

## 6. Run the Agent for iOS

Start the agent in dev mode so the iOS app can connect:

```bash
uv run python src/agent.py dev
```

Leave this running in a terminal.

## 7. Build and Run the iOS App

1. Open `tota/tota.xcodeproj` in Xcode
2. Select an iPhone simulator or your device
3. Build and run (`Cmd+R`)
4. Tap "Start Conversation" and speak

## Verification Checklist

- [ ] Agent responds in Malayalam when you speak English
- [ ] Agent responds in Malayalam when you speak Malayalam
- [ ] Both user and agent speech appear in the transcript view
- [ ] Speaking while the agent is talking interrupts it (barge-in)
- [ ] The agent greets you automatically when the session starts

## Troubleshooting

**Agent fails to start**: Check that all 5 env vars in `agent/.env.local` are set correctly.

**iOS app shows "Disconnected"**: Make sure the agent is running with `dev` and the Sandbox ID in `.env.xcconfig` matches your LiveKit project.

**No audio on simulator**: The iOS simulator has limited mic support. Test on a real device for best results.

**Sarvam errors**: Verify your Sarvam API key is active at https://dashboard.sarvam.ai/key-management.
