const asyncHandler = require('express-async-handler');
const { AppError } = require('../middlewares/errorMiddleware');
const User = require('../models/userModel');
const Driver = require('../models/driverModel');
const Ride = require('../models/rideModel');
const Transaction = require('../models/transactionModel');
const mongoose = require('mongoose');

// Get all users with pagination
const getAllUsers = asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  // Filter query
  const filter = {};
  if (req.query.role) {
    filter.role = req.query.role;
  }

  // Find users
  const users = await User.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);

  // Get total count
  const totalCount = await User.countDocuments(filter);

  res.status(200).json({
    status: 'success',
    results: users.length,
    pagination: {
      page,
      limit,
      totalCount,
      totalPages: Math.ceil(totalCount / limit),
    },
    data: {
      users,
    },
  });
});

// Get user details
const getUserDetails = asyncHandler(async (req, res, next) => {
  const { userId } = req.params;

  // Find user
  const user = await User.findById(userId);
  if (!user) {
    return next(new AppError('User not found', 404));
  }

  // Get additional driver info if user is a driver
  let driverInfo = null;
  if (user.role === 'driver') {
    driverInfo = await Driver.findOne({ user: user._id });
  }

  res.status(200).json({
    status: 'success',
    data: {
      user,
      driver: driverInfo,
    },
  });
});

// Update user status (activate/deactivate)
const updateUserStatus = asyncHandler(async (req, res, next) => {
  const { userId } = req.params;
  const { isActive } = req.body;

  // Check if isActive is provided
  if (typeof isActive !== 'boolean') {
    return next(new AppError('isActive must be true or false', 400));
  }

  // Find and update user
  const updatedUser = await User.findByIdAndUpdate(
    userId,
    {
      isActive,
      updatedAt: Date.now(),
    },
    { new: true }
  );

  if (!updatedUser) {
    return next(new AppError('User not found', 404));
  }

  res.status(200).json({
    status: 'success',
    data: {
      user: updatedUser,
    },
  });
});

// Get pending driver approvals
const getPendingDrivers = asyncHandler(async (req, res) => {
  const drivers = await Driver.find({ isApproved: false })
    .populate({
      path: 'user',
      select: 'firstName lastName email phone isActive isVerified createdAt',
    })
    .sort({ createdAt: 1 });

  res.status(200).json({
    status: 'success',
    results: drivers.length,
    data: {
      drivers,
    },
  });
});

// Approve or reject driver
const approveRejectDriver = asyncHandler(async (req, res, next) => {
  const { driverId } = req.params;
  const { approve } = req.body;

  console.log('Driver ID from params:', driverId);
  console.log('Collection name:', Driver.collection.name);
  console.log('Database name:', mongoose.connection.db.databaseName);
  
  // Find all drivers to check if any exist
  const allDrivers = await Driver.find({}).lean();
  console.log('Total drivers found:', allDrivers.length);
  
  if (allDrivers.length > 0) {
    // Log some sample driver IDs for comparison
    console.log('Sample driver IDs:', allDrivers.slice(0, 3).map(d => d._id.toString()));
  }
  
  // Try finding the specific driver using different methods
  try {
    // Method 1: Using findById directly
    const driver = await Driver.findById(driverId);
    
    if (!driver) {
      console.log('Driver not found using findById');
      
      // Method 2: Try using a different query approach
      const driverAlt = await Driver.findOne({ _id: driverId }).exec();
      
      if (!driverAlt) {
        console.log('Driver not found using findOne with string ID');
        
        try {
          // Method 3: Try converting to ObjectId explicitly
          const objId = new mongoose.Types.ObjectId(driverId);
          console.log('Successfully converted to ObjectId:', objId);
          
          const driverWithObjId = await Driver.findOne({ _id: objId }).exec();
          
          if (!driverWithObjId) {
            console.log('Driver not found even with explicit ObjectId conversion');
            return next(new AppError('Driver not found', 404));
          } else {
            console.log('Driver found with explicit ObjectId conversion!');
            // Update driver approval status
            driverWithObjId.isApproved = approve;
            driverWithObjId.updatedAt = Date.now();
            await driverWithObjId.save();

            // Update user verification status
            const user = await User.findById(driverWithObjId.user);
            user.isVerified = approve;
            user.updatedAt = Date.now();
            await user.save();

            return res.status(200).json({
              status: 'success',
              data: {
                driver: driverWithObjId,
              },
            });
          }
        } catch (err) {
          console.log('Error converting to ObjectId:', err.message);
          return next(new AppError(`Invalid driver ID format: ${err.message}`, 400));
        }
      } else {
        console.log('Driver found using findOne with string ID!');
        // Use driverAlt for the rest of the function
        driverAlt.isApproved = approve;
        driverAlt.updatedAt = Date.now();
        await driverAlt.save();

        // Update user verification status
        const user = await User.findById(driverAlt.user);
        user.isVerified = approve;
        user.updatedAt = Date.now();
        await user.save();

        return res.status(200).json({
          status: 'success',
          data: {
            driver: driverAlt,
          },
        });
      }
    } else {
      console.log('Driver found using regular findById!');
      // Original code path since driver was found
      driver.isApproved = approve;
      driver.updatedAt = Date.now();
      await driver.save();

      // Update user verification status
      const user = await User.findById(driver.user);
      user.isVerified = approve;
      user.updatedAt = Date.now();
      await user.save();

      return res.status(200).json({
        status: 'success',
        data: {
          driver,
        },
      });
    }
  } catch (err) {
    console.error('Unexpected error:', err);
    return next(new AppError(`Error finding driver: ${err.message}`, 500));
  }
});

// Get all rides with pagination
const getAllRides = asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  // Filter query
  const filter = {};
  if (req.query.status) {
    filter.status = req.query.status;
  }

  // Find rides
  const rides = await Ride.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .populate({
      path: 'rider',
      select: 'firstName lastName phone',
    })
    .populate({
      path: 'driver',
      select: 'vehicleType licensePlate',
      populate: {
        path: 'user',
        select: 'firstName lastName phone',
      },
    });

  // Get total count
  const totalCount = await Ride.countDocuments(filter);

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

// Get all transactions with pagination
const getAllTransactions = asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  // Filter query
  const filter = {};
  if (req.query.type) {
    filter.type = req.query.type;
  }
  if (req.query.status) {
    filter.status = req.query.status;
  }

  // Find transactions
  const transactions = await Transaction.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .populate({
      path: 'user',
      select: 'firstName lastName email phone role',
    })
    .populate({
      path: 'ride',
      select: 'status pickupLocation.name dropoffLocation.name',
    });

  // Get total count
  const totalCount = await Transaction.countDocuments(filter);

  res.status(200).json({
    status: 'success',
    results: transactions.length,
    pagination: {
      page,
      limit,
      totalCount,
      totalPages: Math.ceil(totalCount / limit),
    },
    data: {
      transactions,
    },
  });
});

// Get dashboard stats
const getDashboardStats = asyncHandler(async (req, res) => {
  // Total users
  const totalUsers = await User.countDocuments();
  const totalRiders = await User.countDocuments({ role: 'rider' });
  const totalDrivers = await User.countDocuments({ role: 'driver' });
  
  // Active drivers
  const activeDrivers = await Driver.countDocuments({ isApproved: true });
  
  // Pending drivers
  const pendingDrivers = await Driver.countDocuments({ isApproved: false });
  
  // Ride stats
  const totalRides = await Ride.countDocuments();
  const completedRides = await Ride.countDocuments({ status: 'completed' });
  const cancelledRides = await Ride.countDocuments({ status: 'cancelled' });
  const ongoingRides = await Ride.countDocuments({ status: 'ongoing' });
  
  // Transaction stats
  const totalTransactions = await Transaction.countDocuments();
  const totalRevenue = await Transaction.aggregate([
    { $match: { type: 'commission', status: 'successful' } },
    { $group: { _id: null, total: { $sum: '$amount' } } }
  ]);

  // Today's stats
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayRides = await Ride.countDocuments({ createdAt: { $gte: today } });
  const todayCompletedRides = await Ride.countDocuments({ 
    status: 'completed',
    createdAt: { $gte: today }
  });
  const todayRevenue = await Transaction.aggregate([
    { 
      $match: { 
        type: 'commission',
        status: 'successful',
        createdAt: { $gte: today }
      }
    },
    { $group: { _id: null, total: { $sum: '$amount' } } }
  ]);

  res.status(200).json({
    status: 'success',
    data: {
      users: {
        total: totalUsers,
        riders: totalRiders,
        drivers: totalDrivers,
        pending_drivers: pendingDrivers,
        active_drivers: activeDrivers,
      },
      rides: {
        total: totalRides,
        completed: completedRides,
        cancelled: cancelledRides,
        ongoing: ongoingRides,
      },
      transactions: {
        total: totalTransactions,
        revenue: totalRevenue.length > 0 ? totalRevenue[0].total : 0,
      },
      today: {
        rides: todayRides,
        completed_rides: todayCompletedRides,
        revenue: todayRevenue.length > 0 ? todayRevenue[0].total : 0,
      },
    },
  });
});

module.exports = {
  getAllUsers,
  getUserDetails,
  updateUserStatus,
  getPendingDrivers,
  approveRejectDriver,
  getAllRides,
  getAllTransactions,
  getDashboardStats,
};
