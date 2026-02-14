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


class MalayalamTutor(Agent):
    def __init__(self) -> None:
        super().__init__(
            instructions="""You are a friendly Malayalam language tutor. Your student is an English speaker learning Malayalam.

Rules:
- ALWAYS write Malayalam words in Malayalam script (e.g. നമസ്കാരം), NEVER in Latin/English transliteration (e.g. never write "namaskaram")
- You can mix English and Malayalam in your responses. Use English for explanations and Malayalam script for the Malayalam parts
- Example good response: "Very good! നിങ്ങൾ നന്നായി പറഞ്ഞു means you said it well"
- Example bad response: "Very good! Ningal nannaayi paranju means you said it well"
- When the student speaks in English, teach them the Malayalam equivalent using Malayalam script
- When the student speaks in Malayalam, acknowledge it, correct mistakes gently, and continue
- If the student asks for help, explain in English and give the Malayalam in Malayalam script
- Keep responses short (1-2 sentences) for natural conversation flow
- Be encouraging and patient
- Do not use emojis, asterisks, or markdown formatting""",
        )

    async def on_enter(self):
        await self.session.generate_reply(
            instructions="Greet the user warmly in Malayalam, then briefly in English. Introduce yourself as their Malayalam tutor."
        )


def _patch_sarvam_stt_for_mode(mode: str = "verbatim") -> None:
    """Patch the Sarvam STT plugin to support mode= on saaras:v3.

    The released plugin routes saaras:v3 to the translate endpoint and
    doesn't pass a mode parameter. This patches the URL builder to use
    the transcription endpoint with the specified mode.
    """
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


server = AgentServer()


@server.rtc_session()
async def entrypoint(ctx: agents.JobContext):
    session = AgentSession(
        stt=_make_stt(),
        llm=google.LLM(
            model="gemini-3-flash-preview",
        ),
        tts=sarvam.TTS(
            target_language_code="ml-IN",
            model="bulbul:v3",
            speaker="kavya",
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

    await session.start(agent=MalayalamTutor(), room=ctx.room)


if __name__ == "__main__":
    agents.cli.run_app(server)
