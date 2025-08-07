// authController.js (Fixed version)
const jwt = require('jsonwebtoken');
const asyncHandler = require('express-async-handler');
const { AppError } = require('../middlewares/errorMiddleware');
const User = require('../models/userModel');
const Wallet = require('../models/walletModel');
const Driver = require('../models/driverModel');
const { createVirtualAccount } = require('../services/squadService');
const config = require('../config/config');
const logger = require('../utils/logger');

// Generate JWT token
const generateToken = (id) => {
  return jwt.sign({ id }, config.jwtSecret, {
    expiresIn: config.jwtExpiresIn || '30d',
  });
};

// Validate rider registration fields
const validateRiderRegistration = (req, res, next) => {
  const requiredFields = ['firstName', 'lastName', 'email', 'phone', 'password'];
  const { firstName, lastName, email, phone, password } = req.body;

  const missingFields = requiredFields.filter(field => !req.body[field]);
  
  if (missingFields.length > 0) {
    return next(new AppError(`Missing required fields: ${missingFields.join(', ')}`, 400));
  }

  // Validate email format
  const emailRegex = /^\S+@\S+\.\S+$/;
  if (!emailRegex.test(email)) {
    return next(new AppError('Please provide a valid email address', 400));
  }

  // Validate phone format (11 digits for Nigerian phone numbers)
  const phoneRegex = /^\d{11}$/;
  if (!phoneRegex.test(phone)) {
    return next(new AppError('Please provide a valid phone number (11 digits)', 400));
  }

  // Validate password length
  if (password.length < 8) {
    return next(new AppError('Password must be at least 8 characters long', 400));
  }

  // Validate name fields
  if (firstName.trim().length < 2 || lastName.trim().length < 2) {
    return next(new AppError('First and last names must be at least 2 characters long', 400));
  }

  next();
};

// Validate driver registration fields
const validateDriverRegistration = (req, res, next) => {
  const requiredFields = [
    'firstName',
    'lastName',
    'email',
    'phone',
    'password',
    'vehicleType',
    'vehicleMake',
    'vehicleModel',
    'vehicleColor',
    'licensePlate',
    'driversLicense',
    'driversLicenseExpiry',
    'vehicleInsurance',
    'vehicleRegistration',
  ];

  const missingFields = requiredFields.filter(field => !req.body[field]);
  
  if (missingFields.length > 0) {
    return next(new AppError(`Missing required fields: ${missingFields.join(', ')}`, 400));
  }

  const {
    firstName,
    lastName,
    email,
    phone,
    password,
    vehicleType,
    driversLicenseExpiry,
  } = req.body;

  // Validate email format
  const emailRegex = /^\S+@\S+\.\S+$/;
  if (!emailRegex.test(email)) {
    return next(new AppError('Please provide a valid email address', 400));
  }

  // Validate phone format
  const phoneRegex = /^\d{11}$/;
  if (!phoneRegex.test(phone)) {
    return next(new AppError('Please provide a valid phone number (11 digits)', 400));
  }

  // Validate password length
  if (password.length < 8) {
    return next(new AppError('Password must be at least 8 characters long', 400));
  }

  // Validate name fields
  if (firstName.trim().length < 2 || lastName.trim().length < 2) {
    return next(new AppError('First and last names must be at least 2 characters long', 400));
  }

  // Validate vehicle type
  if (!['keke', 'cab'].includes(vehicleType)) {
    return next(new AppError('Vehicle type must be either "keke" or "cab"', 400));
  }

  // Validate driver's license expiry date
  const expiryDate = new Date(driversLicenseExpiry);
  if (isNaN(expiryDate.getTime()) || expiryDate < new Date()) {
    return next(new AppError('Please provide a valid future expiry date for driver\'s license', 400));
  }

  next();
};

// Register user (rider) - Fixed
const registerRider = asyncHandler(async (req, res, next) => {
  // First run validation
  validateRiderRegistration(req, res, async (err) => {
    if (err) return next(err);
    
    try {
      const { firstName, lastName, email, phone, password } = req.body;

      // Check if email or phone already exists
      const userExists = await User.findOne({ $or: [{ email }, { phone }] });
      if (userExists) {
        if (userExists.email === email) {
          return next(new AppError('User already exists with this email', 409));
        } else {
          return next(new AppError('User already exists with this phone number', 409));
        }
      }

      // Create user with rider role
      const user = await User.create({
        firstName,
        lastName,
        email,
        phone,
        password, // password is hashed via model pre-save middleware
        role: 'rider',
        isVerified: true, // Auto-verify for simplicity in MVP
      });

      if (!user) {
        return next(new AppError('Failed to create user account', 500));
      }

      // Create wallet for the user
      const wallet = await Wallet.create({
        user: user._id,
        balance: 0,
      });

      if (!wallet) {
        // If wallet creation fails, delete the user and return error
        await User.findByIdAndDelete(user._id);
        return next(new AppError('Failed to create user wallet', 500));
      }

      // Try to create virtual account (non-blocking)
      try {
        const virtualAccountData = await createVirtualAccount(user);
        if (virtualAccountData) {
          wallet.virtualAccountNumber = virtualAccountData.accountNumber;
          wallet.virtualAccountName = virtualAccountData.accountName;
          wallet.virtualAccountBank = virtualAccountData.bankName;
          await wallet.save();
        }
      } catch (error) {
        logger.error('Error creating virtual account:', error);
        // Continue registration even if virtual account creation fails
      }

      // Generate token
      const token = generateToken(user._id);

      // Return success response with token and user data
      return res.status(201).json({
        status: 'success',
        message: 'Registration successful',
        token,
        data: {
          user: {
            id: user._id,
            firstName: user.firstName,
            lastName: user.lastName,
            email: user.email,
            phone: user.phone,
            role: user.role,
          },
          wallet: {
            balance: wallet.balance,
            virtualAccountNumber: wallet.virtualAccountNumber,
            virtualAccountName: wallet.virtualAccountName,
            virtualAccountBank: wallet.virtualAccountBank,
          },
        },
      });
    } catch (error) {
      logger.error('Error in registerRider:', error);
      return next(new AppError('Registration failed. Please try again later.', 500));
    }
  });
});

// Register driver - Fixed
const registerDriver = asyncHandler(async (req, res, next) => {
  // First run validation
  validateDriverRegistration(req, res, async (err) => {
    if (err) return next(err);
    
    try {
      const {
        firstName,
        lastName,
        email,
        phone,
        password,
        vehicleType,
        vehicleMake,
        vehicleModel,
        vehicleColor,
        licensePlate,
        driversLicense,
        driversLicenseExpiry,
        vehicleInsurance,
        vehicleRegistration,
      } = req.body;

      // Check if email or phone already exists
      const userExists = await User.findOne({ $or: [{ email }, { phone }] });
      if (userExists) {
        if (userExists.email === email) {
          return next(new AppError('User already exists with this email', 409));
        } else {
          return next(new AppError('User already exists with this phone number', 409));
        }
      }

      // Check if license plate is already registered
      const driverExists = await Driver.findOne({ licensePlate });
      if (driverExists) {
        return next(new AppError('A vehicle with this license plate is already registered', 409));
      }

      // Create user with driver role
      const user = await User.create({
        firstName,
        lastName,
        email,
        phone,
        password, // password is hashed via model pre-save middleware
        role: 'driver',
        isVerified: false, // Drivers need approval
      });

      if (!user) {
        return next(new AppError('Failed to create driver account', 500));
      }

      // Create driver details
      const driver = await Driver.create({
        user: user._id,
        vehicleType,
        vehicleMake,
        vehicleModel,
        vehicleColor,
        licensePlate,
        driversLicense,
        driversLicenseExpiry: new Date(driversLicenseExpiry),
        vehicleInsurance,
        vehicleRegistration,
        isAvailable: false, // Drivers start as unavailable until approved
        isApproved: false,
      });

      if (!driver) {
        // If driver details creation fails, delete the user and return error
        await User.findByIdAndDelete(user._id);
        return next(new AppError('Failed to create driver details', 500));
      }

      // Create wallet for the driver
      const wallet = await Wallet.create({
        user: user._id,
        balance: 0,
      });

      if (!wallet) {
        // If wallet creation fails, delete the user and driver details
        await User.findByIdAndDelete(user._id);
        await Driver.findByIdAndDelete(driver._id);
        return next(new AppError('Failed to create driver wallet', 500));
      }

      // Try to create virtual account (non-blocking)
      try {
        const virtualAccountData = await createVirtualAccount(user);
        if (virtualAccountData) {
          wallet.virtualAccountNumber = virtualAccountData.accountNumber;
          wallet.virtualAccountName = virtualAccountData.accountName;
          wallet.virtualAccountBank = virtualAccountData.bankName;
          await wallet.save();
        }
      } catch (error) {
        logger.error('Error creating virtual account:', error);
        // Continue registration even if virtual account creation fails
      }

      // Generate token
      const token = generateToken(user._id);

      // Return success response
      return res.status(201).json({
        status: 'success',
        message: 'Driver registration successful. Awaiting approval by admin.',
        token,
        data: {
          user: {
            id: user._id,
            firstName: user.firstName,
            lastName: user.lastName,
            email: user.email,
            phone: user.phone,
            role: user.role,
            isVerified: user.isVerified,
          },
          driver: {
            id: driver._id,
            vehicleType: driver.vehicleType,
            licensePlate: driver.licensePlate,
            isApproved: driver.isApproved,
          },
          wallet: {
            balance: wallet.balance,
            virtualAccountNumber: wallet.virtualAccountNumber,
            virtualAccountName: wallet.virtualAccountName,
            virtualAccountBank: wallet.virtualAccountBank,
          },
        },
      });
    } catch (error) {
      logger.error('Error in registerDriver:', error);
      return next(new AppError('Registration failed. Please try again later.', 500));
    }
  });
});

// Login user - Fixed
const login = asyncHandler(async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Check if email and password exist
    if (!email || !password) {
      return next(new AppError('Please provide email and password', 400));
    }

    // Check if user exists
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return next(new AppError('Incorrect email or password', 401));
    }

    // Check if password is correct
    const isPasswordCorrect = await user.comparePassword(password);
    if (!isPasswordCorrect) {
      return next(new AppError('Incorrect email or password', 401));
    }

    // Check if user is active
    if (!user.isActive) {
      return next(new AppError('Your account has been deactivated. Please contact admin.', 401));
    }

    // Generate token
    const token = generateToken(user._id);

    // Get wallet info
    const wallet = await Wallet.findOne({ user: user._id });
    if (!wallet) {
      logger.error(`Wallet not found for user: ${user._id}`);
    }

    // Additional driver info if user is a driver
    let driverInfo = null;
    if (user.role === 'driver') {
      driverInfo = await Driver.findOne({ user: user._id });
      if (!driverInfo) {
        logger.error(`Driver details not found for user: ${user._id}`);
      }
    }

    // Return success response
    return res.status(200).json({
      status: 'success',
      message: 'Login successful',
      token,
      data: {
        user: {
          id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          phone: user.phone,
          role: user.role,
          isVerified: user.isVerified,
        },
        wallet: wallet ? {
          balance: wallet.balance,
          virtualAccountNumber: wallet.virtualAccountNumber,
          virtualAccountName: wallet.virtualAccountName,
          virtualAccountBank: wallet.virtualAccountBank,
        } : null,
        driver: driverInfo ? {
          id: driverInfo._id,
          vehicleType: driverInfo.vehicleType,
          licensePlate: driverInfo.licensePlate,
          isApproved: driverInfo.isApproved,
          isAvailable: driverInfo.isAvailable,
        } : null,
      },
    });
  } catch (error) {
    logger.error('Error in login:', error);
    return next(new AppError('Login failed. Please try again later.', 500));
  }
});

module.exports = {
  registerRider,
  registerDriver,
  login,
};
