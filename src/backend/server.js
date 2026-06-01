require('dotenv').config(); // 確保總機讀得到機密

const express = require('express');
const cors = require('cors');
const db = require('./db'); // 把你的資料庫連線檔案引入進來
const app = express();
app.use(cors());
app.use(express.json());


// I. 總機轉接中心 (路由管理)

// 1. 引入「上傳部門」的檔案
const uploadRoute = require('./routes/upload');

// 2. 設定轉接規則：只要網址開頭是 /api/upload，就交給 uploadRoute 處理
app.use('/api/upload', uploadRoute);


// II. 啟動伺服器

const PORT = process.env.PORT || 3000;
// 這是給 Flutter App 呼叫的真實 API
app.get('/api/users/:id', (req, res) => {
  const userId = req.params.id; // 抓取網址上的數字 1
  console.log(`📱 Flutter App 正在請求使用者 ${userId} 號的資料！`);
  
  // 寫 SQL 語法去 Aiven 資料庫撈資料
  const sql = 'SELECT * FROM users WHERE id = ?';
  
  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: "資料庫發生錯誤" });
    }
    
    if (results.length > 0) {
      // 成功找到！把資料庫裡的真實資料打包成 JSON 傳給 Flutter
      res.json(results[0]); 
    } else {
      res.status(404).json({ message: "找不到這位使用者" });
    }
  });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Piggo 後端總機已啟動！正在監聽 Port ${PORT}`);
});