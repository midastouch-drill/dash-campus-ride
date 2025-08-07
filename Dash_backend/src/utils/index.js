
/**
 * Generate a random string
 * @param {number} length - Length of string to generate
 * @returns {string} Random string
 */
const generateRandomString = (length = 8) => {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += characters.charAt(Math.floor(Math.random() * characters.length));
    }
    return result;
  };
  
  /**
   * Format currency amount
   * @param {number} amount - Amount to format
   * @param {string} currency - Currency code (default: NGN)
   * @returns {string} Formatted currency
   */
  const formatCurrency = (amount, currency = 'NGN') => {
    return new Intl.NumberFormat('en-NG', {
      style: 'currency',
      currency,
    }).format(amount);
  };
  
  /**
   * Calculate distance between two points using Haversine formula
   * @param {Array} coordinates1 - [longitude, latitude] of first point
   * @param {Array} coordinates2 - [longitude, latitude] of second point
   * @returns {number} Distance in kilometers
   */
  const calculateDistance = (coordinates1, coordinates2) => {
    const [lon1, lat1] = coordinates1;
    const [lon2, lat2] = coordinates2;
    
    const R = 6371; // Radius of the earth in km
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c; // Distance in km
    
    return distance;
  };
  
  /**
   * Convert degrees to radians
   * @param {number} deg - Degrees
   * @returns {number} Radians
   */
  const deg2rad = (deg) => {
    return deg * (Math.PI / 180);
  };
  
  /**
   * Estimate ride duration based on distance
   * @param {number} distanceInKm - Distance in kilometers
   * @param {number} averageSpeedKmh - Average speed in km/h
   * @returns {number} Duration in minutes
   */
  const estimateRideDuration = (distanceInKm, averageSpeedKmh = 30) => {
    const durationHours = distanceInKm / averageSpeedKmh;
    return Math.round(durationHours * 60); // Convert to minutes and round
  };
  
  module.exports = {
    generateRandomString,
    formatCurrency,
    calculateDistance,
    estimateRideDuration,
  };
  