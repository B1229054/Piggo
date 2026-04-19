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
        
        // 接收前端傳來的各種可能參數
        const { 
            uploadType, userId, tripId, postId, 
            lat, lng, locationName, sortOrder, poseName, category 
        } = req.body; 

        if (!file) {
            return res.status(400).json({ success: false, message: '沒有收到照片' });
        }

        // A. 決定存放 S3 的「資料夾名稱」
        let folderName = 'others';
        if (uploadType === 'avatar') folderName = 'avatars';
        else if (uploadType === 'trip_cover') folderName = 'trip_covers';
        else if (uploadType === 'trip_photo') folderName = 'trip_photos';
        else if (uploadType === 'post_photo') folderName = 'post_photos';
        else if (uploadType === 'pose') folderName = 'poses';
        else if (uploadType === 'chat_photo') folderName = 'chat_photos';

        const fileName = `${folderName}/${Date.now()}_${file.originalname}`;
        
        // B. 正式上傳到 S3
        const s3Params = {
            Bucket: process.env.AWS_BUCKET_NAME,
            Key: fileName,
            Body: file.buffer,
            ContentType: file.mimetype
        };
        await s3.send(new PutObjectCommand(s3Params));
        
        // S3 永久公開網址
        const imageUrl = `https://${process.env.AWS_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${fileName}`;

        // C. 總機分發邏輯 (決定寫入哪個 MySQL 資料表)
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
            const safeTripId = (tripId === 'null' || !tripId) ? null : tripId;
            await db.execute(
                `INSERT INTO trip_photos (trip_id, user_id, image_url, taken_at, lat, lng, location_name) VALUES (?, ?, ?, NOW(), ?, ?, ?)`, 
                [safeTripId, userId, imageUrl, lat || null, lng || null, locationName || null]
            );
        }

        // D. 回報成功給 App
        res.json({ success: true, message: `成功處理 ${uploadType} 類型的照片！`, imageUrl: imageUrl });

    } catch (error) {
        console.error('上傳處理失敗:', error);
        res.status(500).json({ success: false, message: '後端伺服器發生錯誤' });
    }
});

// 把這包設定匯出給總機
module.exports = router;