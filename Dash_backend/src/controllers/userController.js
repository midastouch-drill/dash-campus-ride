const asyncHandler = require('express-async-handler');
const { AppError } = require('../middlewares/errorMiddleware');
const User = require('../models/userModel');
const Driver = require('../models/driverModel');
const bcrypt = require('bcryptjs');

// Get current user profile
const getProfile = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user.id);
  
  // Get additional driver info if user is a driver
  let driverInfo = null;
  if (user.role === 'driver') {
    driverInfo = await Driver.findOne({ user: user._id });
  }

  res.status(200).json({
    status: 'success',
    data: {
      user: {
        id: user._id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        profilePicture: user.profilePicture,
        isActive: user.isActive,
        isVerified: user.isVerified,
      },
      driver: driverInfo,
    },
  });
});

// Update user profile
const updateProfile = asyncHandler(async (req, res, next) => {
  const { firstName, lastName, phone, profilePicture } = req.body;

  // Check if phone already exists for another user
  if (phone) {
    const phoneExists = await User.findOne({ 
      phone, 
      _id: { $ne: req.user.id } 
    });
    
    if (phoneExists) {
      return next(new AppError('Phone number already in use by another user', 400));
    }
  }

  // Find and update user
  const updatedUser = await User.findByIdAndUpdate(
    req.user.id,
    { 
      firstName, 
      lastName, 
      phone,
      profilePicture,
      updatedAt: Date.now()
    },
    { new: true, runValidators: true }
  );

  res.status(200).json({
    status: 'success',
    data: {
      user: {
        id: updatedUser._id,
        firstName: updatedUser.firstName,
        lastName: updatedUser.lastName,
        email: updatedUser.email,
        phone: updatedUser.phone,
        role: updatedUser.role,
        profilePicture: updatedUser.profilePicture,
      },
    },
  });
});

// Change password
const changePassword = asyncHandler(async (req, res, next) => {
  const { currentPassword, newPassword } = req.body;

  // Check if passwords are provided
  if (!currentPassword || !newPassword) {
    return next(new AppError('Please provide current and new password', 400));
  }

  // Get user with password
  const user = await User.findById(req.user.id).select('+password');

  // Check if current password is correct
  if (!(await user.comparePassword(currentPassword))) {
    return next(new AppError('Current password is incorrect', 401));
  }

  // Check if new password meets requirements
  if (newPassword.length < 8) {
    return next(new AppError('Password must be at least 8 characters', 400));
  }

  // Update password
  user.password = newPassword;
  user.updatedAt = Date.now();
  await user.save();

  res.status(200).json({
    status: 'success',
    message: 'Password changed successfully',
  });
});

// Update driver availability
const updateDriverAvailability = asyncHandler(async (req, res, next) => {
  const { isAvailable, currentLocation } = req.body;

  // Check if user is a driver
  if (req.user.role !== 'driver') {
    return next(new AppError('User is not a driver', 403));
  }

  // Find driver details
  const driver = await Driver.findOne({ user: req.user.id });
  if (!driver) {
    return next(new AppError('Driver details not found', 404));
  }

  // Check if driver is approved
  if (!driver.isApproved) {
    return next(new AppError('Driver is not approved yet by admin', 403));
  }

  // Update availability and location
  const updates = { updatedAt: Date.now() };
  
  if (typeof isAvailable === 'boolean') {
    updates.isAvailable = isAvailable;
  }

  if (currentLocation && currentLocation.coordinates) {
    updates.currentLocation = {
      type: 'Point',
      coordinates: currentLocation.coordinates, // [longitude, latitude]
    };
  }

  const updatedDriver = await Driver.findByIdAndUpdate(
    driver._id,
    updates,
    { new: true }
  );

  res.status(200).json({
    status: 'success',
    data: {
      driver: {
        id: updatedDriver._id,
        isAvailable: updatedDriver.isAvailable,
        currentLocation: updatedDriver.currentLocation,
      },
    },
  });
});

module.exports = {
  getProfile,
  updateProfile,
  changePassword,
  updateDriverAvailability,
};
