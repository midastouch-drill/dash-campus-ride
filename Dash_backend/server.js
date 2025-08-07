require('dotenv').config();
console.log('MONGODB_URI:', process.env.MONGODB_URI);
const mongoose = require('mongoose');
const app = require('./src/app');
const config = require('./src/config/config');
const logger = require('./src/utils/logger');
const { runSeeders } = require('./src/utils/seeder');

// Port configuration
const PORT = config.port;

// Connect to MongoDB and start server
const startServer = async () => {
  try {
    await mongoose.connect(config.mongoURI);
    
    logger.info('Connected to MongoDB');

    // Run seeders in development mode or when explicitly requested
    if (config.nodeEnv !== 'production' || process.env.RUN_SEEDERS === 'true') {
      logger.info('Running database seeders...');
      await runSeeders().catch(err => {
        logger.error('Error during seeding:', err);
        // Continue server startup even if seeders fail
      });
      logger.info('All seeders completed successfully');
    }
    
    const server = app.listen(PORT, () => {
      logger.info(`Server running in ${config.nodeEnv} mode on port ${PORT}`);
      logger.info(`API Documentation available at: ${config.apiUrl}/api-docs`);
    });
    
    // Handle unhandled rejections
    process.on('unhandledRejection', (err) => {
      logger.error('UNHANDLED REJECTION! 💥 Shutting down...');
      logger.error(err.name, err.message);
      
      // Close server & exit process
      server.close(() => {
        process.exit(1);
      });
    });
    
    // Handle uncaught exceptions
    process.on('uncaughtException', (err) => {
      logger.error('UNCAUGHT EXCEPTION! 💥 Shutting down...');
      logger.error(err.name, err.message);
      process.exit(1);
    });
    
    // Handle SIGTERM signal
    process.on('SIGTERM', () => {
      logger.info('SIGTERM received. Shutting down gracefully');
      server.close(() => {
        logger.info('Process terminated!');
      });
    });
  } catch (error) {
    logger.error('Database connection error:', error);
    process.exit(1);
  }
};

startServer();