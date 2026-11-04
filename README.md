# 🐷 PIGGO：整合行程管理與社群分享的智慧旅遊應用系統

![Flutter Version](https://img.shields.io/badge/Flutter-3.19.0+-blue.svg)
![Dart Version](https://img.shields.io/badge/Dart-3.3.0+-blue.svg)
![Node.js](https://img.shields.io/badge/Node.js-Backend-green.svg)
![MySQL](https://img.shields.io/badge/Database-MySQL-blue.svg)

## 📖 前言 (Introduction)
要讓一群人順利出遊，從來不只是把行程安排好這麼簡單。從出發前的意見整合、旅途中的即時協助再到返程回憶分享，整個旅程都需要不斷溝通與協調。然而，現有 App 多半偏重行前規劃，且使用者需頻繁切換多個工具，導致操作流程零碎。

為此，我們開發 **PIGGO 智慧旅遊 App**，以 **AI 輔助與自動化協作**為核心，完整涵蓋旅行的「前、中、後」，自動化處理繁雜排程與事實查證，減輕旅伴負擔，讓多人出遊真正輕鬆順暢。

---

## 🖼️ 專題海報 (Project Posters)
> 💡 *點擊圖片可查看原圖*

| PIGGO 系統架構與特色 | PIGGO 核心功能展示 |
| :---: | :---: |
| <a href="https://github.com/user-attachments/assets/d3170f4d-b90e-4408-8656-f4264454039f" target="_blank"><img src="https://github.com/user-attachments/assets/d3170f4d-b90e-4408-8656-f4264454039f" width="400"></a> | <a href="https://github.com/user-attachments/assets/17d0a251-992a-4336-9741-1ccfdbd50955" target="_blank"><img src="https://github.com/user-attachments/assets/17d0a251-992a-4336-9741-1ccfdbd50955" width="400"></a> |

---
## 🎥 影音展示 (Videos)
> 💡 *點擊下方縮圖即可前往 YouTube 觀看 PIGGO 的實機操作與完整使用情境。*

| 💻 系統介紹與展示 (System Demo) | 🎬 實境使用情境 (Scenario Video) |
| :---: | :---: |
| [![系統展示影片預留](https://img.youtube.com/vi/請在這裡替換你的介紹影片ID/hqdefault.jpg)](https://www.youtube.com/watch?v=請在這裡替換你的介紹影片ID) | [![情境影片](https://img.youtube.com/vi/dnWTcvT2FMo/hqdefault.jpg)](https://www.youtube.com/watch?v=dnWTcvT2FMo) |
---

## ✨ 創意描述與亮點 (Innovations)

### 1. 🤖 AI 隨行協助：從動態排程到拍照指導
* **演算法與推薦機制**：透過「旅行人格測驗」量化喜好標籤，於後端運算群組偏好交集。結合 Google Maps API 距離計算，自動過濾出兼顧「大家喜好」與「路徑順暢」的最佳行程順序。
* **即時應變與拍照指導**：
  * 串接 OpenWeatherMap API 監控氣象與營業狀態，遇突發狀況主動預警並提供備案。
  * 結合 LBS 定位與 AI 視覺辨識，於拍攝畫面即時疊加「人物輔助線」與「動態姿勢微調提示」。
  * 支援人臉辨識共享相簿，自動分類照片，解決多人出遊收齊照片的痛點。

### 2. 🔄 全流程整合：規劃、出遊與分享相互銜接
* **自動化資料流串接**：群組投票結果即時寫入後端，自動篩選最高票景點並透過 Google Maps API 生成路線。行程規劃、行李清單與旅途提醒無縫接軌。
* **便利分享機制**：支援將他人的優質旅遊行程「一鍵匯入」個人計畫中，實現高互動的社群體驗。

### 3. 🤝 多人協作互助：讓每位旅伴都能參與
* **行前共編決策**：整合偏好分析、景點投票與行李清單認領，AI 亦會根據目的地氣候智慧推薦攜帶物品。
* **旅途 RAG 事實查證**：遇突發狀況可向社群提問，系統採用 RAG 架構，結合即時網路搜尋與 Google Places API，限制 AI 僅依據引文進行事實比對與摘要，避免幻覺產生。

---

## 📱 系統功能簡介 (Core Features)

1. **旅行人格測驗**：AI 萃取偏好標籤，精準推薦行程與景點。
2. **群組計畫與決策**：多人共編行程、共享行李清單與聊天室。AI 計算群組偏好交集主動推送景點，支援聊天室內發起投票。
3. **智慧相機**：內建 AI 拍照指導（輔助線與骨架提示），拍攝後一鍵同步至共享相簿。
4. **雙向交流社群**：
   * **推薦版**：分享與探索優質行程，支援一鍵匯入。
   * **問答版**：在地疑難雜症即時求助，AI 自動統整網友留言並進行事實查證。
5. **全域 AI 助手**：背景比對店家營業時間、提醒下個行程時間，並推播天氣警告。

---

## 🆚 系統特色與差異優勢 (Competitive Advantage)

| 痛點 | 傳統做法 / 現有 App | **PIGGO 的解決方案與優勢** |
| :--- | :--- | :--- |
| **工具分散** | 在 LINE、記事本與 Google Maps 間來回切換，容易產生資訊落差。 | **一站式整合群組決策**，從聊天室投票到自動產生路線皆在同一 App 內完成。 |
| **突發狀況** | 遇大雨或景點沒開，需自行手動重排行程，耗時且慌亂。 | **主動預警與動態應變**，結合氣象與營業狀態，主動發出提醒並直接提供「可執行的備案」。 |
| **資訊雜亂** | 網路論壇資訊破碎，難以辨別真偽。 | **RAG 事實查證**，AI 自動摘要社群留言並核實，快速提供正確解答。 |

---

## 🛠️ 開發工具與技術棧 (Tech Stack)

### 開發與運行環境
* **IDE**: Visual Studio Code, Xcode, Android Studio
* **前端框架**: Flutter (Dart)
* **後端框架**: Node.js (Express)
* **資料庫與儲存**: MySQL, Aiven 雲端資料庫, AWS S3 雲端儲存
* **支援系統**: Android 7.0+ / iOS 13+

### 核心整合技術
* **交通運輸服務**: 整合交通部 TDX (台鐵/高鐵時刻表 API)，支援跨運具轉乘規劃與時刻動態抓取。
* **地理資訊服務**: 整合 Google Maps API 與 OpenWeatherMap API，支援路徑串接與氣象狀態觸發。
* **狀態管理與同步**: 前端使用 `Provider`，透過 HTTP 與後端 API 溝通，確保多人協作畫面即時同步。
* **AI 語意輔助與推薦**: 後端透過 LLM 與提示詞工程，解析偏好標籤、計算交集並邏輯排序。
* **RAG 架構應用**: 結合即時網路搜尋與 Google Places API 上下文，限制 AI 依引文回答，確保正確性。

---

## 🚀 系統使用指南 (Quick Start)

1. **初始化與測驗**：首次開啟 APP 註冊後，系統自動引導進行「旅行人格測驗」，建立初始 AI 偏好模型。
2. **建立群組與計畫**：進入【計畫】分頁邀請好友。聊天室中，系統會依群組偏好交集推送 AI 行程卡片。
3. **無縫決策與排程**：點擊 AI 卡片「加入投票選項」發起表決。確認的景點將自動同步並串接至團隊行程表。
4. **行中儀表板**：旅遊當日切換至【首頁】，系統依行程表提供下一站導航、當下匯率、分帳工具，並透過 AI 推播天氣警告。

---

## 📁 專案結構 (Directory Structure)

```plaintext
PIGGO/
├── android/            # Android 原生設定檔
├── ios/                # iOS 原生設定檔
├── lib/                # Flutter 主要程式碼目錄
│   ├── main.dart       # 程式進入點與 Provider 全域宣告
│   ├── models/         # 資料模型 (User, Plan, Vote, Post)
│   ├── providers/      # 狀態管理邏輯 (Auth, PlanProvider, AIProvider)
│   ├── screens/        # 各大分頁 UI 畫面
│   │   ├── onboarding/ # 登入與旅行人格測驗
│   │   ├── plan/       # 行程計畫與聊天室投票
│   │   ├── home/       # 首頁儀表板與導航
│   │   ├── camera/     # 智慧相機
│   │   ├── profile/    # 個人社群頁面
│   │   └── community/  # 推薦版與交流版
│   ├── services/       # 外部 API 與 雲端服務操作層
│   └── widgets/        # 共用 UI 元件 (Buttons, Cards, Dialogs)
├── assets/             # 靜態圖片與 Icon 資源
├── pubspec.yaml        # 專案依賴套件設定檔
└── README.md           # 專案說明文件
## 開發團隊
專案開發成員 — B1229001 張詠淇 B1229005 王奕喬 B1229007 高思婕 B1229054 潘欣妤

指導教授：張賢宗教授



