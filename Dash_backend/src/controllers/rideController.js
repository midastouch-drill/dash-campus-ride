const asyncHandler = require('express-async-handler');
const { AppError } = require('../middlewares/errorMiddleware');
const Ride = require('../models/rideModel');
const Driver = require('../models/driverModel');
const User = require('../models/userModel');
const Wallet = require('../models/walletModel');
const Transaction = require('../models/transactionModel');
const { v4: uuidv4 } = require('uuid');

// Constants
const BASE_FARE = 200; // Naira
const PRICE_PER_KM = 100; // Naira per km
const COMMISSION_PERCENTAGE = 10; // 10%

// Helper function to calculate fare
const calculateFare = (distanceInKm) => {
  return BASE_FARE + (PRICE_PER_KM * distanceInKm);
};

// Calculate commission amount
const calculateCommission = (fare) => {
  return (fare * COMMISSION_PERCENTAGE) / 100;
};

// Request a new ride
const requestRide = asyncHandler(async (req, res, next) => {
  const {
    pickupLocation,
    dropoffLocation,
    distance,
    duration,
    paymentMethod,
  } = req.body;

  // Validate required fields
  if (!pickupLocation || !dropoffLocation || !distance || !duration || !paymentMethod) {
    return next(new AppError('Missing required fields', 400));
  }

  // Validate payment method
  if (!['cash', 'wallet'].includes(paymentMethod)) {
    return next(new AppError('Invalid payment method', 400));
  }

  // Calculate fare based on distance
  const fare = calculateFare(distance);

  // Calculate commission
  const commissionAmount = calculateCommission(fare);

  // Calculate driver amount
  const driverAmount = fare - commissionAmount;

  // If payment method is wallet, check if user has sufficient balance
  if (paymentMethod === 'wallet') {
    const wallet = await Wallet.findOne({ user: req.user.id });
    if (!wallet) {
      return next(new AppError('Wallet not found', 404));
    }
    if (wallet.balance < fare) {
      return next(new AppError('Insufficient wallet balance', 400));
    }
  }

  // Create new ride request
  const ride = await Ride.create({
    rider: req.user.id,
    pickupLocation,
    dropoffLocation,
    distance,
    duration,
    fare,
    commissionAmount,
    driverAmount,
    paymentMethod,
  });

  // Find available drivers near the pickup location (within 5km radius)
  const availableDrivers = await Driver.find({
    isAvailable: true,
    isApproved: true,
    currentLocation: {
      $nearSphere: {
        $geometry: {
          type: 'Point',
          coordinates: pickupLocation.coordinates,
        },
        $maxDistance: 5000, // 5km in meters
      },
    },
  }).limit(10);

  res.status(201).json({
    status: 'success',
    data: {
      ride,
      availableDrivers: availableDrivers.length,
    },
  });
});

// Driver accepts a ride
// Driver accepts a ride
const acceptRide = asyncHandler(async (req, res, next) => {
  const { rideId } = req.params;

  // Find the ride - add logging to debug
  console.log(`Attempting to find ride with ID: ${rideId}`);
  
  const ride = await Ride.findById(rideId);
  if (!ride) {
    console.log(`Ride not found with ID: ${rideId}`);
    return next(new AppError('Ride not found', 404));
  }

  console.log(`Ride found with status: ${ride.status}`);

  // Check if ride is already accepted or cancelled
  if (ride.status !== 'requested') {
    return next(new AppError(`Ride is already ${ride.status}`, 400));
  }

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
    return next(new AppError('Driver is not approved yet', 403));
  }

  // Update ride status
  ride.status = 'accepted';
  ride.driver = driver._id;
  ride.updatedAt = Date.now();
  await ride.save();

  // Update driver availability
  driver.isAvailable = false;
  driver.updatedAt = Date.now();
  await driver.save();

  res.status(200).json({
    status: 'success',
    data: {
      ride,
    },
  });
});

// Start ride
const startRide = asyncHandler(async (req, res, next) => {
  const { rideId } = req.params;

  // Find the ride
  const ride = await Ride.findById(rideId);
  if (!ride) {
    return next(new AppError('Ride not found', 404));
  }

  // Check if ride is accepted
  if (ride.status !== 'accepted') {
    return next(new AppError(`Ride cannot be started. Current status: ${ride.status}`, 400));
  }

  // Check if the driver making the request is the assigned driver
  const driver = await Driver.findOne({ user: req.user.id });
  if (!driver || !ride.driver.equals(driver._id)) {
    return next(new AppError('You are not authorized to start this ride', 403));
  }

  // Update ride status
  ride.status = 'ongoing';
  ride.startTime = Date.now();
  ride.updatedAt = Date.now();
  await ride.save();

  res.status(200).json({
    status: 'success',
    data: {
      ride,
    },
  });
});

// Complete ride
const completeRide = asyncHandler(async (req, res, next) => {
  const { rideId } = req.params;

  // Find the ride
  const ride = await Ride.findById(rideId);
  if (!ride) {
    return next(new AppError('Ride not found', 404));
  }

  // Check if ride is ongoing
  if (ride.status !== 'ongoing') {
    return next(new AppError(`Ride cannot be completed. Current status: ${ride.status}`, 400));
  }

  // Check if the driver making the request is the assigned driver
  const driver = await Driver.findOne({ user: req.user.id });
  if (!driver || !ride.driver.equals(driver._id)) {
    return next(new AppError('You are not authorized to complete this ride', 403));
  }

  // Update ride status
  ride.status = 'completed';
  ride.endTime = Date.now();
  ride.updatedAt = Date.now();

  // Handle payment
  if (ride.paymentMethod === 'wallet') {
    ride.paymentStatus = 'paid';

    // Deduct fare from rider's wallet
    const riderWallet = await Wallet.findOne({ user: ride.rider });
    riderWallet.balance -= ride.fare;
    riderWallet.updatedAt = Date.now();
    await riderWallet.save();

    // Create transaction record for rider
    await Transaction.create({
      user: ride.rider,
      type: 'debit',
      amount: ride.fare,
      description: `Payment for ride #${ride._id}`,
      reference: `RIDE_PAYMENT_${uuidv4()}`,
      status: 'successful',
      paymentMethod: 'wallet',
      ride: ride._id,
    });

    // Credit driver's wallet with their share
    const driverUser = await User.findById(driver.user);
    const driverWallet = await Wallet.findOne({ user: driverUser._id });
    driverWallet.balance += ride.driverAmount;
    driverWallet.updatedAt = Date.now();
    await driverWallet.save();

    // Create transaction record for driver
    await Transaction.create({
      user: driverUser._id,
      type: 'credit',
      amount: ride.driverAmount,
      description: `Earnings from ride #${ride._id}`,
      reference: `DRIVER_EARNING_${uuidv4()}`,
      status: 'successful',
      paymentMethod: 'wallet',
      ride: ride._id,
    });

    // Record commission transaction (to platform admin)
    await Transaction.create({
      user: driverUser._id, // Reference to driver for tracking
      type: 'commission',
      amount: ride.commissionAmount,
      description: `Commission from ride #${ride._id}`,
      reference: `COMMISSION_${uuidv4()}`,
      status: 'successful',
      paymentMethod: 'wallet',
      ride: ride._id,
    });
  } else {
    // For cash payments, mark as paid and record transactions
    ride.paymentStatus = 'paid';

    // Record driver's earning
    await Transaction.create({
      user: driver.user,
      type: 'credit',
      amount: ride.driverAmount,
      description: `Cash earnings from ride #${ride._id}`,
      reference: `DRIVER_CASH_EARNING_${uuidv4()}`,
      status: 'successful',
      paymentMethod: 'cash',
      ride: ride._id,
    });

    // Record commission (to be settled later)
    await Transaction.create({
      user: driver.user,
      type: 'commission',
      amount: ride.commissionAmount,
      description: `Commission owed from cash ride #${ride._id}`,
      reference: `CASH_COMMISSION_${uuidv4()}`,
      status: 'pending', // Commission is pending until driver settles
      paymentMethod: 'cash',
      ride: ride._id,
    });
  }

  await ride.save();

  // Update driver stats and availability
  driver.completedRides += 1;
  driver.isAvailable = true; // Make driver available again
  driver.updatedAt = Date.now();
  await driver.save();

  res.status(200).json({
    status: 'success',
    data: {
      ride,
    },
  });
});

// Cancel ride
const cancelRide = asyncHandler(async (req, res, next) => {
  const { rideId } = req.params;
  const { reason } = req.body;

  // Find the ride
  const ride = await Ride.findById(rideId);
  if (!ride) {
    return next(new AppError('Ride not found', 404));
  }

  // Check if ride can be cancelled (not already completed or cancelled)
  if (['completed', 'cancelled'].includes(ride.status)) {
    return next(new AppError(`Ride cannot be cancelled. Current status: ${ride.status}`, 400));
  }

  let cancelledBy;

  // Check authorization for cancellation
  if (req.user.role === 'rider' && ride.rider.equals(req.user._id)) {
    cancelledBy = 'rider';
  } else if (req.user.role === 'driver') {
    const driver = await Driver.findOne({ user: req.user.id });
    if (driver && ride.driver && ride.driver.equals(driver._id)) {
      cancelledBy = 'driver';

      // Update driver stats
      driver.cancelledRides += 1;
      await driver.save();
    } else {
      return next(new AppError('You are not authorized to cancel this ride', 403));
    }
  } else if (req.user.role === 'admin') {
    cancelledBy = 'system';
  } else {
    return next(new AppError('You are not authorized to cancel this ride', 403));
  }

  // Update ride status
  ride.status = 'cancelled';
  ride.cancellationReason = reason || 'No reason provided';
  ride.cancelledBy = cancelledBy;
  ride.updatedAt = Date.now();
  await ride.save();

  // If a driver was assigned, make them available again
  if (ride.driver) {
    const driver = await Driver.findById(ride.driver);
    if (driver) {
      driver.isAvailable = true;
      driver.updatedAt = Date.now();
      await driver.save();
    }
  }

  res.status(200).json({
    status: 'success',
    data: {
      ride,
    },
  });
});

// Get user's ride history
const getRideHistory = asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  const query = { rider: req.user.id };

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
      path: 'driver',
      select: 'vehicleType vehicleMake vehicleModel vehicleColor licensePlate',
      populate: {
        path: 'user',
        select: 'firstName lastName phone profilePicture',
      },
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
      totalPages: Math.ceil(totalCount / limit),
    },
    data: {
      rides,
    },
  });
});

// Get driver's ride history
const getDriverRideHistory = asyncHandler(async (req, res, next) => {
  // Check if user is a driver
  if (req.user.role !== 'driver') {
    return next(new AppError('User is not a driver', 403));
  }

  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  // Find driver details
  const driver = await Driver.findOne({ user: req.user.id });
  if (!driver) {
    return next(new AppError('Driver details not found', 404));
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
      select: 'firstName lastName phone profilePicture',
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
      totalPages: Math.ceil(totalCount / limit),
    },
    data: {
      rides,
    },
  });
});

// Get single ride details
const getRideDetails = asyncHandler(async (req, res, next) => {
  const { rideId } = req.params;

  // Find the ride
  const ride = await Ride.findById(rideId)
    .populate({
      path: 'rider',
      select: 'firstName lastName phone profilePicture',
    })
    .populate({
      path: 'driver',
      select: 'vehicleType vehicleMake vehicleModel vehicleColor licensePlate rating',
      populate: {
        path: 'user',
        select: 'firstName lastName phone profilePicture',
      },
    });

  if (!ride) {
    return next(new AppError('Ride not found', 404));
  }

  // Check if user is authorized to view this ride
  const isRider = ride.rider._id.equals(req.user._id);
  const isDriver = req.user.role === 'driver' &&
    ride.driver &&
    await Driver.findOne({ user: req.user.id, _id: ride.driver._id });
  const isAdmin = req.user.role === 'admin';

  if (!isRider && !isDriver && !isAdmin) {
    return next(new AppError('You are not authorized to view this ride', 403));
  }

  // Transform ride object to include virtual fields explicitly
  const rideObj = ride.toObject({ virtuals: true });

  res.status(200).json({
    status: 'success',
    data: {
      ride: rideObj,
    },
  });
});

// Rate a ride
const rateRide = asyncHandler(async (req, res, next) => {
  const { rideId } = req.params;
  const { rating, review } = req.body;

  // Validate rating
  if (!rating || rating < 1 || rating > 5) {
    return next(new AppError('Invalid rating. Must be between 1 and 5', 400));
  }

  // Find the ride
  const ride = await Ride.findById(rideId);
  if (!ride) {
    return next(new AppError('Ride not found', 404));
  }

  // Check if ride is completed
  if (ride.status !== 'completed') {
    return next(new AppError('Only completed rides can be rated', 400));
  }

  // Check if user is rider or driver
  const isRider = ride.rider.equals(req.user._id);
  const isDriver = req.user.role === 'driver' &&
    await Driver.findOne({ user: req.user.id, _id: ride.driver });

  if (!isRider && !isDriver) {
    return next(new AppError('You are not authorized to rate this ride', 403));
  }

  // Update rating based on user role
  if (isRider) {
    // Rider rating the driver
    if (ride.riderRating) {
      return next(new AppError('You have already rated this ride', 400));
    }

    ride.riderRating = rating;

    // Update driver's overall rating
    const driver = await Driver.findById(ride.driver);
    const newTotalRatings = driver.totalRatings + 1;
    const oldRatingWeight = driver.rating * driver.totalRatings;
    const newRating = (oldRatingWeight + rating) / newTotalRatings;

    driver.rating = newRating;
    driver.totalRatings = newTotalRatings;
    await driver.save();
  } else {
    // Driver rating the rider
    if (ride.driverRating) {
      return next(new AppError('You have already rated this ride', 400));
    }

    ride.driverRating = rating;

    // In a future version, this could update the rider's rating as well
  }

  ride.updatedAt = Date.now();
  await ride.save();

  res.status(200).json({
    status: 'success',
    data: {
      ride,
    },
  });
});

module.exports = {
  requestRide,
  acceptRide,
  startRide,
  completeRide,
  cancelRide,
  getRideHistory,
  getDriverRideHistory,
  getRideDetails,
  rateRide,
};
