const express = require('express');
const router = express.Router();
const openaiService = require('../services/openaiService');

// Route to generate image from text prompt
router.post('/generate-image', async (req, res) => {
  try {
    const { prompt } = req.body;
    
    // Validate request
    if (!prompt || prompt.trim() === '') {
      return res.status(400).json({ message: 'Prompt is required' });
    }
    
    // Check if prompt is too long
    if (prompt.length > 1000) {
      return res.status(400).json({ message: 'Prompt is too long. Please keep it under 1000 characters.' });
    }
    
    // Generate the image
    const result = await openaiService.generateImage(prompt);
    
    // Return the image URL
    res.json({ url: result.url });
    
  } catch (error) {
    console.error('Error generating image:', error);
    
    // Handle specific API errors
    if (error.response && error.response.data) {
      return res.status(error.response.status || 500).json({
        message: 'Error from image generation API',
        details: error.response.data
      });
    }
    
    // General error handling
    res.status(500).json({
      message: 'Failed to generate image',
      error: error.message
    });
  }
});

// Route to check API status
router.get('/status', (req, res) => {
  res.json({ status: 'API is operational' });
});

module.exports = router;
