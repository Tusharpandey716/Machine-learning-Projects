from fastapi import FastAPI, File, UploadFile, Form, HTTPException
import fitz  # PyMuPDF
import chromadb  # Vector Database
from sentence_transformers import SentenceTransformer
from transformers import pipeline
import os
import uuid

from fastapi.middleware.cors import CORSMiddleware

# Initialize FastAPI
app = FastAPI()

# Enable CORS (Allow frontend requests)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change "*" to a specific origin in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load AI models
embed_model = SentenceTransformer("all-MiniLM-L6-v2")
summarizer = pipeline("summarization", model="t5-small")

# Initialize ChromaDB
chroma_client = chromadb.PersistentClient(path="./chroma_db")
collection = chroma_client.get_or_create_collection(name="pdf_docs")

# Extract text from PDFs
def extract_text_from_pdf(pdf_path):
    try:
        doc = fitz.open(pdf_path)
        text = "\n".join([page.get_text("text") for page in doc])
        return text if text.strip() else "No text found in PDF."
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error reading PDF: {str(e)}")

# API to upload PDFs
@app.post("/upload/")
async def upload_pdf(file: UploadFile = File(...)):
    file_path = f"temp_{uuid.uuid4().hex}.pdf"
    
    try:
        with open(file_path, "wb") as f:
            f.write(file.file.read())

        # Extract text
        text = extract_text_from_pdf(file_path)
        if text == "No text found in PDF.":
            raise HTTPException(status_code=400, detail="Uploaded PDF contains no readable text.")
        
        # Generate embeddings
        embedding = embed_model.encode(text).tolist()
        
        # Store in ChromaDB
        doc_id = str(uuid.uuid4())
        collection.add(documents=[text], embeddings=[embedding], ids=[doc_id])

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing PDF: {str(e)}")
    
    finally:
        os.remove(file_path)  # Ensure file is deleted
    
    return {"message": "PDF uploaded & processed", "doc_id": doc_id}

# API to ask questions
@app.post("/query/")
async def query_pdf(question: str = Form(...)):
    try:
        # Convert question to embedding
        question_embedding = embed_model.encode(question).tolist()
        results = collection.query(query_embeddings=[question_embedding], n_results=1)

        if not results.get("documents") or not results["documents"][0]:
            raise HTTPException(status_code=404, detail="No relevant information found.")
        
        relevant_text = results["documents"][0][0]

        # Summarize relevant text
        summary = summarizer(relevant_text, max_length=200, min_length=20, do_sample=False)
    
        return {"answer": summary[0]["summary_text"]}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing query: {str(e)}")

# Run FastAPI server
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
