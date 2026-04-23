const AWS = require('aws-sdk');
const dynamoDb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  console.log('Matchmaking request:', event);
  
  // Simulate finding a match for local testing
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