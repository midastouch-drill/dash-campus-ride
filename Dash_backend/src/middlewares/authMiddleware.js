const jwt = require('jsonwebtoken');
const { AppError } = require('./errorMiddleware');
const User = require('../models/userModel');
const asyncHandler = require('express-async-handler');
const config = require('../config/config');
const logger = require('../utils/logger');

// Protect routes middleware
const protect = asyncHandler(async (req, res, next) => {
  let token;

  // Check if token exists in authorization header
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    token = req.headers.authorization.split(' ')[1];
  }

  // Check if token exists
  if (!token) {
    return next(new AppError('You are not logged in. Please log in to get access.', 401));
  }

  try {
    // Verify token using jwtSecret from config
    const decoded = jwt.verify(token, config.jwtSecret);
    logger.debug(`Token verified for user: ${decoded.id}`);

    // Check if user still exists
    const user = await User.findById(decoded.id).select('-password');
    if (!user) {
      return next(new AppError('The user belonging to this token no longer exists.', 401));
    }

    // Check if user is active
    if (!user.isActive) {
      return next(new AppError('Your account has been deactivated.', 401));
    }

    // Grant access to protected route
    logger.debug(`Access granted to: ${user.email} (${user.role})`);
    req.user = user;
    next();
  } catch (error) {
    logger.error(`Auth middleware error: ${error.message}`);
    return next(new AppError('Invalid token. Please log in again.', 401));
  }
});

// Restrict to certain roles middleware
const restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      logger.warn(`Access denied for ${req.user.email} (${req.user.role}) - Required roles: ${roles.join(', ')}`);
      return next(new AppError('You do not have permission to perform this action.', 403));
    }
    logger.debug(`Role verification passed for ${req.user.email} (${req.user.role})`);
    next();
  };
};

module.exports = { protect, restrictTo };
