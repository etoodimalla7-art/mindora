"""RAG layer — chunking, embedding, retrieval."""
from ai.rag.chunker import chunk_text
from ai.rag.embedder import index_document
from ai.rag.retriever import search_documents

__all__ = ["chunk_text", "index_document", "search_documents"]
