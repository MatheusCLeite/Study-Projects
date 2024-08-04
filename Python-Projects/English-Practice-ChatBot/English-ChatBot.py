import os 
import streamlit as st
import sqlite3
from Utils import transcribe, text_speech, PromptRetriever
from audio_recorder_streamlit import audio_recorder

__import__('pysqlite3')
sys.modules['sqlite3'] = sys.modules.pop('pysqlite3')
repo_id = "mistralai/Mixtral-8x7B-Instruct-v0.1"
api_token = st.secrets['HUGGINGFACEHUB_API_TOKEN']
prompt_retriever = PromptRetriever(repo_id, api_token)

st.title("Marvin - Chatbot English Tutor 🤖")

if "messages" not in st.session_state:
    st.session_state.messages = [{"role": "assistant", "content": "Hi! How may I assist you today?"}]
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

with st.sidebar:
    audio_bytes = audio_recorder(
    text="Click and say something!",
    recording_color="#5a83c4",
    neutral_color="#354257",
    icon_name="microphone",
    icon_size="3x",
)

if audio_bytes:
    webm_file_path = "temp_audio.wav"
    with open(webm_file_path, "wb") as f:
        f.write(audio_bytes)

    transcript = transcribe(audio_bytes)
    st.session_state.messages.append({"role": "user", "content": transcript})
    with st.chat_message("user"):
        st.write(transcript)

    with st.chat_message("assistant"):
        with st.spinner("Thinking🤔..."):
            final_response = prompt_retriever.llm_response(transcript)
        with st.spinner("Generating audio response..."):
            audio_file = text_speech(final_response)
            st.audio(audio_file)
        st.write(final_response)
        st.session_state.messages.append({"role": "assistant", "content": final_response})