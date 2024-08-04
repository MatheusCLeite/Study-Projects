import langchain
from langchain.chains import create_history_aware_retriever, create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_chroma import Chroma
from langchain_community.chat_message_histories import ChatMessageHistory
from langchain_community.document_loaders import WebBaseLoader
from langchain_core.chat_history import BaseChatMessageHistory
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.runnables.history import RunnableWithMessageHistory
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain import FewShotPromptTemplate
from langchain_core.prompts import FewShotChatMessagePromptTemplate
from langchain_core.prompts import PromptTemplate
from langchain_community.llms import HuggingFaceEndpoint
import streamlit as st
import re
import os 
import bs4

__import__('pysqlite3')
sys.modules['sqlite3'] = sys.modules.pop('pysqlite3')

os.environ['HUGGINGFACEHUB_API_TOKEN'] = st.secrets['HUGGINGFACEHUB_API_TOKEN']
api_token = st.secrets['HUGGINGFACEHUB_API_TOKEN']

 #Speech Transcription

transcriber = HuggingFaceEndpoint(
    repo_id="openai/whisper-tiny", token = api_token)

def transcribe(audio):
    
    transcription = transcriber.client.automatic_speech_recognition(audio)

    return transcription["text"]


#Language Model Query 

repo_id = "mistralai/Mixtral-8x7B-Instruct-v0.1"

class PromptRetriever:
    def __init__(self, repo_id, api_token):
        # Initialize the LLM
        self.llm = HuggingFaceEndpoint(
            repo_id=repo_id, 
            max_new_tokens=70, 
            temperature=0.9, 
            top_k=20, 
            repetition_penalty=1.1, 
            stop_sequences=["\nHuman:","\nSystem: ","\nSystem:","\nUser"], 
            token=api_token
        )

        # Load the documents
        self.loader = WebBaseLoader(
            web_paths=("https://lilianweng.github.io/posts/2023-06-23-agent/",),
            bs_kwargs=dict(
                parse_only=bs4.SoupStrainer(
                    class_=("post-content", "post-title", "post-header")
                )
            ),
        )
        docs = self.loader.load()

        # Split the documents
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=100, chunk_overlap=100)
        splits = text_splitter.split_documents(docs)
        
        # Create a vectorstore and retriever
        vectorstore = Chroma.from_documents(documents=splits, embedding=HuggingFaceEmbeddings())
        retriever = vectorstore.as_retriever()

        # Define the system prompt
        contextualize_q_system_prompt = (
            "Given a chat history and the latest user question "
            "which might reference context in the chat history, "
            "formulate a standalone question which can be understood "
            "without the chat history. "
        )

        # Define the prompt template
        contextualize_q_prompt = ChatPromptTemplate.from_messages(
            [
                ("system", contextualize_q_system_prompt),
                MessagesPlaceholder("chat_history"),
                ("user", "{input}")
            ]
        )

        # Create the history-aware retriever
        self.history_aware_retriever = create_history_aware_retriever(
            self.llm, retriever, contextualize_q_prompt
        )

        # Define examples for few-shot learning
        examples = [
            {
                "input": "Hey! How you are?",
                "output": "Hello! Did you mean: 'How are you?'. I'm pretty fine, and you?"
            },
            {
                "input": "That's what i meant. I'm pretty fine too! Thanks for asking.",
                "output": "You're welcome! What would you like to talk?"
            },
            {
                "input": "We can talk about movies.",
                "output": "Oh, i enjoy movies a lot. What about you?"
            },
            {
                "input": "I love watch movies, especially comedies.",
                "output": "Did you mean: 'I love watching movies'? Comedies are great for a good laugh. Do you have a favorite comedy movie?"
            },
            {
                "input": "That's right, i meant to say 'I love watching movies'. Yes, my favorite movie is 'The Mask'",
                "output": "That's a classic! Jim Carrey is hilarious in that movie. What do you like most about it?"
            },
            {
                "input": "I like how funny and full of action it is.",
                "output": "It is definitely a fun and action-packed movie. Do you watch movies often?"
            }
        ]

        # Define the example prompt
        example_prompt = ChatPromptTemplate.from_messages(
            [
                ("user", "{input}"),
                ("ai", "{output}"),
            ]
        )

        # Create a few-shot prompt template
        few_shot_prompt = FewShotChatMessagePromptTemplate(
            example_prompt=example_prompt,
            examples=examples
        )

        # Define the QA prompt template
        qa_prompt = ChatPromptTemplate.from_messages(
            [
                ("system", """You are Marvin, a friendly and communicative English tutor that helps improve syntax and conversation skills.
                           Here are a few examples of how you dialogue: """),
                few_shot_prompt,
                "System", """Analyze the syntax and construction of the following sentence: '{input}'. If there is an error in syntax or sentence construction, provide the corrected form followed by a question to keep a conversation, otherwise, answer in a hearty manner. Use the examples and the following context to construct your answer: {context}""",
                MessagesPlaceholder("chat_history"),
                ("user", "{input}"),
            ]
        )

        # Create the question-answer chain
        question_answer_chain = create_stuff_documents_chain(self.llm, qa_prompt)

        # Create the retrieval chain
        rag_chain = create_retrieval_chain(self.history_aware_retriever, question_answer_chain)

        # Initialize session store
        self.store = {}

        def get_session_history(session_id: str) -> BaseChatMessageHistory:
            if session_id not in self.store:
                self.store[session_id] = ChatMessageHistory()
            return self.store[session_id]

        # Create the conversational RAG chain
        self.conversational_rag_chain = RunnableWithMessageHistory(
            rag_chain,
            get_session_history,
            input_messages_key="input",
            history_messages_key="chat_history",
            output_messages_key="answer",
        )

    def llm_response(self, input):
        response = re.sub(r'AI:', '', self.conversational_rag_chain.invoke(
            {"input": input},
            config={"configurable": {"session_id": "abc123"}}
        )['answer'])
        return response
    
#Text to Speech

speechness = HuggingFaceEndpoint(
    repo_id="facebook/mms-tts-eng", token = st.secrets['HUGGINGFACEHUB_API_TOKEN'])

def text_speech(response):
    speech = speechness.client.text_to_speech(response)
    return speech