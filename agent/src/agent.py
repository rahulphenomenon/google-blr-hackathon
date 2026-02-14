import logging

from dotenv import load_dotenv
from livekit import agents
from livekit.agents import AgentSession, Agent, AgentServer
from livekit.plugins import google, sarvam

load_dotenv(".env.local")
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
        )

    async def on_enter(self):
        await self.session.generate_reply(
            instructions="Greet the user warmly in Malayalam, then briefly in English. Introduce yourself as their Malayalam tutor."
        )


server = AgentServer()


@server.rtc_session()
async def entrypoint(ctx: agents.JobContext):
    logger.info(f"User connected to room: {ctx.room.name}")
    session = AgentSession(
        stt=sarvam.STT(
            language="unknown",
            model="saaras:v3",
            flush_signal=True,
        ),
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
            logger.info(f"[STT] User said: {ev.transcript}")

    @session.on("agent_state_changed")
    def on_agent_state(ev):
        logger.info(f"[Agent] {ev.old_state} → {ev.new_state}")

    @session.on("conversation_item_added")
    def on_conversation_item(ev):
        msg = ev.item
        if hasattr(msg, "role") and hasattr(msg, "text_content"):
            text = msg.text_content()
            if text:
                logger.info(f"[{msg.role.upper()}] {text}")

    await session.start(agent=MalayalamTutor(), room=ctx.room)


if __name__ == "__main__":
    agents.cli.run_app(server)
