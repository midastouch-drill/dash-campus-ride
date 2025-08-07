
# Dash - University Ride-Hailing API

A robust, scalable backend API for a university ride-hailing platform. This project serves as the backend for both a Flutter mobile app and a web admin dashboard.

## Features

- JWT Authentication for riders, drivers, and admins
- Real-time ride request, acceptance, and tracking
- Integrated payment processing with wallet system
- Driver management and ratings
- Admin dashboard for monitoring and analytics
- Comprehensive logging and error handling
- API documentation with Swagger
- Rate limiting and CORS protection

## Tech Stack

- Node.js & Express
- MongoDB with Mongoose
- JWT for Authentication
- Winston for Logging
- Swagger for API Documentation
- Squad Payment Gateway Integration

## Project Structure

```
.                   # Root of the project
├── .env            # Environment variables file 
├── server.js       # Main server entry point 
├── src/
│   ├── app.js          # Express app initialization
│   ├── config/         # Configuration files and environment setup
│   ├── controllers/    # Business logic for each feature
│   ├── middlewares/    # Auth, error handling, validation middlewares
│   ├── models/         # Mongoose schemas
│   ├── routes/         # API route definitions
│   ├── services/       # External service integrations
│   ├── utils/          # Helper functions
│   └── logs/           # Application logs (gitignored)
```

## Prerequisites

- Node.js (v14+)
- MongoDB (local or Atlas)
- npm or yarn
- Squad payment gateway account (for payment processing)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Muhammadurasheed/Dash.git
   cd dash
   ```

2. Install dependencies:
   ```bash
   npm install
   # or
   yarn install
   ```

3. Set up environment variables:
   ```bash
   cp .env
   # Edit .env with your configuration
   ```

4. Start the development server:
   ```bash
   npm run dev
   # or
   yarn dev
   ```

5. The server should be running at http://localhost:5000 (or your configured port)

## API Documentation

Swagger documentation is available at `/api-docs` when the server is running (e.g., http://localhost:5000/api-docs).

## Environment Variables

The following environment variables are required:

| Variable | Description | Example |
|----------|-------------|---------|
| PORT | Server port | 5000 |
| NODE_ENV | Environment (development/production) | development |
| MONGODB_URI | MongoDB connection URI | mongodb://localhost:27017/dash-rides |
| JWT_SECRET | Secret for JWT signing | your_jwt_secret_here |
| JWT_EXPIRES_IN | JWT token expiration | 30d |
| API_URL | Base URL for the API | http://localhost:5000 |
| SQUAD_API_KEY | Squad payment API key | your_squad_api_key |
| SQUAD_API_URL | Squad API URL | https://api.squadco.com |
| SQUAD_SECRET_HASH | Secret hash for webhook verification | your_squad_webhook_hash |
| BASE_FARE | Base fare for rides (Naira) | 200 |
| PRICE_PER_KM | Price per kilometer (Naira) | 100 |
| COMMISSION_PERCENTAGE | Platform commission percentage | 10 |
| MAX_DRIVER_DISTANCE | Maximum driver distance in meters | 5000 |

## Available Scripts

- `npm start` - Start the production server
- `npm run dev` - Start the development server with live reload
- `npm test` - Run tests (when implemented)

## API Endpoints

### Authentication
- POST `/api/v1/auth/register/rider` - Register a new rider
- POST `/api/v1/auth/register/driver` - Register a new driver
- POST `/api/v1/auth/login` - Login for riders, drivers, and admins

### Users
- GET `/api/v1/users/profile` - Get user profile
- PATCH `/api/v1/users/profile` - Update user profile
- PATCH `/api/v1/users/password` - Change password

### Drivers
- GET `/api/v1/drivers/profile` - Get driver profile
- PATCH `/api/v1/drivers/profile` - Update driver profile
- PATCH `/api/v1/drivers/availability` - Update driver availability
- PATCH `/api/v1/drivers/location` - Update driver location
- GET `/api/v1/drivers/rides` - Get driver's rides
- GET `/api/v1/drivers/earnings` - Get driver's earnings

### Rides
- POST `/api/v1/rides` - Request a new ride
- GET `/api/v1/rides` - Get user's ride history
- GET `/api/v1/rides/:rideId` - Get specific ride details
- PATCH `/api/v1/rides/:rideId/accept` - Driver accepts a ride
- PATCH `/api/v1/rides/:rideId/start` - Start a ride
- PATCH `/api/v1/rides/:rideId/complete` - Complete a ride
- PATCH `/api/v1/rides/:rideId/cancel` - Cancel a ride
- POST `/api/v1/rides/:rideId/rate` - Rate a completed ride

### Wallet
- GET `/api/v1/wallet/balance` - Get wallet balance
- GET `/api/v1/wallet/transactions` - Get wallet transactions

### Admin
- GET `/api/v1/admin/users` - Get all users
- GET `/api/v1/admin/users/:userId` - Get user details
- PATCH `/api/v1/admin/users/:userId` - Update user status
- GET `/api/v1/admin/drivers/pending` - Get pending driver approvals
- PATCH `/api/v1/admin/drivers/:driverId` - Approve/reject driver
- GET `/api/v1/admin/rides` - Get all rides
- GET `/api/v1/admin/transactions` - Get all transactions
- GET `/api/v1/admin/dashboard` - Get dashboard statistics
- POST `/api/v1/admin/wallet/topup` - Top up a user's wallet

## Testing

Testing setup is prepared with Jest and Supertest. Run tests with:
```bash
npm test
```

## Contributing

 CONTRIBUTING.md would be made available soon for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
