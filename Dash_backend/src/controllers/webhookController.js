const asyncHandler = require('express-async-handler');
const crypto = require('crypto');
const { AppError } = require('../middlewares/errorMiddleware');
const Transaction = require('../models/transactionModel');
const Wallet = require('../models/walletModel');
const User = require('../models/userModel');
const logger = require('../utils/logger');
const config = require('../config/config');

// Squad payment webhook handler
const squadWebhook = asyncHandler(async (req, res, next) => {
  const payload = req.body;
  const signature = req.headers['squad-signature'];

  // Validate webhook signature
  if (!signature) {
    logger.warn('Missing Squad webhook signature');
    return res.status(200).end(); // Return 200 to avoid retries, but log the issue
  }

  // Verify webhook signature (if production)
  if (config.nodeEnv === 'production' && config.squad.secretHash) {
    const hash = crypto
      .createHmac('sha512', config.squad.secretHash)
      .update(JSON.stringify(payload))
      .digest('hex');
    
    if (hash !== signature) {
      logger.warn('Invalid Squad webhook signature');
      return res.status(200).end(); // Return 200 to avoid retries, but log the issue
    }
  }

  // Ensure required data is available
  if (!payload.data || !payload.data.transaction_ref) {
    logger.warn('Invalid webhook payload structure', payload);
    return res.status(200).end();
  }

  try {
    const { 
      data: { 
        transaction_ref, 
        amount,
        customer: { email },
        payment_status 
      } 
    } = payload;
    
    // Find the transaction by reference
    const transaction = await Transaction.findOne({ reference: transaction_ref });
    
    // If no matching transaction is found, this could be a direct account funding
    if (!transaction) {
      // Try to find user by email
      const user = await User.findOne({ email });
      if (!user) {
        logger.warn(`User with email ${email} not found for transaction ${transaction_ref}`);
        return res.status(200).end();
      }

      // Find user's wallet
      const wallet = await Wallet.findOne({ user: user._id });
      if (!wallet) {
        logger.warn(`Wallet not found for user ${user._id}`);
        return res.status(200).end();
      }

      // Create a new transaction for this payment
      if (payment_status === 'success') {
        // Create a transaction record
        await Transaction.create({
          user: user._id,
          type: 'credit',
          amount: amount / 100, // Convert from kobo to naira
          description: 'Wallet funding via Squad',
          reference: transaction_ref,
          status: 'successful',
          paymentMethod: 'virtual_account',
          paymentDetails: payload.data,
        });

        // Update wallet balance
        wallet.balance += amount / 100;
        wallet.updatedAt = Date.now();
        await wallet.save();

        logger.info(`Wallet funded for user ${user._id} with amount ${amount / 100}`);
      }
    } else {
      // Update existing transaction status based on webhook data
      if (payment_status === 'success' && transaction.status !== 'successful') {
        transaction.status = 'successful';
        transaction.updatedAt = Date.now();
        transaction.paymentDetails = payload.data;
        await transaction.save();

        // If this is a wallet funding transaction, update the wallet balance
        if (transaction.type === 'credit') {
          const wallet = await Wallet.findOne({ user: transaction.user });
          if (wallet) {
            wallet.balance += transaction.amount;
            wallet.updatedAt = Date.now();
            await wallet.save();
          }
        }

        logger.info(`Transaction ${transaction._id} marked as successful`);
      } else if (payment_status === 'failed' && transaction.status === 'pending') {
        transaction.status = 'failed';
        transaction.updatedAt = Date.now();
        transaction.paymentDetails = payload.data;
        await transaction.save();
        
        logger.info(`Transaction ${transaction._id} marked as failed`);
      }
    }

    // Return success response to Squad
    return res.status(200).json({ status: 'success' });
  } catch (error) {
    logger.error('Error processing Squad webhook:', error);
    // Still return 200 to avoid webhook retries
    return res.status(200).end();
  }
});

module.exports = {
  squadWebhook,
};
