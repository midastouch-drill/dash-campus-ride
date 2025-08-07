const express = require('express');
const { squadWebhook } = require('../controllers/webhookController');

const router = express.Router();

/**
 * @swagger
 * /api/v1/webhooks/squad:
 *   post:
 *     summary: Process Squad payment webhook
 *     tags: [Webhooks]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Webhook processed successfully
 */
router.post('/squad', squadWebhook);

module.exports = router;
