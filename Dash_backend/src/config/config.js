require('dotenv').config();

module.exports = {
  port: process.env.PORT || 5000,
  nodeEnv: process.env.NODE_ENV || 'development',
  mongoURI: process.env.MONGODB_URI,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '30d',
  apiUrl: process.env.API_URL || `http://localhost:${process.env.PORT || 5000}`,
  corsOrigins: process.env.CORS_ORIGINS || '*',
  squad: {
    apiKey: process.env.SQUAD_API_KEY,
    apiUrl: process.env.SQUAD_API_URL || 'https://api.squadco.com',
    secretHash: process.env.SQUAD_SECRET_HASH,
  },
  rideSettings: {
    baseFare: process.env.BASE_FARE ? Number(process.env.BASE_FARE) : 200, // Naira
    pricePerKm: process.env.PRICE_PER_KM ? Number(process.env.PRICE_PER_KM) : 100, // Naira per km
    commissionPercentage: process.env.COMMISSION_PERCENTAGE ? Number(process.env.COMMISSION_PERCENTAGE) : 10, // 10%
    maxDriverDistance: process.env.MAX_DRIVER_DISTANCE ? Number(process.env.MAX_DRIVER_DISTANCE) : 5000, // in meters
  },
  logging: {
    level: process.env.LOG_LEVEL || 'info',
  },
};
