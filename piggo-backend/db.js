// db.js
const mysql = require('mysql2/promise');
require('dotenv').config(); // 確保這個檔案能讀到 .env 裡面的秘密

const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT,
    ssl: { rejectUnauthorized: false},
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// 測試連線，確保一啟動就知道資料庫有沒有接通！
pool.getConnection()
    .then(connection => {
        console.log('✅ 資料庫連線成功！');
        connection.release(); // 測試完把連線放回水池
    })
    .catch(err => {
        console.error('❌ 資料庫連線失敗：', err);
    });

module.exports = pool;