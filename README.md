# PIGGO：整合行程管理與社群分享的智慧旅遊應用系統

![Flutter](https://img.shields.io/badge/Flutter-Dart-blue.svg)
![Node.js](https://img.shields.io/badge/Node.js-Express-green.svg)
![Database](https://img.shields.io/badge/Database-MySQL-orange.svg)

團隊成員： 張詠淇、王奕喬、高思婕、潘欣妤
指導教授： 張賢宗教授

## 前言
要讓一群人順利出遊，從來不只是把行程安排好這麼簡單。從出發前的意見整合、旅途中的即時協助再到返程回憶分享，整個旅程都需要不斷溝通與協調。然而，現有 App 多半偏重行前規劃，且使用者需頻繁切換多個工具，導致操作流程零碎。

為此，我們開發 **PIGGO 智慧旅遊 App**，以 **AI 輔助與自動化協作**為核心，完整涵蓋旅行的「前、中、後」，自動化處理繁雜排程與事實查證，減輕旅伴負擔，讓多人出遊真正輕鬆順暢。

---

##  專題海報

| PIGGO 系統架構與特色 | PIGGO 核心功能展示 |
| :---: | :---: |
| <a href="https://github.com/user-attachments/assets/d3170f4d-b90e-4408-8656-f4264454039f" target="_blank"><img src="https://github.com/user-attachments/assets/d3170f4d-b90e-4408-8656-f4264454039f" width="400"></a> | <a href="https://github.com/user-attachments/assets/17d0a251-992a-4336-9741-1ccfdbd50955" target="_blank"><img src="https://github.com/user-attachments/assets/17d0a251-992a-4336-9741-1ccfdbd50955" width="400"></a> |

---
##  影音展示 
>  *點擊下方縮圖即可前往 YouTube 觀看 PIGGO 的實機操作與完整使用情境。*

|  系統介紹與展示  |  實境使用情境  |
| :---: | :---: |
| [![系統展示影片](https://img.youtube.com/vi/61y5aUJO-uw/hqdefault.jpg)](https://www.youtube.com/watch?v=61y5aUJO-uw) | [![情境影片](https://img.youtube.com/vi/dnWTcvT2FMo/hqdefault.jpg)](https://www.youtube.com/watch?v=dnWTcvT2FMo) |
---
## 系統架構圖
<img src="https://github.com/user-attachments/assets/bd6d8750-81aa-44aa-8e78-ceca1e70e1d1" width="1000">

---

##  創意描述與亮點
* **旅行人格偏好與 AI 動態排程系統**：解決多人出遊常因喜好分歧難以抉擇，且手動調整順序、比對交通相當耗時的痛點。透過測驗量化喜好標籤並交叉比對推薦景點；支援投票選景點，並能根據現有行程與交通自動排列最佳順序。
* **AI 即時構圖與姿勢引導**：串聯 LBS 定位與 AI 視覺辨識，主動識別環境，於畫面即時疊加「人物輔助線」，並提供動態的「姿勢微調提示」。徹底降低拍攝失敗風險，實質提升使用者的社交情緒價值與成就感。
* **問答版與 AI 內容摘要並查證事實**：在旅遊當下如果臨時遇到交通或行程調整，透過 AI 整理問答、內容摘要與事實查證整合，讓使用者能直接提問並快速取得正確答案。
* **行李清單共編**：提供個人與團隊共用行李清單，成員可認領物品並追蹤進度，系統也會智慧推薦適合攜帶的物品，解決行前分工不明確的問題。
---
##  七大核心功能

1. **旅行人格測驗**：AI 根據結果給出對應的偏好標籤，精準推薦專屬行程與景點。
2. **計畫**：創建群組後，可以多人共同編輯行程、共享行李清單，群組投票、聊天等。AI 也會計算群組的偏好標籤最大交集，來進行景點推薦。
3. **首頁**：整合當地天氣、群組分帳、交通導航、翻譯匯率、下一站導航、附近景點推薦及定位分享。
4. **相機**：提供內建相機拍攝、AI 拍照指導及共享相簿功能。系統會分析環境，並透過畫面的輔助線與即時骨架提示來提供構圖與姿勢建議。
5. **我的**：使用者可發布貼文，分享行程與照片，為旅程留下回憶。
6. **交流**：「推薦版」可瀏覽他人旅遊行程並一鍵匯入到自己的行程中；「問答版」由附近及相關用戶解答突發狀況，AI 會自動統整摘要留言，並進行事實查證。
7. **全域 AI 助手**：負責比對店家營業時間與建議景點順序、提醒旅行中的天氣與下一個行程的時間。
---
##  系統畫面展示

| 交流版 | 首頁 | 計畫 |
| :---: | :---: | :---: |
| <img src="https://github.com/user-attachments/assets/6b692cbb-8ad5-4187-9f9a-6ab4c0ddad3e" width="250"> | <img src="https://github.com/user-attachments/assets/57723e08-0abd-4d14-b20e-4da087e33909" width="250"> | <img src="https://github.com/user-attachments/assets/41648154-8527-4c75-94a0-7574c967d835" width="250"> |
| **我的** | **推薦版** | **旅行人格測驗** |
| <img src="https://github.com/user-attachments/assets/1c1cf021-1f80-451a-b358-dbec8dfa89ce" width="250"> | <img src="https://github.com/user-attachments/assets/3d93d516-02dc-4ff5-93dc-702407b000af" width="250"> | <img src="https://github.com/user-attachments/assets/bd693907-50c0-42ea-addc-f4509b1fef99" width="250"> |
---

##  系統特色與差異優勢

| 痛點 | 傳統做法 / 現有 App | **PIGGO 的解決方案與優勢** |
| :--- | :--- | :--- |
| **工具分散** | 在 LINE、記事本與 Google Maps 間來回切換，容易產生資訊落差。 | **一站式整合群組決策**，從聊天室投票到自動產生路線皆在同一 App 內完成。 |
| **突發狀況** | 遇大雨或景點沒開，需自行手動重排行程，耗時且慌亂。 | **主動預警與動態應變**，結合氣象與營業狀態，主動發出提醒並直接提供「可執行的備案」。 |
| **資訊雜亂** | 網路論壇資訊破碎，難以辨別真偽。 | **RAG 事實查證**，AI 自動摘要社群留言並核實，快速提供正確解答。 |

---

##  開發工具與技術

### 開發與運行環境
* **IDE**: Visual Studio Code, Xcode, Android Studio
* **前端框架**: Flutter (Dart)
* **後端框架**: Node.js (Express)
* **資料庫與儲存**: 虛擬機 (整合 MySQL 關聯式資料庫與本地靜態照片儲存區)
* **支援系統**: Android 7.0+ / iOS 13+

### 核心整合技術
* **交通運輸服務**: 整合交通部 TDX (台鐵/高鐵時刻表 API)，支援跨運具轉乘規劃與時刻動態抓取。
* **地理資訊服務**: 整合 Google Maps API 與 OpenWeatherMap API，支援路徑串接與氣象狀態觸發。
* **狀態管理與同步**: 前端使用 `Provider`，透過 HTTP 與後端 API 溝通，確保多人協作畫面即時同步。
* **AI 語意輔助與推薦**: 後端透過 LLM 與提示詞工程，解析偏好標籤、計算交集並邏輯排序。
* **RAG 架構應用**: 結合即時網路搜尋與 Google Places API 上下文，限制 AI 依引文回答，確保正確性。

---

##  系統使用指南

1. **初始化與測驗**：首次開啟 APP 註冊後，系統自動引導進行「旅行人格測驗」，建立初始 AI 偏好模型。
2. **建立群組與計畫**：進入【計畫】分頁邀請好友。聊天室中，系統會依群組偏好交集推送 AI 行程卡片。
3. **無縫決策與排程**：點擊 AI 卡片「加入投票選項」發起表決。確認的景點將自動同步並串接至團隊行程表。
4. **行中儀表板**：旅遊當日切換至【首頁】，系統依行程表提供下一站導航、當下匯率、分帳工具，並透過 AI 推播天氣警告。
---

##  資料庫模型與架構
本專案後端資料庫採用關聯式資料庫 (MySQL) 搭配雲端儲存，主要資料表設計如下：

| 資料表 / 模組 | 關聯與功能說明 |
| :--- | :--- |
| **Users (使用者)** | 儲存帳號、密碼雜湊、旅行人格測驗結果 (偏好標籤) 與基本資料。 |
| **Plans (行程計畫)** | 儲存群組旅遊的總體計畫，關聯至所屬的 Users 群組。 |
| **Votes (投票決策)** | 紀錄各行程地點的提案人、投票狀態與最終結果，採用即時狀態同步。 |
| **Checklists (行李)** | 關聯至 Plans，儲存共編行李清單與認領狀態 (已準備 / 未準備)。 |
| **Posts (社群貼文)** | 儲存我的/交流版的貼文內容，關聯至虛擬機中的圖片路徑。 |

*(註：刪除使用者或行程時，採用 Cascade Delete 確保底下的投票與貼文資料一併連動清除。)*

---

##  核心 API 與服務串接流程
為了實現多人群組協作與 AI 即時運算，PIGGO 依賴以下資料流與外部服務：

| 功能情境 | 觸發端點 / 服務 | 處理流程與技術細節 |
| :--- | :--- | :--- |
| **AI 行程推薦** | `/api/ai/recommend` | 將群組成員的「偏好標籤」交集打包，發送至 LLM 解析，並結合 Google Maps API 篩選順暢路徑。 |
| **群組投票同步** | `Provider / Stream` | 前端觸發投票後，更新後端資料庫。透過 Flutter `StreamBuilder` 讓所有群組成員畫面在毫秒內同步更新。 |
| **RAG 旅遊問答** | `/api/rag/query` | 接收使用者提問，透過向量比對找出最相關的社群摘要或外部即時資訊，限制 AI 僅能依據上下文回答。 |
| **大眾運輸追蹤** | `TDX API` | 呼叫交通部 TDX 介面，取得高鐵/台鐵/捷運即時時刻表，提供下一站導航依據。 |
| **氣象與預警** | `OpenWeather API` | 背景監控定位與天氣 API，當降雨機率過高或遇極端天氣，推播前端顯示備案。 |

---

## 目前限制與資安考量
本專案目前以畢業專題與學術展示為主，未來若需正式上線至雙平台 (App Store / Google Play)，需進一步優化以下項目：

1. **Token 身分驗證機制**：目前 API 主要依賴基礎驗證，未來將全面導入 JWT (JSON Web Token) 確保每一次的 API 請求皆來自合法登入之使用者。
2. **流量與檔案限制**：使用者上傳至虛擬機的圖片與相簿，尚未實作嚴格的檔案大小限制與圖片壓縮機制，未來將加入邊緣運算 (Edge) 壓縮以節省頻寬。
3. **API 請求次數控管**：為避免惡意洗版或過度消耗外部 AI 與 Google Maps API 額度，未來將在 Node.js 後端加入請求速率限制。

---
##  未來展望 
- **離線模式支援**：導入 SQLite 本地快取，確保在無網路的山區或跨國班機上，仍可順利查看與編輯既有行程。
- **AR 擴增實境導航**：結合手機鏡頭，提供更直覺的「下一站」步行虛擬指標引導體驗，解決路痴看傳統地圖的困擾。
- **AI 收據辨識與智慧分帳**：結合 OCR 光學字元辨識技術，旅途中拍下收據即可自動帶入品項金額，並一鍵完成群組分帳。
- **多國語言即時翻譯**：強化跨國旅遊體驗，結合語音辨識與生成式 AI，實作雙向即時語音翻譯功能。

---

##  參考資源
感謝以下開源社群與公開資料平台，讓 PIGGO 得以實現豐富的系統功能：
* **[交通部 TDX 運輸資料流通服務](https://tdx.transportdata.tw/)**：提供全台精準的鐵路、高鐵與大眾運輸時刻表及轉乘資訊。
* **[OpenWeatherMap API](https://openweathermap.org/)**：支援即時氣象與天氣預警資料，幫助系統實現動態行程調整。
* **[Google Maps Platform](https://mapsplatform.google.com/)**：提供底層圖資、路線導航、Places API 與 Geocoding 地理編碼服務。

##  專案結構

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




