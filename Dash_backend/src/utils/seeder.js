require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/userModel');
const Wallet = require('../models/walletModel');
const logger = require('./logger');
const config = require('../config/config');

// Create admin user
const createAdminUser = async () => {
  try {
    // Check if admin already exists
    const adminExists = await User.findOne({ role: 'admin' });
   
    if (adminExists) {
      logger.info('Admin user already exists');
      return;
    }
   
    // Create admin user - let the pre-save hook handle password hashing
    const admin = await User.create({
      firstName: 'Rasheed',
      lastName: 'Yekini',
      email: 'muhammadurasheed2002@gmail.com',
      phone: '07063638535',
      password: 'admin@1234', // Plain password - will be hashed by pre-save hook
      role: 'admin',
      isActive: true,
      isVerified: true,
    });
   
    // Create wallet for admin
    await Wallet.create({
      user: admin._id,
      balance: 0,
    });
   
    logger.info('Admin user created successfully');
   
  } catch (error) {
    logger.error('Error creating admin user:', error);
  }
};

// Function to seed test data
const seedTestData = async () => {
  if (process.env.NODE_ENV === 'production') {
    logger.warn('Skipping test data seeding in production environment');
    return;
  }
 
  try {
    // Add test data seeding logic here
    logger.info('Test data seeded successfully');
  } catch (error) {
    logger.error('Error seeding test data:', error);
  }
};

// Main function to run all seeders
const runSeeders = async () => {
  try {
    await createAdminUser();
    await seedTestData();
   
    logger.info('All seeders completed successfully');
    // Don't exit the process here when called from server.js
    return true;
  } catch (error) {
    logger.error('Error running seeders:', error);
    throw error; // Propagate the error up
  }
};

// Export functions for use in other files
module.exports = {
  createAdminUser,
  seedTestData,
  runSeeders
};

// Run seeders if this file is executed directly
if (require.main === module) {
  // Only exit process if this file is run directly
  runSeeders()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}