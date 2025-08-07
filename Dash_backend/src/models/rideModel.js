const mongoose = require('mongoose');

const rideSchema = new mongoose.Schema(
  {
    rider: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    driver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Driver',
      default: null,
    },
    status: {
      type: String,
      enum: ['requested', 'accepted', 'ongoing', 'completed', 'cancelled'],
      default: 'requested',
    },
    pickupLocation: {
      name: {
        type: String,
        required: true,
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },
    dropoffLocation: {
      name: {
        type: String,
        required: true,
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },
    distance: {
      type: Number, // in kilometers
      required: true,
    },
    duration: {
      type: Number, // in minutes
      required: true,
    },
    fare: {
      type: Number,
      required: true,
    },
    commissionAmount: {
      type: Number,
      default: 0,
    },
    driverAmount: {
      type: Number,
      default: 0,
    },
    paymentMethod: {
      type: String,
      enum: ['cash', 'wallet'],
      required: true,
    },
    paymentStatus: {
      type: String,
      enum: ['pending', 'paid'],
      default: 'pending',
    },
    startTime: {
      type: Date,
      default: null,
    },
    endTime: {
      type: Date,
      default: null,
    },
    riderRating: {
      type: Number,
      min: 1,
      max: 5,
      default: null,
    },
    driverRating: {
      type: Number,
      min: 1,
      max: 5,
      default: null,
    },
    cancellationReason: {
      type: String,
      default: null,
    },
    cancelledBy: {
      type: String,
      enum: ['rider', 'driver', 'system', null],
      default: null,
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

// Create index for geospatial queries
rideSchema.index({ 'pickupLocation.coordinates': '2dsphere' });

// Virtual field for rider's full name
rideSchema.virtual('riderName').get(function () {
  if (this.rider && typeof this.rider === 'object') {
    return this.rider.firstName && this.rider.lastName
      ? `${this.rider.firstName} ${this.rider.lastName}`
      : undefined;
  }
  return undefined;
});

// Virtual field for rider's phone number
rideSchema.virtual('riderPhone').get(function () {
  if (this.rider && typeof this.rider === 'object') {
    return this.rider.phone;
  }
  return undefined;
});

// Virtual field to determine if the ride has been rated
rideSchema.virtual('isRated').get(function() {
  // From driver's perspective
  if (this.driver && this.driverRating !== null) {
    return true;
  }
  
  // From rider's perspective
  if (this.rider && this.riderRating !== null) {
    return true;
  }
  
  return false;
});

// Pre-find middleware to populate rider data for virtuals
rideSchema.pre(/^find/, function(next) {
  this.populate({
    path: 'rider',
    select: 'firstName lastName phone'
  });
  next();
});

const Ride = mongoose.model('Ride', rideSchema);

module.exports = Ride;
