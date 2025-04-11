// Main App component for the Text to Image Generator
const App = () => {
  const [activeTab, setActiveTab] = React.useState('generator');
  
  return (
    <div className="container mt-4">
      <header className="mb-5 text-center">
        <h1>Text to Image Generator</h1>
        <p className="lead">Create images from your text descriptions using AI</p>
      </header>

      <div className="nav-tabs-container">
        <ul className="nav nav-tabs mb-4">
          <li className="nav-item">
            <button 
              className={`nav-link ${activeTab === 'generator' ? 'active' : ''}`} 
              onClick={() => setActiveTab('generator')}
            >
              Image Generator
            </button>
          </li>
          <li className="nav-item">
            <button 
              className={`nav-link ${activeTab === 'gallery' ? 'active' : ''}`} 
              onClick={() => setActiveTab('gallery')}
            >
              Image Gallery
            </button>
          </li>
        </ul>
      </div>

      <div className="tab-content">
        {activeTab === 'generator' ? (
          <ImageGenerator />
        ) : (
          <ImageGallery />
        )}
      </div>

      <footer className="mt-5 pt-4 text-center text-muted border-top">
        <p>© 2023 Text to Image Generator | Powered by OpenAI DALL-E</p>
      </footer>
    </div>
  );
};
