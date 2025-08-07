
const mongoose = require('mongoose');

const driverSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    vehicleType: {
      type: String,
      enum: ['keke', 'cab'],
      required: [true, 'Vehicle type is required'],
    },
    vehicleMake: {
      type: String,
      required: [true, 'Vehicle make is required'],
    },
    vehicleModel: {
      type: String,
      required: [true, 'Vehicle model is required'],
    },
    vehicleColor: {
      type: String,
      required: [true, 'Vehicle color is required'],
    },
    licensePlate: {
      type: String,
      required: [true, 'License plate is required'],
      unique: true,
    },
    driversLicense: {
      type: String,
      required: [true, 'Driver\'s license is required'],
      unique: true,
    },
    driversLicenseExpiry: {
      type: Date,
      required: [true, 'Driver\'s license expiry date is required'],
    },
    vehicleInsurance: {
      type: String,
      required: [true, 'Vehicle insurance is required'],
    },
    vehicleRegistration: {
      type: String,
      required: [true, 'Vehicle registration is required'],
    },
    isApproved: {
      type: Boolean,
      default: false,
    },
    isAvailable: {
      type: Boolean,
      default: false,
    },
    currentLocation: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number],
        default: [0, 0], // [longitude, latitude]
      },
    },
    rating: {
      type: Number,
      default: 0,
    },
    totalRatings: {
      type: Number,
      default: 0,
    },
    completedRides: {
      type: Number,
      default: 0,
    },
    cancelledRides: {
      type: Number,
      default: 0,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Create a geospatial index on the currentLocation field
driverSchema.index({ currentLocation: '2dsphere' });

// Virtual populate for rides
driverSchema.virtual('rides', {
  ref: 'Ride',
  foreignField: 'driver',
  localField: '_id',
});

const Driver = mongoose.model('Driver', driverSchema);

module.exports = Driver;
