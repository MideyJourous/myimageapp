// ImageGallery component for displaying saved images
const ImageGallery = () => {
  const [savedImages, setSavedImages] = React.useState([]);
  const [selectedImage, setSelectedImage] = React.useState(null);

  React.useEffect(() => {
    // Load saved images from local storage
    const images = getFromStorage('savedImages') || [];
    setSavedImages(images);
  }, []);

  const removeImage = (id) => {
    const updatedImages = savedImages.filter(image => image.id !== id);
    localStorage.setItem('savedImages', JSON.stringify(updatedImages));
    setSavedImages(updatedImages);
    
    if (selectedImage && selectedImage.id === id) {
      setSelectedImage(null);
    }
  };

  const viewImageDetails = (image) => {
    setSelectedImage(image);
  };

  return (
    <div className="card p-4 shadow-sm">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h2>Your Image Gallery</h2>
      </div>

      {savedImages.length === 0 ? (
        <div className="text-center py-5">
          <div className="mb-3">
            <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" strokeLinecap="round" strokeLinejoin="round" className="text-muted">
              <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
              <circle cx="8.5" cy="8.5" r="1.5"></circle>
              <polyline points="21 15 16 10 5 21"></polyline>
            </svg>
          </div>
          <h4>Your Gallery is Empty</h4>
          <p className="text-muted">Generate and save images to see them here</p>
        </div>
      ) : (
        <div className="row">
          {savedImages.map(image => (
            <div key={image.id} className="col-md-4 mb-4">
              <div className="card h-100">
                <img 
                  src={image.url} 
                  alt={image.prompt} 
                  className="card-img-top gallery-image"
                  onClick={() => viewImageDetails(image)}
                />
                <div className="card-body">
                  <p className="card-text text-truncate">{image.prompt}</p>
                  <div className="d-flex justify-content-between align-items-center">
                    <small className="text-muted">
                      {new Date(image.timestamp).toLocaleDateString()}
                    </small>
                    <button 
                      className="btn btn-sm btn-outline-danger"
                      onClick={() => removeImage(image.id)}
                    >
                      Remove
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Image Details Modal */}
      {selectedImage && (
        <div className="modal show" style={{ display: 'block', backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-lg">
            <div className="modal-content">
              <div className="modal-header">
                <h5 className="modal-title">Image Details</h5>
                <button 
                  type="button" 
                  className="btn-close" 
                  onClick={() => setSelectedImage(null)}
                ></button>
              </div>
              <div className="modal-body">
                <img 
                  src={selectedImage.url} 
                  alt={selectedImage.prompt} 
                  className="img-fluid mb-3" 
                />
                <h6>Description:</h6>
                <p>{selectedImage.prompt}</p>
                <div className="d-flex justify-content-between">
                  <p className="text-muted">
                    Created: {new Date(selectedImage.timestamp).toLocaleString()}
                  </p>
                </div>
              </div>
              <div className="modal-footer">
                <a 
                  href={selectedImage.url} 
                  className="btn btn-primary" 
                  download="generated-image.png" 
                  target="_blank" 
                  rel="noopener noreferrer"
                >
                  Download
                </a>
                <button 
                  type="button" 
                  className="btn btn-danger"
                  onClick={() => removeImage(selectedImage.id)}
                >
                  Delete
                </button>
                <button 
                  type="button" 
                  className="btn btn-secondary" 
                  onClick={() => setSelectedImage(null)}
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
