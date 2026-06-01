router.get('/user/:userId', async (req, res) => {
    try {
        const { userId } = req.params;

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
        console.error('獲取行程失敗:', error);
        res.status(500).json({ success: false, message: '無法取得行程清單' });
    }
});