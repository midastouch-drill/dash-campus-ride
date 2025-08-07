const asyncHandler = require('express-async-handler');
const { AppError } = require('../middlewares/errorMiddleware');
const Wallet = require('../models/walletModel');
const Transaction = require('../models/transactionModel');
const { v4: uuidv4 } = require('uuid');

// Get wallet balance
const getWalletBalance = asyncHandler(async (req, res, next) => {
  // Find wallet for user
  const wallet = await Wallet.findOne({ user: req.user.id });
  if (!wallet) {
    return next(new AppError('Wallet not found', 404));
  }

  res.status(200).json({
    status: 'success',
    data: {
      wallet: {
        balance: wallet.balance,
        virtualAccountNumber: wallet.virtualAccountNumber,
        virtualAccountName: wallet.virtualAccountName,
        virtualAccountBank: wallet.virtualAccountBank,
      },
    },
  });
});

// Get wallet transactions
const getWalletTransactions = asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  // Find transactions for user
  const transactions = await Transaction.find({ user: req.user.id })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);

  // Get total count
  const totalCount = await Transaction.countDocuments({ user: req.user.id });

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

// Admin: Manual wallet top-up
const adminTopUpWallet = asyncHandler(async (req, res, next) => {
  const { userId, amount, description } = req.body;

  // Check if amount is valid
  if (!amount || amount <= 0) {
    return next(new AppError('Invalid amount', 400));
  }

  // Find wallet for user
  const wallet = await Wallet.findOne({ user: userId });
  if (!wallet) {
    return next(new AppError('Wallet not found', 404));
  }

  // Create a unique reference
  const reference = `ADMIN_TOPUP_${uuidv4()}`;

  // Create transaction
  const transaction = await Transaction.create({
    user: userId,
    type: 'credit',
    amount,
    description: description || 'Admin wallet top-up',
    reference,
    status: 'successful',
    paymentMethod: 'bank_transfer',
  });

  // Update wallet balance
  wallet.balance += amount;
  wallet.updatedAt = Date.now();
  await wallet.save();

  res.status(200).json({
    status: 'success',
    data: {
      transaction,
      wallet: {
        balance: wallet.balance,
      },
    },
  });
});

module.exports = {
  getWalletBalance,
  getWalletTransactions,
  adminTopUpWallet,
};
