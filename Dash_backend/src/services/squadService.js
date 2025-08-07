
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');

/**
 * Create a virtual account for a user using Squad API
 * @param {Object} user - User object
 * @returns {Promise<Object>} Virtual account details
 */
const createVirtualAccount = async (user) => {
  const squadApiKey = process.env.SQUAD_API_KEY;
  const squadApiUrl = process.env.SQUAD_API_URL || 'https://api.squadco.com';
  
  // Skip if no API key (for development/testing)
  if (!squadApiKey) {
    console.log('Squad API key not set. Skipping virtual account creation.');
    return null;
  }

  try {
    // Generate a unique reference
    const reference = `VA_${user._id}_${uuidv4().substring(0, 8)}`;

    const payload = {
      customer: {
        email: user.email,
        name: `${user.firstName} ${user.lastName}`,
        phone: user.phone,
      },
      permanent: true,
      preferred_bank: 'wema-bank',
      business_name: 'Dash University Rides',
      reference,
    };

    const response = await axios.post(`${squadApiUrl}/v1/virtual-accounts`, payload, {
      headers: {
        Authorization: `Bearer ${squadApiKey}`,
        'Content-Type': 'application/json',
      },
    });

    if (response.data && response.data.status === 200 && response.data.data) {
      const { account_number, account_name, bank_name } = response.data.data;
      return {
        accountNumber: account_number,
        accountName: account_name,
        bankName: bank_name,
      };
    }
    
    console.error('Failed to create virtual account:', response.data);
    return null;
  } catch (error) {
    console.error('Error creating virtual account:', error.response?.data || error.message);
    return null;
  }
};

module.exports = {
  createVirtualAccount,
};
