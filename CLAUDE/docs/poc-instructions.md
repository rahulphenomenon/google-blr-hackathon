# poc instructions

i want to start with the poc. before you implement it let us spec it out so we are on the same page. this is my rough idea of what it should be. feel free to ask me clarifying questions, challenge assumptions, or push back if my ideas are not great. i need the result to be excellent

for the poc i think we should use livekit’s swift template. use gemini and sarvam ai as the models. let me know if there is anything i need to do outside the codebase to get this working. i can run it locally for now, but i want to understand the right way to run this in the cloud (or we could directly run it in the cloud if that is easier depending on the docs). use gemini 3 flash preview as the llm and sarvam for the stt and tts. i have attached the resources you should use as the source of truth. 

- https://github.com/livekit-examples/agent-starter-swift
- [https://docs.sarvam.ai/api-reference-docs/integration/build-voice-agent-with-live-kit](https://docs.sarvam.ai/api-reference-docs/integration/build-voice-agent-with-live-kit)
- https://docs.sarvam.ai/api-reference-docs/getting-started/models/bulbul
- [https://docs.livekit.io/agents/models/stt/plugins/sarvam/](https://docs.livekit.io/agents/models/stt/plugins/sarvam/)
- [https://docs.livekit.io/agents/models/llm/plugins/gemini/](https://docs.livekit.io/agents/models/llm/plugins/gemini/)