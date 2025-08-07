const express = require('express');
const router = express.Router();
const { protect, restrictTo } = require('../middlewares/authMiddleware');
const { 
  getDriverProfile, 
  updateDriverProfile, 
  updateDriverAvailability, 
  updateDriverLocation, 
  getDriverRides,
  getDriverEarnings 
} = require('../controllers/driverController');

/**
 * @swagger
 * tags:
 *   name: Drivers
 *   description: Driver management endpoints
 */

/**
 * @swagger
 * /api/v1/drivers/profile:
 *   get:
 *     summary: Get driver profile
 *     tags: [Drivers]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Driver profile retrieved successfully
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Not a driver
 */
router.get('/profile', protect, restrictTo('driver'), getDriverProfile);

/**
 * @swagger
 * /api/v1/drivers/profile:
 *   patch:
 *     summary: Update driver profile
 *     tags: [Drivers]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               vehicleMake:
 *                 type: string
 *               vehicleModel:
 *                 type: string
 *               vehicleColor:
 *                 type: string
 *     responses:
 *       200:
 *         description: Driver profile updated successfully
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Not a driver
 */
router.patch('/profile', protect, restrictTo('driver'), updateDriverProfile);

/**
 * @swagger
 * /api/v1/drivers/availability:
 *   patch:
 *     summary: Update driver availability
 *     tags: [Drivers]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               isAvailable:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Driver availability updated successfully
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Not a driver or not approved
 */
router.patch('/availability', protect, restrictTo('driver'), updateDriverAvailability);

/**
 * @swagger
 * /api/v1/drivers/location:
 *   patch:
 *     summary: Update driver location
 *     tags: [Drivers]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               coordinates:
 *                 type: array
 *                 items:
 *                   type: number
 *                 minItems: 2
 *                 maxItems: 2
 *                 example: [3.3792, 6.5244]
 *     responses:
 *       200:
 *         description: Driver location updated successfully
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Not a driver
 */
router.patch('/location', protect, restrictTo('driver'), updateDriverLocation);

/**
 * @swagger
 * /api/v1/drivers/rides:
 *   get:
 *     summary: Get driver's rides
 *     tags: [Drivers]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [requested, accepted, ongoing, completed, cancelled]
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *     responses:
 *       200:
 *         description: Driver rides retrieved successfully
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Not a driver
 */
router.get('/rides', protect, restrictTo('driver'), getDriverRides);

/**
 * @swagger
 * /api/v1/drivers/earnings:
 *   get:
 *     summary: Get driver's earnings
 *     tags: [Drivers]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [daily, weekly, monthly, all]
 *           default: weekly
 *     responses:
 *       200:
 *         description: Driver earnings retrieved successfully
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Not a driver
 */
router.get('/earnings', protect, restrictTo('driver'), getDriverEarnings);

module.exports = router;
