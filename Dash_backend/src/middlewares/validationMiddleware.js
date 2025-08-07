
const { AppError } = require('./errorMiddleware');

// Validate request body fields
const validateFields = (requiredFields) => {
  return (req, res, next) => {
    const missingFields = [];
    
    requiredFields.forEach(field => {
      if (!req.body[field]) {
        missingFields.push(field);
      }
    });
    
    if (missingFields.length > 0) {
      return next(new AppError(`Missing required fields: ${missingFields.join(', ')}`, 400));
    }
    
    next();
  };
};

// Validate ObjectId
const validateObjectId = (req, res, next) => {
  const { mongoose } = require('mongoose');
  const params = req.params;
  
  for (const param in params) {
    if (param.toLowerCase().includes('id')) {
      if (!mongoose.Types.ObjectId.isValid(params[param])) {
        return next(new AppError(`Invalid ID format for ${param}`, 400));
      }
    }
  }
  
  next();
};

// Validate pagination parameters
const validatePagination = (req, res, next) => {
  const { page, limit } = req.query;
  
  if (page && (!Number.isInteger(Number(page)) || Number(page) < 1)) {
    return next(new AppError('Page parameter must be a positive integer', 400));
  }
  
  if (limit && (!Number.isInteger(Number(limit)) || Number(limit) < 1)) {
    return next(new AppError('Limit parameter must be a positive integer', 400));
  }
  
  next();
};

module.exports = {
  validateFields,
  validateObjectId,
  validatePagination
};
