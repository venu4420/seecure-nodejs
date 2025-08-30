const request = require('supertest');
const app = require('../src/app');

describe('API Endpoints', () => {
  test('GET /health should return healthy status', async () => {
    const response = await request(app)
      .get('/health')
      .expect(200);
    
    expect(response.body.status).toBe('healthy');
    expect(response.body.timestamp).toBeDefined();
  });

  test('POST /users should validate required fields', async () => {
    const response = await request(app)
      .post('/users')
      .send({})
      .expect(400);
    
    expect(response.body.error).toBe('Name and email are required');
  });
});