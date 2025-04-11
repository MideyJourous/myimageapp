const OpenAI = require('openai');

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

/**
 * Generate an image based on text prompt using OpenAI's DALL-E
 * @param {string} prompt - The text description for image generation
 * @returns {Promise<Object>} - Object containing the generated image URL
 */
async function generateImage(prompt) {
  try {
    // Enhance the prompt for better results
    const enhancedPrompt = `${prompt}. High quality, detailed image.`;
    
    // Generate image with DALL-E
    const response = await openai.images.generate({
      model: "dall-e-3", // Using DALL-E 3 for better quality
      prompt: enhancedPrompt,
      n: 1, // Generate one image
      size: "1024x1024", // Standard size
      quality: "standard",
    });

    return { url: response.data[0].url };
  } catch (error) {
    console.error('OpenAI image generation error:', error);
    
    // Check if it's a specific API error
    if (error.response) {
      throw new Error(`OpenAI API error: ${error.response.data.error.message}`);
    }
    
    // Handle rate limiting
    if (error.code === 'rate_limit_exceeded') {
      throw new Error('Rate limit exceeded. Please try again later.');
    }
    
    // Handle content policy violations
    if (error.code === 'content_policy_violation') {
      throw new Error('Your request violates content policy. Please modify your prompt and try again.');
    }
    
    // Generic error
    throw new Error('Failed to generate image: ' + error.message);
  }
}

module.exports = {
  generateImage
};
