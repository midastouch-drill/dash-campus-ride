const express = require('express');
const { registerRider, registerDriver, login } = require('../controllers/authController');

const router = express.Router();

/**
 * @swagger
 * /api/v1/auth/register/rider:
 *   post:
 *     summary: Register a new rider
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - firstName
 *               - lastName
 *               - email
 *               - phone
 *               - password
 *             properties:
 *               firstName:
 *                 type: string
 *               lastName:
 *                 type: string
 *               email:
 *                 type: string
 *               phone:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       201:
 *         description: Rider registered successfully
 *       400:
 *         description: Validation error
 *       409:
 *         description: User already exists
 *       500:
 *         description: Server error
 */
router.post('/register/rider', registerRider);

/**
 * @swagger
 * /api/v1/auth/register/driver:
 *   post:
 *     summary: Register a new driver
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - firstName
 *               - lastName
 *               - email
 *               - phone
 *               - password
 *               - vehicleType
 *               - vehicleMake
 *               - vehicleModel
 *               - vehicleColor
 *               - licensePlate
 *               - driversLicense
 *               - driversLicenseExpiry
 *               - vehicleInsurance
 *               - vehicleRegistration
 *             properties:
 *               firstName:
 *                 type: string
 *               lastName:
 *                 type: string
 *               email:
 *                 type: string
 *               phone:
 *                 type: string
 *               password:
 *                 type: string
 *               vehicleType:
 *                 type: string
 *                 enum: [keke, cab]
 *               vehicleMake:
 *                 type: string
 *               vehicleModel:
 *                 type: string
 *               vehicleColor:
 *                 type: string
 *               licensePlate:
 *                 type: string
 *               driversLicense:
 *                 type: string
 *               driversLicenseExpiry:
 *                 type: string
 *                 format: date
 *               vehicleInsurance:
 *                 type: string
 *               vehicleRegistration:
 *                 type: string
 *     responses:
 *       201:
 *         description: Driver registered successfully
 *       400:
 *         description: Validation error
 *       409:
 *         description: User already exists or license plate already registered
 *       500:
 *         description: Server error
 */
router.post('/register/driver', registerDriver);

/**
 * @swagger
 * /api/v1/auth/login:
 *   post:
 *     summary: Login user
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 *       401:
 *         description: Invalid credentials
 *       400:
 *         description: Missing email or password
 *       500:
 *         description: Server error
 */
router.post('/login', login);

module.exports = router;
