const mysql = require('mysql2');
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// ✅ Updated MySQL connection using a connection pool for better efficiency
const pool = mysql.createPool({
    host: '172.18.0.5', // MySQL container's IP address
    user: 'app_user',   // Matches MYSQL_USER
    password: 'app_password', // Matches MYSQL_PASSWORD
    database: 'react_app_db', // Matches MYSQL_DATABASE
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Test database connection with retry mechanism
const testDBConnection = () => {
    pool.getConnection((err, connection) => {
        if (err) {
            console.error('❌ Error connecting to MySQL:', err);
            setTimeout(testDBConnection, 5000); // Retry after 5 seconds
            return;
        }
        console.log('✅ Connected to MySQL');
        connection.release();
    });
};

testDBConnection(); // Initial connection check

// 🔹 Login Route
app.post('/login', (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Email and password required' });
    }

    const query = 'SELECT * FROM users WHERE email = ?';
    
    pool.query(query, [email], (err, results) => {
        if (err) {
            console.error('❌ Database query error:', err);
            return res.status(500).json({ message: 'Server error' });
        }

        if (results.length > 0 && results[0].password === password) {
            res.status(200).json({ message: 'Login successful', user: results[0] });
        } else {
            res.status(401).json({ message: 'Invalid credentials' });
        }
    });
});

// 🔹 Start the server
const PORT = 3001;
app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
});