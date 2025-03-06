import { useState } from "react";
import axios from "axios";
import "./App.css";

export default function SmartDocSearch() {
  const [file, setFile] = useState(null);
  const [question, setQuestion] = useState("");
  const [answer, setAnswer] = useState("");
  const [loading, setLoading] = useState(false);

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
  };

  const handleUpload = async () => {
    if (!file) return alert("Please select a PDF file first");
    const formData = new FormData();
    formData.append("file", file);
    setLoading(true);
    try {
      await axios.post("http://localhost:8000/upload/", formData);
      alert("PDF uploaded successfully!");
    } catch (error) {
      alert("Error uploading PDF");
    }
    setLoading(false);
  };

  const handleQuery = async () => {
    if (!question) return alert("Please enter a question");
    setLoading(true);
    try {
      const response = await axios.post("http://localhost:8000/query/", new URLSearchParams({ question }));
      setAnswer(response.data.answer);
    } catch (error) {
      setAnswer("Error fetching answer");
    }
    setLoading(false);
  };

  return (
    <div className="container">
      <h2>Smart Document Search</h2>
      <input type="file" accept="application/pdf" onChange={handleFileChange} className="file-input" />
      <button onClick={handleUpload} className={`btn upload-btn ${loading ? 'disabled' : ''}`} disabled={loading}>
        {loading ? "Uploading..." : "Upload PDF"}
      </button>
      <input
        type="text"
        value={question}
        onChange={(e) => setQuestion(e.target.value)}
        placeholder="Ask a question..."
        className="text-input"
      />
      <button onClick={handleQuery} className={`btn query-btn ${loading ? 'disabled' : ''}`} disabled={loading}>
        {loading ? "Searching..." : "Search"}
      </button>
      {answer && <p className="answer-box">{answer}</p>}
    </div>
  );
}
