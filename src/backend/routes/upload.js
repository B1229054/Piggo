// routes/upload.js
const express = require('express');
const router = express.Router(); // 建立這個部門的專屬分機
const multer = require('multer'); 
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");

const db = require('../db'); 

// 連線到 AWS S3 (東京機房)
const s3 = new S3Client({
    region: process.env.AWS_REGION,
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    }
});

// multer 設定：把 App 傳來的圖片暫存在記憶體中
const upload = multer({ storage: multer.memoryStorage() });

// 照片上傳
router.post('/', upload.single('photo'), async (req, res) => {
    try {
        const file = req.file; 
        
        // 1. 接收前端傳來的各種可能參數 (記得補上 taken_at)
        const { 
            uploadType, userId, tripId, postId, 
            lat, lng, locationName, sortOrder, poseName, category, taken_at, is_shared
        } = req.body; 

        if (!file) {
            return res.status(400).json({ success: false, message: '沒有收到照片' });
        }

        // 2. 防呆處理：整理好所有準備要存進資料庫的變數
        const finalLat = (lat === '' || lat === 'null' || lat === undefined) ? null : parseFloat(lat);
        const finalLng = (lng === '' || lng === 'null' || lng === undefined) ? null : parseFloat(lng);
        const safeTripId = (tripId === 'null' || !tripId) ? 1 : tripId; 
        const finalLocation = (locationName === '' || locationName === '定位中...' || locationName === 'null') ? null : locationName;
        const finalTakenAt = taken_at || new Date().toISOString(); // 如果沒傳時間，才用現在的時間
        const finalIsShared = (is_shared === 'false' || is_shared === '0') ? 0 : 1;

        // 3. 決定存放 S3 的「資料夾名稱」
        let folderName = 'others';
        if (uploadType === 'avatar') folderName = 'avatars';
        else if (uploadType === 'trip_cover') folderName = 'trip_covers';
        else if (uploadType === 'trip_photo') folderName = 'trip_photos';
        else if (uploadType === 'post_photo') folderName = 'post_photos';
        else if (uploadType === 'pose') folderName = 'poses';
        else if (uploadType === 'chat_photo') folderName = 'chat_photos';

        const fileName = `${folderName}/${Date.now()}_${file.originalname}`;
        
        // 4. 正式上傳到 S3 (誕生出 imageUrl)
        const s3Params = {
            Bucket: process.env.AWS_BUCKET_NAME,
            Key: fileName,
            Body: file.buffer,
            ContentType: file.mimetype
        };
        await s3.send(new PutObjectCommand(s3Params));
        
        // S3 永久公開網址
        const imageUrl = `https://${process.env.AWS_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${fileName}`;

        // 5. 總機分發邏輯
        if (uploadType === 'avatar') {
            await db.execute('UPDATE users SET avatar_url = ? WHERE id = ?', [imageUrl, userId]);
        } else if (uploadType === 'trip_cover') {
            await db.execute('UPDATE trips SET cover_image = ? WHERE id = ?', [imageUrl, tripId]);
        } else if (uploadType === 'post_photo') {
            await db.execute('INSERT INTO post_attachments (post_id, upload_photo_url, sort_order) VALUES (?, ?, ?)', [postId, imageUrl, sortOrder || 0]);
        } else if (uploadType === 'pose') {
            await db.execute('INSERT INTO pose_references (image_url, pose_name, category) VALUES (?, ?, ?)', [imageUrl, poseName || '未命名', category || 'general']);
        }  else if (uploadType === 'chat_photo') {
            await db.execute('INSERT INTO group_chat (trip_id, user_id, content, type, time) VALUES (?, ?, ?, ?, NOW())', [tripId, userId, imageUrl, 'image']);
        } else {
            // 預設為一般行程相簿
            await db.execute(
                `INSERT INTO trip_photos (trip_id, user_id, image_url, is_shared, taken_at, lat, lng, location_name) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                [safeTripId, userId, imageUrl, finalIsShared, finalTakenAt, finalLat, finalLng, finalLocation]
            );
        }

        // 6. 回報成功給 App
        res.json({ success: true, message: `成功處理 ${uploadType} 類型的照片！`, imageUrl: imageUrl });

    } catch (error) {
        console.error('上傳處理失敗:', error);
        res.status(500).json({ success: false, message: '後端伺服器發生錯誤' });
    }
});

// 取得特定行程的所有照片
router.get('/photos', async (req, res) => {
    try {
        // 從 Flutter 傳來的網址參數中拿出這三個關鍵變數
        const { userId, tripId, mode } = req.query;
        let query = "";
        let params = [];

        // 去 trip_photos 撈照片，去 users 抓出上傳者的名字
        const baseSql = `
            SELECT tp.*, u.username 
            FROM trip_photos tp
            JOIN users u ON tp.user_id = u.id
        `;

        // 審查模式：
        if (mode === 'all_mine') {
            // 【私人總相簿】只看 user_id 是自己的，不管在哪個行程
            query = `${baseSql} WHERE tp.user_id = ? ORDER BY tp.taken_at DESC`;
            params = [userId];

        } else if (mode === 'trip_view') {
            // 【行程共同相簿】
            if (!tripId) {
                return res.json({ success: true, data: [] }); // 沒傳行程 ID 就回傳空的
            }
            // 這個行程內，(大家公開的) + (自己私藏的)
            query = `
                ${baseSql} 
                WHERE tp.trip_id = ? 
                AND (tp.is_shared = 1 OR tp.user_id = ?) 
                ORDER BY tp.taken_at DESC
            `;
            params = [tripId, userId];

        } else {
            // 防呆機制
            return res.status(400).json({ success: false, message: '未知的相簿模式' });
        }

        // 執行 SQL 查詢並回傳結果
        const [rows] = await db.execute(query, params);
        res.json({ success: true, data: rows });

    } catch (error) {
        console.error('🚨 抓取照片失敗:', error);
        res.status(500).json({ success: false, message: '伺服器錯誤' });
    }
});

// 撈取使用者行程清單 API
router.get('/trips/user/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        
        // 去 trip_members 找該使用者的所有行程，並 JOIN trips 拿標題與時間
        const [rows] = await db.execute(
            `SELECT t.id, t.title, t.start_date, t.end_date 
             FROM trips t
             JOIN trip_members tm ON t.id = tm.trip_id
             WHERE tm.user_id = ?
             ORDER BY t.start_date DESC`,
            [userId]
        );
        
        res.json({ success: true, data: rows });
    } catch (error) {
        console.error('🚨 獲取行程清單失敗:', error);
        res.status(500).json({ success: false, message: '伺服器錯誤' });
    }
});

// 把這包設定匯出給總機
module.exports = router;