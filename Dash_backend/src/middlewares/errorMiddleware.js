// Error handling middleware
const errorHandler = (err, req, res, next) => {
    const statusCode = err.statusCode || 500;
    const message = err.message || 'Something went wrong';
    
    // Log error for developers
    console.error(`[${statusCode}] - ${message}`, err.stack);
    
    res.status(statusCode).json({
      status: 'error',
      message,
      stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
    });
  };
  
  // Custom error class
  class AppError extends Error {
    constructor(message, statusCode) {
      super(message);
      this.statusCode = statusCode;
      this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
      this.isOperational = true;
  
      Error.captureStackTrace(this, this.constructor);
    }
  }
  
  module.exports = { errorHandler, AppError };
  