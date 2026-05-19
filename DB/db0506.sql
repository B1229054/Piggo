-- 關閉外鍵檢查，以便安全地 Drop 與建立關聯資料表
SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------
-- 清除舊資料表 (確保環境乾淨，依賴關係不衝突)
-- -----------------------------------------------------
DROP TABLE IF EXISTS user_packing_templates;
DROP TABLE IF EXISTS trip_packing_items;
DROP TABLE IF EXISTS trip_details;
DROP TABLE IF EXISTS qa_comments;
DROP TABLE IF EXISTS qa_likes;
DROP TABLE IF EXISTS qa_keep;
DROP TABLE IF EXISTS post_keep;
DROP TABLE IF EXISTS place_keep;
DROP TABLE IF EXISTS group_chat;
DROP TABLE IF EXISTS pose_references;
DROP TABLE IF EXISTS ai_chat_logs;
DROP TABLE IF EXISTS qa;
DROP TABLE IF EXISTS post_comments;
DROP TABLE IF EXISTS post_likes;
DROP TABLE IF EXISTS post_attachments;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS trip_photos;
DROP TABLE IF EXISTS vote_responses;
DROP TABLE IF EXISTS vote_options;
DROP TABLE IF EXISTS votes;
DROP TABLE IF EXISTS expense_shares;
DROP TABLE IF EXISTS expenses;
DROP TABLE IF EXISTS trip_members;
DROP TABLE IF EXISTS trips;
DROP TABLE IF EXISTS follows;
DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS users;

-- -----------------------------------------------------
-- 建立資料表
-- -----------------------------------------------------

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255),
    email VARCHAR(255) NULL UNIQUE,
    avatar_url VARCHAR(255),
    provider VARCHAR(255),
    provider_id VARCHAR(255),
    created_at DATETIME
);

CREATE TABLE user_profiles (
    user_id INT PRIMARY KEY,
    bio VARCHAR(255),
    personality_type VARCHAR(255),
    personality_tags JSON,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE follows (
    follower_id INT,
    following_id INT,
    PRIMARY KEY (follower_id, following_id),
    FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE trips (
    id INT AUTO_INCREMENT PRIMARY KEY,
    creator_id INT,
    title VARCHAR(255),
    start_date DATE,
    end_date DATE,
    cover_image VARCHAR(255),
    status VARCHAR(255),
    invite_code VARCHAR(255),
    created_at DATETIME,
    FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE trip_members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT,
    user_id INT,
    role VARCHAR(255),
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE expenses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT,
    payer_id INT,
    amount DECIMAL(10, 2),
    title VARCHAR(255),
    created_at DATETIME,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    FOREIGN KEY (payer_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE expense_shares (
    id INT AUTO_INCREMENT PRIMARY KEY,
    expense_id INT,
    user_id INT,
    amount DECIMAL(10, 2),
    is_paid BOOLEAN,
    FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE votes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT,
    creator_id INT,
    title VARCHAR(255),
    created_at DATETIME,
    state VARCHAR(5),
    start_time DATETIME,
    end_time DATETIME,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE vote_options (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vote_id INT,
    option_content VARCHAR(255),
    FOREIGN KEY (vote_id) REFERENCES votes(id) ON DELETE CASCADE
);

CREATE TABLE vote_responses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vote_option_id INT,
    user_id INT,
    FOREIGN KEY (vote_option_id) REFERENCES vote_options(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE trip_photos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT,
    user_id INT,
    image_url VARCHAR(255),
    is_shared BOOLEAN DEFAULT TRUE,
    taken_at DATETIME,
    lat DECIMAL(10, 8),
    lng DECIMAL(10, 8),
    location_name VARCHAR(255),
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    content TEXT,
    location_tag VARCHAR(255),
    created_at DATETIME,
    trip_id INT NULL,
    tags JSON,
    is_public BOOLEAN,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE SET NULL
);

CREATE TABLE post_attachments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT,
    trip_photo_id INT NULL,
    upload_photo_url VARCHAR(255) NULL,
    sort_order INT,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (trip_photo_id) REFERENCES trip_photos(id) ON DELETE SET NULL
);

CREATE TABLE post_likes (
    user_id INT,
    post_id INT,
    created_at DATETIME,
    PRIMARY KEY (user_id, post_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
);

CREATE TABLE post_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT,
    user_id INT,
    content TEXT,
    created_at DATETIME,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE qa (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    title VARCHAR(255),
    content TEXT,
    category VARCHAR(255),
    location_tag VARCHAR(255),
    created_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE ai_chat_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    user_query TEXT,
    ai_response TEXT,
    created_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE pose_references (
    id INT AUTO_INCREMENT PRIMARY KEY,
    image_url VARCHAR(255),
    pose_name VARCHAR(255),
    category VARCHAR(255)
);

CREATE TABLE group_chat (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT,
    user_id INT,
    content TEXT,
    type VARCHAR(10),
    time DATETIME,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE place_keep (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    google_place_id VARCHAR(255),
    place_name VARCHAR(255),
    address VARCHAR(255),
    lat DECIMAL(10, 8),
    lng DECIMAL(10, 8),
    created_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE post_keep (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    created_at DATETIME,
    post_id INT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
);

CREATE TABLE qa_keep (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    qa_id INT,
    created_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (qa_id) REFERENCES qa(id) ON DELETE CASCADE
);

CREATE TABLE qa_likes (
    user_id INT,
    qa_id INT,
    created_at DATETIME,
    PRIMARY KEY (user_id, qa_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (qa_id) REFERENCES qa(id) ON DELETE CASCADE
);

CREATE TABLE qa_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    qa_id INT,
    user_id INT,
    content TEXT,
    created_at DATETIME,
    FOREIGN KEY (qa_id) REFERENCES qa(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE trip_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT,
    day_number INT,
    sort_order INT,
    place_name VARCHAR(100),
    google_place_id VARCHAR(255),
    address VARCHAR(255),
    lat DECIMAL(10, 8),
    lng DECIMAL(10, 8),
    start_time TIME,
    stay_duration INT,
    transport_mode VARCHAR(255),
    transport_time INT,
    note TEXT,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
);

CREATE TABLE trip_packing_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trip_id INT,
    user_id INT,
    category VARCHAR(255),
    item_name VARCHAR(255),
    is_checked BOOLEAN,
    item_type VARCHAR(255),
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE user_packing_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    category VARCHAR(255),
    item_name VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 重新開啟外鍵檢查
SET FOREIGN_KEY_CHECKS = 1;
