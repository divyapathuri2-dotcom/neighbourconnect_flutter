require('dotenv').config();

const mysql = require('mysql2/promise');

const requiredDatabaseVariables = [
  'DB_HOST',
  'DB_USER',
  'DB_PASSWORD',
  'DB_NAME',
];
const missingDatabaseVariables = requiredDatabaseVariables.filter(
  (name) => !process.env[name],
);

if (missingDatabaseVariables.length > 0) {
  throw new Error(
    `Missing database environment variables: ${missingDatabaseVariables.join(', ')}`,
  );
}

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

async function testConnection() {
  try {
    const connection = await pool.getConnection();

    console.log('MySQL connected successfully!');

    connection.release();
  } catch (error) {
    console.error('MySQL connection failed:', error.message);
  }
}

testConnection();

module.exports = pool;