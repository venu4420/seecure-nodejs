const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const { Pool } = require('pg');
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');

const app = express();
const port = process.env.PORT || 8080;

app.use(helmet());
app.use(cors());
app.use(express.json());

let pool;

async function initDatabase() {
  const client = new SecretManagerServiceClient();
  const projectId = process.env.GOOGLE_CLOUD_PROJECT;
  
  console.log('Initializing database connection...');
  console.log('Project ID:', projectId);
  console.log('DB Host:', process.env.DB_HOST);
  console.log('DB User:', process.env.DB_USER);
  console.log('DB Name:', process.env.DB_NAME);
  
  try {
    const [dbPassword] = await client.accessSecretVersion({
      name: `projects/${projectId}/secrets/db-password/versions/latest`,
    });
    
    pool = new Pool({
      user: process.env.DB_USER || 'appuser',
      host: process.env.DB_HOST,
      database: process.env.DB_NAME || 'appdb',
      password: dbPassword.payload.data.toString(),
      port: 5432,
      ssl: false
    });

    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Database initialization failed:', error);
    process.exit(1);
  }
}

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/users', async (req, res) => {
  try {
    if (!pool) {
      return res.status(500).json({ error: 'Database not initialized' });
    }
    const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/users', async (req, res) => {
  const { name, email } = req.body;
  
  if (!name || !email) {
    return res.status(400).json({ error: 'Name and email are required' });
  }

  try {
    if (!pool) {
      return res.status(500).json({ error: 'Database not initialized' });
    }
    const result = await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

async function startServer() {
  await initDatabase();
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
}

if (require.main === module) {
  startServer();
}

module.exports = app;