// Utility functions for handling local storage
const saveToStorage = (key, item) => {
  try {
    // Get existing items
    const existingItems = getFromStorage(key) || [];
    
    // Add new item to array
    const updatedItems = [item, ...existingItems];
    
    // Save to localStorage
    localStorage.setItem(key, JSON.stringify(updatedItems));
    
    return updatedItems;
  } catch (error) {
    console.error('Error saving to local storage:', error);
    return [];
  }
};

const getFromStorage = (key) => {
  try {
    const items = localStorage.getItem(key);
    return items ? JSON.parse(items) : null;
  } catch (error) {
    console.error('Error reading from local storage:', error);
    return null;
  }
};

const removeFromStorage = (key, id) => {
  try {
    const items = getFromStorage(key) || [];
    const updatedItems = items.filter(item => item.id !== id);
    localStorage.setItem(key, JSON.stringify(updatedItems));
    return updatedItems;
  } catch (error) {
    console.error('Error removing from local storage:', error);
    return [];
  }
};

const clearStorage = (key) => {
  try {
    localStorage.removeItem(key);
  } catch (error) {
    console.error('Error clearing local storage:', error);
  }
};
