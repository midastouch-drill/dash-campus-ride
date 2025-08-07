const express = require('express');
const {
  requestRide,
  acceptRide,
  startRide,
  completeRide,
  cancelRide,
  getRideHistory,
  getDriverRideHistory,
  getRideDetails,
  rateRide,
} = require('../controllers/rideController');
const { protect, restrictTo } = require('../middlewares/authMiddleware');

const router = express.Router();

/**
 * @swagger
 * /api/v1/rides/request:
 *   post:
 *     summary: Request a new ride
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - pickupLocation
 *               - dropoffLocation
 *               - distance
 *               - duration
 *               - paymentMethod
 *             properties:
 *               pickupLocation:
 *                 type: object
 *                 required:
 *                   - name
 *                   - coordinates
 *                 properties:
 *                   name:
 *                     type: string
 *                   coordinates:
 *                     type: array
 *                     items:
 *                       type: number
 *                     minItems: 2
 *                     maxItems: 2
 *               dropoffLocation:
 *                 type: object
 *                 required:
 *                   - name
 *                   - coordinates
 *                 properties:
 *                   name:
 *                     type: string
 *                   coordinates:
 *                     type: array
 *                     items:
 *                       type: number
 *                     minItems: 2
 *                     maxItems: 2
 *               distance:
 *                 type: number
 *               duration:
 *                 type: number
 *               paymentMethod:
 *                 type: string
 *                 enum: [cash, wallet]
 *     responses:
 *       201:
 *         description: Ride requested successfully
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 */
router.post('/request', protect, restrictTo('rider'), requestRide);

/**
 * @swagger
 * /api/v1/rides/{rideId}/accept:
 *   post:
 *     summary: Driver accepts a ride
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: rideId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Ride accepted successfully
 *       400:
 *         description: Invalid request
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       404:
 *         description: Ride not found
 */
router.post('/:rideId/accept', protect, restrictTo('driver'), acceptRide);

/**
 * @swagger
 * /api/v1/rides/{rideId}/start:
 *   post:
 *     summary: Start ride
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: rideId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Ride started successfully
 *       400:
 *         description: Invalid request
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       404:
 *         description: Ride not found
 */
router.post('/:rideId/start', protect, restrictTo('driver'), startRide);

/**
 * @swagger
 * /api/v1/rides/{rideId}/complete:
 *   post:
 *     summary: Complete ride
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: rideId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Ride completed successfully
 *       400:
 *         description: Invalid request
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       404:
 *         description: Ride not found
 */
router.post('/:rideId/complete', protect, restrictTo('driver'), completeRide);

/**
 * @swagger
 * /api/v1/rides/{rideId}/cancel:
 *   post:
 *     summary: Cancel ride
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: rideId
 *         schema:
 *           type: string
 *         required: true
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: Ride cancelled successfully
 *       400:
 *         description: Invalid request
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       404:
 *         description: Ride not found
 */
router.post('/:rideId/cancel', protect, cancelRide);

/**
 * @swagger
 * /api/v1/rides/history:
 *   get:
 *     summary: Get rider's ride history
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *         description: Filter by status
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         description: Number of items per page
 *     responses:
 *       200:
 *         description: Rides retrieved successfully
 *       401:
 *         description: Unauthorized
 */
router.get('/history', protect, restrictTo('rider'), getRideHistory);

/**
 * @swagger
 * /api/v1/rides/driver/history:
 *   get:
 *     summary: Get driver's ride history
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *         description: Filter by status
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *         description: Number of items per page
 *     responses:
 *       200:
 *         description: Rides retrieved successfully
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Not a driver
 */
router.get('/driver/history', protect, restrictTo('driver'), getDriverRideHistory);

/**
 * @swagger
 * /api/v1/rides/{rideId}:
 *   get:
 *     summary: Get ride details
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: rideId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Ride details retrieved successfully
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       404:
 *         description: Ride not found
 */
router.get('/:rideId', protect, getRideDetails);

/**
 * @swagger
 * /api/v1/rides/{rideId}/rate:
 *   post:
 *     summary: Rate a ride
 *     tags: [Rides]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: rideId
 *         schema:
 *           type: string
 *         required: true
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - rating
 *             properties:
 *               rating:
 *                 type: number
 *                 minimum: 1
 *                 maximum: 5
 *               review:
 *                 type: string
 *     responses:
 *       200:
 *         description: Ride rated successfully
 *       400:
 *         description: Invalid request
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       404:
 *         description: Ride not found
 */
router.post('/:rideId/rate', protect, rateRide);

module.exports = router;
