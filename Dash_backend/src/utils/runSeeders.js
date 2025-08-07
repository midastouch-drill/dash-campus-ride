require('dotenv').config();
const mongoose = require('mongoose');
const logger = require('./logger');
const config = require('../config/config');
const { createAdminUser, seedTestData, runSeeders } = require('./seeder');

// Connect to MongoDB and run seeders
const runAllSeeders = async () => {
  try {
    // Log the MongoDB URI for debugging (without credentials if any)
    const uriForLogging = config.mongoURI.replace(/\/\/([^:]+):([^@]+)@/, '//***:***@');
    logger.info(`Attempting to connect to MongoDB at: ${uriForLogging}`);

    await mongoose.connect(config.mongoURI);

    logger.info('Connected to MongoDB successfully');

    // Run seeders
    logger.info('Creating admin user...');
    await createAdminUser();

    // Only run test data seeder in development environment
    if (config.nodeEnv !== 'production') {
      logger.info('Seeding test data...');
      await seedTestData();
    }

    logger.info('All seeders completed successfully');

    // Close the MongoDB connection
    await mongoose.connection.close();
    logger.info('MongoDB connection closed');

    process.exit(0);
  } catch (error) {
    logger.error(`Error running seeders: ${error.message}`);
    logger.error(error.stack);

    // Try to close connection if it's open
    if (mongoose.connection.readyState !== 0) {
      await mongoose.connection.close();
    }

    process.exit(1);
  }
};

// Run the seeders if this script is executed directly
if (require.main === module) {
  runAllSeeders();
}

module.exports = runAllSeeders;
