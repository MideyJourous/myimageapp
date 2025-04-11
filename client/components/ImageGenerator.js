// ImageGenerator component for handling text input and image generation
const ImageGenerator = () => {
  const [prompt, setPrompt] = React.useState("");
  const [generatedImage, setGeneratedImage] = React.useState(null);
  const [isLoading, setIsLoading] = React.useState(false);
  const [error, setError] = React.useState(null);
  const [isSaved, setIsSaved] = React.useState(false);
  const MAX_CHARS = 1000;

  const generateImage = async () => {
    if (!prompt || prompt.trim() === "") {
      setError("Please enter a description for your image.");
      return;
    }

    setError(null);
    setIsLoading(true);
    setGeneratedImage(null);
    setIsSaved(false);

    try {
      const response = await fetch('/api/generate-image', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ prompt: prompt.trim() }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Failed to generate image');
      }

      const data = await response.json();
      setGeneratedImage(data.url);
    } catch (err) {
      setError(`Error: ${err.message || 'Failed to generate image. Please try again.'}`);
    } finally {
      setIsLoading(false);
    }
  };

  const saveImage = () => {
    if (!generatedImage) return;

    const imageData = {
      prompt,
      url: generatedImage,
      timestamp: new Date().toISOString(),
      id: Date.now().toString()
    };

    const savedImages = saveToStorage('savedImages', imageData);
    setIsSaved(true);
  };

  return (
    <div className="card p-4 shadow-sm">
      <h2 className="mb-4">Create Your Image</h2>
      
      <div className="mb-4">
        <label htmlFor="prompt" className="form-label">
          Describe the image you want to create:
        </label>
        <textarea
          id="prompt"
          className="form-control"
          placeholder="Describe your image in detail... (e.g., A surreal landscape with floating islands, waterfalls, and a rainbow sky)"
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          maxLength={MAX_CHARS}
          rows={5}
        ></textarea>
        <div className="d-flex justify-content-between mt-2">
          <small className="text-muted">
            Be descriptive for better results
          </small>
          <small className="text-muted">
            {prompt.length}/{MAX_CHARS} characters
          </small>
        </div>
      </div>

      {error && (
        <div className="alert alert-danger" role="alert">
          {error}
        </div>
      )}

      <div className="d-grid mb-4">
        <button 
          className="btn btn-primary" 
          onClick={generateImage}
          disabled={isLoading || !prompt.trim()}
        >
          {isLoading ? (
            <>
              <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
              Generating Image...
            </>
          ) : (
            'Generate Image'
          )}
        </button>
      </div>

      {isLoading && (
        <div className="text-center my-4">
          <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
          <p className="mt-2">Creating your image... This may take a moment.</p>
        </div>
      )}

      {generatedImage && (
        <div className="image-result mt-4">
          <h3 className="mb-3">Your Generated Image</h3>
          <div className="image-container text-center">
            <img 
              src={generatedImage} 
              alt={prompt} 
              className="img-fluid rounded shadow-sm mb-3" 
            />
            <div className="d-flex justify-content-center gap-2">
              <button 
                className="btn btn-success" 
                onClick={saveImage}
                disabled={isSaved}
              >
                {isSaved ? 'Saved to Gallery' : 'Save to Gallery'}
              </button>
              <a 
                href={generatedImage} 
                className="btn btn-outline-primary" 
                download="generated-image.png" 
                target="_blank" 
                rel="noopener noreferrer"
              >
                Download
              </a>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
