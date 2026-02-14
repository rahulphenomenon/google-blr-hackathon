import logging

# Silence all noisy logs before any LiveKit imports
logging.getLogger("livekit").setLevel(logging.ERROR)
logging.getLogger("google_genai").setLevel(logging.ERROR)
logging.getLogger("httpcore").setLevel(logging.ERROR)
logging.getLogger("httpx").setLevel(logging.ERROR)
logging.getLogger("asyncio").setLevel(logging.ERROR)

from dotenv import load_dotenv
from livekit import agents
from livekit.agents import AgentSession, Agent, AgentServer
from livekit.plugins import google, sarvam

load_dotenv(".env.local")

logger = logging.getLogger("tota")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter("%(message)s"))
logger.addHandler(handler)
logger.propagate = False

# --- Language / Scenario / Voice config ---

LANGUAGE_NAMES = {
    "ml-IN": "Malayalam",
    "kn-IN": "Kannada",
    "hi-IN": "Hindi",
    "ta-IN": "Tamil",
    "te-IN": "Telugu",
}

SCENARIO_PROMPTS = {
    "basics": "Focus on basic phrases: greetings (hello, goodbye, how are you), thank you, please, yes, no, numbers 1-10, and essential everyday words. Teach one phrase at a time.",
    "free": "",
    "restaurant": "The conversation takes place at a restaurant. Focus on food ordering, menu items, and polite requests.",
    "directions": "The conversation is about asking for directions. Focus on direction words, landmarks, and transport.",
    "shopping": "The conversation takes place at a market. Focus on prices, bargaining, numbers, and common goods.",
    "introductions": "The conversation is about meeting someone new. Focus on greetings, names, where you're from, and occupations.",
}


# --- Sarvam STT patch for saaras:v3 verbatim mode ---
# The released plugin (1.4.x) doesn't support mode= or saaras:v3.
# This patch adds the mode param to the websocket URL.

def _patch_sarvam_stt_for_mode(mode: str = "verbatim") -> None:
    import livekit.plugins.sarvam.stt as sarvam_stt

    _original_build_url = sarvam_stt._build_websocket_url

    def _patched_build_url(base_url, opts):
        url = _original_build_url(base_url, opts)
        if opts.model == "saaras:v3":
            url += f"&mode={mode}"
        return url

    sarvam_stt._build_websocket_url = _patched_build_url


_patch_sarvam_stt_for_mode("verbatim")


def _make_stt() -> sarvam.STT:
    """Create Sarvam STT with saaras:v3 in verbatim mode."""
    stt = sarvam.STT(
        language="unknown",
        model="saaras:v3",
        flush_signal=True,
    )
    # Force the transcription endpoint (not translate)
    stt._opts.streaming_url = "wss://api.sarvam.ai/speech-to-text/ws"
    stt._opts.base_url = "https://api.sarvam.ai/speech-to-text"
    return stt


# --- Agent ---

class LanguageTutor(Agent):
    def __init__(self, language="ml-IN", scenario="free", voice="kavya"):
        lang_name = LANGUAGE_NAMES.get(language, "Malayalam")
        scenario_context = SCENARIO_PROMPTS.get(scenario, "")

        super().__init__(
            instructions=f"""You are a friendly {lang_name} language tutor. Your student is an English speaker learning {lang_name}.

Rules:
- ALWAYS write {lang_name} words in {lang_name} script, NEVER in Latin/English transliteration
- You can mix English and {lang_name} in your responses. Use English for explanations and {lang_name} script for the {lang_name} parts
- When the student speaks in English, teach them the {lang_name} equivalent using {lang_name} script
- When the student speaks in {lang_name}, acknowledge it, correct mistakes gently, and continue
- If the student asks for help, explain in English and give the {lang_name} in {lang_name} script
- Keep responses short (1-2 sentences) for natural conversation flow
- Be encouraging and patient
- Do not use emojis, asterisks, or markdown formatting
{f"\nScenario: {scenario_context}" if scenario_context else ""}""",
        )
        self._lang_name = lang_name

    async def on_enter(self):
        await self.session.generate_reply(
            instructions=f"Greet the user warmly in {self._lang_name}, then briefly in English. Introduce yourself as their {self._lang_name} tutor."
        )


server = AgentServer()


@server.rtc_session()
async def entrypoint(ctx: agents.JobContext):
    await ctx.connect()
    participant = await ctx.wait_for_participant()

    language = participant.attributes.get("language", "ml-IN")
    scenario = participant.attributes.get("scenario", "free")
    voice = participant.attributes.get("voice", "kavya")

    logger.info(f"[CONFIG] language={language} scenario={scenario} voice={voice}")

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

    @session.on("user_input_transcribed")
    def on_transcript(ev):
        if ev.is_final:
            logger.info(f"[STT ] {ev.transcript}")

    @session.on("conversation_item_added")
    def on_conversation_item(ev):
        msg = ev.item
        try:
            role = getattr(msg, "role", None)
            text = getattr(msg, "text_content", None)
            if role and text:
                label = "USER" if role == "user" else "LLM "
                logger.info(f"[{label}] {text}")
        except Exception:
            pass

    await session.start(
        agent=LanguageTutor(language=language, scenario=scenario, voice=voice),
        room=ctx.room,
    )


if __name__ == "__main__":
    agents.cli.run_app(server)
