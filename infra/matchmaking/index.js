const AWS = require('aws-sdk');
const express = require('express');
const app = express();

// Configure AWS SDK for LocalStack
AWS.config.update({
  region: 'us-east-1',
  endpoint: 'http://localhost:4566'
});

const dynamoDb = new AWS.DynamoDB.DocumentClient();

app.use(express.json());
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  next();
});

// Matchmaking endpoint
app.post('/matchmaking/find', async (req, res) => {
  console.log('Matchmaking request:', req.body);

  try {
    // Simulate finding a match for local testing
    const response = {
      serverUrl: 'ws://localhost:8081/room/test-' + Date.now(),
      roomId: 'test-' + Date.now(),
      token: 'local-dev-token-' + Date.now(),
      estimatedWait: 5,
      message: 'Match found (LocalStack simulation)'
    };

    // Optional: Store in DynamoDB for persistence
    if (process.env.USE_DYNAMODB === 'true') {
      const params = {
        TableName: 'LittleSix-Lobbies',
        Item: {
          roomId: response.roomId,
          serverUrl: response.serverUrl,
          token: response.token,
          createdAt: new Date().toISOString(),
          status: 'waiting'
        }
      };

      try {
        await dynamoDb.put(params).promise();
        console.log('Stored lobby in DynamoDB:', response.roomId);
      } catch (dbError) {
        console.warn('DynamoDB not available, continuing without persistence');
      }
    }

    res.json(response);
  } catch (error) {
    console.error('Matchmaking error:', error);
    res.status(500).json({
      error: 'Matchmaking failed',
      message: error.message
    });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    localstack: process.env.USE_DYNAMODB === 'true'
  });
});

// For Lambda compatibility (when deployed)
exports.handler = async (event) => {
  console.log('Lambda matchmaking request:', event);

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify({
      serverUrl: 'ws://localhost:8081/room/test-' + Date.now(),
      roomId: 'test-' + Date.now(),
      token: 'local-dev-token-' + Date.now(),
      estimatedWait: 5,
      message: 'Match found (LocalStack simulation)'
    })
  };
};

// Start server if run directly (not as Lambda)
if (require.main === module) {
  const PORT = process.env.PORT || 3001;

  app.listen(PORT, () => {
    console.log(`🎯 Little Six Matchmaking Service running on port ${PORT}`);
    console.log(`   Health check: http://localhost:${PORT}/health`);
    console.log(`   Matchmaking:  POST http://localhost:${PORT}/matchmaking/find`);
    console.log(`   LocalStack:   ${process.env.USE_DYNAMODB === 'true' ? 'Enabled' : 'Disabled'}`);
  });
}