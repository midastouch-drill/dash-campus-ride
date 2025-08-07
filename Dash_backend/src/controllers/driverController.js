const asyncHandler = require('express-async-handler');
const { AppError } = require('../middlewares/errorMiddleware');
const Driver = require('../models/driverModel');
const User = require('../models/userModel');
const Ride = require('../models/rideModel');
const Transaction = require('../models/transactionModel');
const logger = require('../utils/logger');
const mongoose = require('mongoose');

// Get driver profile
const getDriverProfile = asyncHandler(async (req, res, next) => {
  // Find driver details
  const driver = await Driver.findOne({ user: req.user.id }).populate({
    path: 'user',
    select: 'firstName lastName email phone profilePicture isActive isVerified'
  });

  if (!driver) {
    return next(new AppError('Driver profile not found', 404));
  }

  // Get statistics for the driver
  const stats = {
    completedRides: driver.completedRides,
    cancelledRides: driver.cancelledRides,
    rating: driver.rating,
    totalRatings: driver.totalRatings
  };

  // Get total earnings
  const earnings = await Transaction.aggregate([
    {
      $match: {
        user: new mongoose.Types.ObjectId(req.user.id),  // Fixed: Added 'new' keyword
        type: 'credit',
        status: 'successful',
      }
    },
    {
      $group: {
        _id: null,
        total: { $sum: '$amount' }
      }
    }
  ]);

  const totalEarnings = earnings.length > 0 ? earnings[0].total : 0;

  res.status(200).json({
    status: 'success',
    data: {
      driver: {
        id: driver._id,
        user: driver.user,
        vehicleType: driver.vehicleType,
        vehicleMake: driver.vehicleMake,
        vehicleModel: driver.vehicleModel,
        vehicleColor: driver.vehicleColor,
        licensePlate: driver.licensePlate,
        isApproved: driver.isApproved,
        isAvailable: driver.isAvailable,
        stats,
        totalEarnings
      }
    }
  });
});

// Update driver profile
const updateDriverProfile = asyncHandler(async (req, res, next) => {
  const { vehicleMake, vehicleModel, vehicleColor } = req.body;

  // Find driver details
  const driver = await Driver.findOne({ user: req.user.id });
  if (!driver) {
    return next(new AppError('Driver profile not found', 404));
  }

  // Update driver profile
  const updates = {};
  
  if (vehicleMake) updates.vehicleMake = vehicleMake;
  if (vehicleModel) updates.vehicleModel = vehicleModel;
  if (vehicleColor) updates.vehicleColor = vehicleColor;
  
  if (Object.keys(updates).length === 0) {
    return next(new AppError('No updates provided', 400));
  }
  
  updates.updatedAt = Date.now();

  const updatedDriver = await Driver.findByIdAndUpdate(
    driver._id,
    updates,
    { new: true, runValidators: true }
  );

  res.status(200).json({
    status: 'success',
    data: {
      driver: {
        id: updatedDriver._id,
        vehicleType: updatedDriver.vehicleType,
        vehicleMake: updatedDriver.vehicleMake,
        vehicleModel: updatedDriver.vehicleModel,
        vehicleColor: updatedDriver.vehicleColor,
        licensePlate: updatedDriver.licensePlate,
      }
    }
  });
});

// Update driver availability
const updateDriverAvailability = asyncHandler(async (req, res, next) => {
  const { isAvailable } = req.body;

  // Check if isAvailable is provided
  if (typeof isAvailable !== 'boolean') {
    return next(new AppError('isAvailable must be true or false', 400));
  }

  // Find driver details
  const driver = await Driver.findOne({ user: req.user.id });
  if (!driver) {
    return next(new AppError('Driver profile not found', 404));
  }

  // Check if driver is approved
  if (!driver.isApproved) {
    return next(new AppError('Driver is not approved yet by admin', 403));
  }

  // Update availability
  driver.isAvailable = isAvailable;
  driver.updatedAt = Date.now();
  await driver.save();

  logger.info(`Driver ${driver._id} changed availability to ${isAvailable ? 'online' : 'offline'}`);

  res.status(200).json({
    status: 'success',
    message: `You are now ${isAvailable ? 'online' : 'offline'}`,
    data: {
      driver: {
        id: driver._id,
        isAvailable: driver.isAvailable
      }
    }
  });
});

// Update driver location
const updateDriverLocation = asyncHandler(async (req, res, next) => {
  const { coordinates } = req.body;

  // Validate coordinates
  if (!coordinates || !Array.isArray(coordinates) || coordinates.length !== 2) {
    return next(new AppError('Valid coordinates are required [longitude, latitude]', 400));
  }

  // Find driver details
  const driver = await Driver.findOne({ user: req.user.id });
  if (!driver) {
    return next(new AppError('Driver profile not found', 404));
  }

  // Update location
  driver.currentLocation = {
    type: 'Point',
    coordinates
  };
  driver.updatedAt = Date.now();
  await driver.save();

  res.status(200).json({
    status: 'success',
    data: {
      driver: {
        id: driver._id,
        currentLocation: driver.currentLocation
      }
    }
  });
});

// Get driver's rides
const getDriverRides = asyncHandler(async (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  // Find driver
  const driver = await Driver.findOne({ user: req.user.id });
  if (!driver) {
    return next(new AppError('Driver profile not found', 404));
  }

  const query = { driver: driver._id };
  
  // Filter by status if provided
  if (req.query.status && ['requested', 'accepted', 'ongoing', 'completed', 'cancelled'].includes(req.query.status)) {
    query.status = req.query.status;
  }

  // Find rides
  const rides = await Ride.find(query)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .populate({
      path: 'rider',
      select: 'firstName lastName phone profilePicture'
    });

  // Get total count
  const totalCount = await Ride.countDocuments(query);

  res.status(200).json({
    status: 'success',
    results: rides.length,
    pagination: {
      page,
      limit,
      totalCount,
      totalPages: Math.ceil(totalCount / limit)
    },
    data: {
      rides
    }
  });
});

// Get driver's earnings
const getDriverEarnings = asyncHandler(async (req, res, next) => {
  const { period = 'weekly' } = req.query;
  
  // Find driver
  const driver = await Driver.findOne({ user: req.user.id });
  if (!driver) {
    return next(new AppError('Driver profile not found', 404));
  }

  // Set date filter based on period
  let dateFilter = {};
  const now = new Date();
  
  switch(period) {
    case 'daily':
      const today = new Date(now.setHours(0, 0, 0, 0));
      dateFilter = { createdAt: { $gte: today } };
      break;
    case 'weekly':
      const oneWeekAgo = new Date(now);
      oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
      dateFilter = { createdAt: { $gte: oneWeekAgo } };
      break;
    case 'monthly':
      const oneMonthAgo = new Date(now);
      oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);
      dateFilter = { createdAt: { $gte: oneMonthAgo } };
      break;
    case 'all':
    default:
      // No date filter
      break;
  }

  // Get earnings
  const earnings = await Transaction.aggregate([
    {
      $match: {
        user: new mongoose.Types.ObjectId(req.user.id),  // Fixed: Added 'new' keyword
        type: 'credit',
        status: 'successful',
        ...dateFilter
      }
    },
    {
      $group: {
        _id: {
          $dateToString: { format: '%Y-%m-%d', date: '$createdAt' }
        },
        earnings: { $sum: '$amount' },
        count: { $sum: 1 }
      }
    },
    {
      $sort: { _id: 1 }
    }
  ]);

  // Calculate total
  let totalEarnings = 0;
  let totalRides = 0;
  
  earnings.forEach(day => {
    totalEarnings += day.earnings;
    totalRides += day.count;
  });

  res.status(200).json({
    status: 'success',
    data: {
      period,
      totalEarnings,
      totalRides,
      dailyBreakdown: earnings.map(day => ({
        date: day._id,
        earnings: day.earnings,
        rides: day.count
      }))
    }
  });
});

module.exports = {
  getDriverProfile,
  updateDriverProfile,
  updateDriverAvailability,
  updateDriverLocation,
  getDriverRides,
  getDriverEarnings
};