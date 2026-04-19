require('dotenv').config(); // 確保總機讀得到機密

const express = require('express');
const cors = require('cors');

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
// 🐷 這是給 Flutter App 呼叫的真實 API
app.get('/api/users/1', (req, res) => {
  console.log('📱 Flutter App 正在請求使用者 1 號的資料！');
  
  // 回傳 JSON 格式的資料，讓 Flutter 的 UserModel 翻譯
  res.json({
    id: 1,
    username: "Piggo 大師",
    avatar_url: "https://example.com/avatar.png"
  });
});
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Piggo 後端總機已啟動！正在監聽 Port ${PORT}`);
});