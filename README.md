n8n 技術文章
============
作者：蔡明翰


**⚠️注意：本教學將在 Windows 11 系統上執行。**

摘要 (Abstract)
------------
本文章以 n8n 自動化工作流平台來實踐「每月自動寄送信件」的系統，透過不同的條件篩選寄送信件的對象，動態設置每月的寄送時機，並且依照不同的對象和月份自動修改部分信件內容。

此系統將會使用到兩個 n8n 工作流：
1. 將資料傳進資料庫 (PostgreSQL) 中
2. 透過資料庫中的資料篩選對象並寄送信件


藉由此系統，可展示 n8n 對於校務的應用價值：
* 無需一封一封手動寄送信件
* 無需自行比對對象和篩選條件
* 高擴充性 (可自行增加對象和篩選條件)
* 高移植性 (可輕易打包整個工作流並部屬在其他電腦上)


目錄(Catalog)
-------------
### 1. [n8n 的安裝和部署教學](#deployment)

* 本地 Docker 安裝
* 本地 n8n 安裝
* 本地 PostgreSQL 安裝
* n8n 和 PostgreSQL 的連接教學

### 2. [n8n 的基本節點和工作流認識](#introduction)

* 各節點的類型和功能介紹
* Credential 的介紹和設置
* 簡易工作流的介紹與示範
* 工作流的匯出
* 工作流的重新導入

### 3. [資料庫的基本節構和功能](#database)

* PostgreSQL 的節構介紹
* PostgreSQL 的欄位和規則建立
* PostgreSQL 的資料導入和刪除
* PostgreSQL 的資料查詢

### 4. [系統的架構和設計](#system)

* 試算表：資料欄位的形式
* 工作流1：資料傳進資料庫的具體架構
* 工作流2：寄送信件的具體架構
  
### 5. [校務自動化的應用實例](#result)

* 系統的執行結果
* 可行的系統擴充和延伸

### 6. [結語：n8n 的校務價值和創新可能性](#conclution)

* 低程式碼和與AI結合的優勢
* 未來可行的應用場景

### 7. [附錄](#appendix)

* workflow 資料夾：系統的工作流
* SQL script 資料夾：PostgreSQL 的 SQL Query




<h2 id="deployment">n8n 的安裝和部署教學</h2>

### 本地 Docker 安裝

Docker 是一個開源平台，用於開發、交付和運行應用程式。要讓一個應用程式在 Docker 上運作，其內包含三個關鍵的組件：
* **容器 (Container)**：容器是映像檔的一個可運行的實例。它是應用程式實際運行的地方。可以啟動、停止、移動或刪除容器。每個容器都彼此隔離。


* **映像檔 (Image)**：映像檔是一個只讀的模板，包含了建立容器的指令，像是應用程式的程式碼、所需的函式庫和環境設定等，相當於是容器的藍圖。

  
* **數據卷 (Volume)**：Volume 是一種機制，允許將主機檔案系統中的特定目錄掛載 (mount) 到容器內部的檔案系統中。它主要用來實現容器與主機之間的數據共享和數據持久化。

Docker 為建立本地 n8n 和本地資料庫 (PostgreSQL) 的基礎設施 (infrastructure) ，在處理 n8n 和資料庫之前，我們必須先下載並建立本地 Docker 。

首先到 [Docker 官網][docker_url]，找到 **Download Docker Desktop** ，接著點擊 **Download for Windows - AMD64** 來下載 Docker 。

  [docker_url]: https://www.docker.com/

<img width="1465" height="924" alt="image" src="https://github.com/user-attachments/assets/b23d5106-27a5-42f1-ac4a-0298262ffe30" />

開啟下載好的安裝檔，接著按 OK ，之後便等待 Docker 安裝完成。

<img width="871" height="604" alt="image" src="https://github.com/user-attachments/assets/66e00797-984a-4682-bc77-580023868317" />

安裝完成後，開啟 Docker Desktop ，選擇 **Accept** ，接著選擇 **Personal** ，然後便登入或註冊帳號(也可以選擇 Skip )，如此本地 Docker 便安裝完成了。

<img width="1571" height="887" alt="image" src="https://github.com/user-attachments/assets/c4be5b19-6dc6-4497-93f4-17303fd22651" />

備註：安裝完成後，若還沒安裝 WSL (適用於Linux的Windows子系統)，在進入Docker後會要求安裝，請將其裝好後重新啟動電腦再打開Docker。

### 本地 n8n 安裝

n8n 是一套開源 (Open Source) 的工作流程自動化工具。它的核心理念是讓使用者可以透過視覺化拖拉的方式，像堆樂高積木一樣，串接各種服務、API 與資料處理邏輯，從而自動化重複性的任務。寄送每月信件是件重複性高的工作，非常適合由 n8n 來執行。

上一步完成了 Docker 的安裝，接著要在本地端安裝 n8n 。

首先打開 Windows 的**命令提示字元** (可以在搜尋欄中輸入cmd來開啟) ，接著輸入以下指令：

    docker run --name n8n -p 5678:5678 -v n8n-file -d n8nio/n8n

以下為指令的解析：
* docker run：Docker 的基本指令，用於建立並啟動容器。
* --name n8n：用於指定容器名稱，在此設為 "n8n"。
* -p 5678:5678：用於連接埠映射 (Port mapping)，預設為5678:5678，不建議更動。
* -v n8n-file：用於指定 Volume 儲存位置，可設置 Volume 名稱或絕對路徑。設置為名稱時將由 Docker 來管理位置，並使用 Docker 來找取資料。設置為絕對路徑時則可直接從路徑中找取資料。在此使用 "n8n-file" 名稱。
* -d n8nio/n8n：用於指定運行方式與映像檔，在此為使用 "n8nio/n8n" 映像檔。

**⚠️注意：以上指令變數在容器創建之後皆無法再次變更。**

<img width="1466" height="647" alt="image" src="https://github.com/user-attachments/assets/05b34065-42d9-4a66-87a5-b0ff50b9298b" />

執行上列指令將自動下載 "n8nio/n8n" 映像檔，並由此創建一個名為 "n8n" 的容器。

<img width="1574" height="602" alt="image" src="https://github.com/user-attachments/assets/e83abfcd-caa0-4d7c-9942-81e505104609" />

<img width="1574" height="602" alt="image" src="https://github.com/user-attachments/assets/959aeff4-6f27-4848-bb70-b4eb85253407" />

到此，本地 n8n 便安裝完成了。

### 本地 PostgreSQL 安裝

PostgreSQL 是一個功能強大、穩定且高度符合標準的開放原始碼物件關聯式資料庫管理系統（ORDBMS）。在寄送信件之前，需要一個用來儲存信件內容和收件人的資料庫，以便讓 n8n 可以輕鬆讀取。

剛剛我們也安裝好本地 n8n，接著我們便要安裝PostgreSQL (資料庫)。

首先一樣首先打開 Windows 的**命令提示字元** (可以在搜尋欄中輸入cmd來開啟)，接著輸入以下指令：

    docker run --name PostgreSQL-school -e POSTGRES_USER=myuser -e POSTGRES_PASSWORD=mypassword -e POSTGRES_DB=schooldb -p 5432:5432 -v postgres-data -d postgres

以下為指令的解析：
* docker run：Docker 的基本指令，用於建立並啟動容器。
* --name n8n：用於指定容器名稱，在此設為 "PostgreSQL-school"。
* -e：環境變數，用於設置不同的環境數值。
  * POSTGRES_USER=myuser：POSTGRES_USER 用於設定使用者名稱，在此設為 "myuser"。
  * POSTGRES_PASSWORD=mypassword：POSTGRES_PASSWORD 用於設定密碼，在此設為 "mypassword"。
  * POSTGRES_DB=schooldb：POSTGRES_DB 用於設定和命名資料庫，在此設為 "schooldb"。
* -p 5432:5432：用於連接埠映射 (Port mapping)，預設為5678:5678，不建議更動。
* -v n8n-file：用於指定 Volume 儲存位置，可設置 Volume 名稱或絕對路徑。設置為名稱時將由 Docker 來管理位置，並使用 Docker 來找取資料。設置為絕對路徑時則可直接從路徑中找取資料。在此使用 "postgres-data" 名稱。
* -d n8nio/n8n：用於指定運行方式與映像檔，在此為使用 "postgres" 映像檔。

**⚠️注意：以上指令變數在容器創建之後皆無法再次變更。**

執行上列指令將自動下載 "postgres" 映像檔，並由此創建一個名為 "PostgreSQL-school" 的容器。

到此，本地 PostgreSQL 也安裝完成了。

### n8n 和 PostgreSQL 的連接教學

剛剛前面有提及，每個容器之間是互不干涉的，但是 n8n 和 PostgreSQL 分別裝在不同的容器中，那要怎麼讓他們互相溝通呢?

這時便需要在 Docker 內部架設一條網路 (network) 來實現容器和容器間的溝通。

打開 Windows 的**命令提示字元**，輸入以下指令：

    docker network create my_internal_net

此指令將在 Docker 中創建一條名為 "my_internal_net" 的網路。

剛剛也有提及，指令變數在容器創建之後便無法變更，所以我們需要重建容器來連接容器之間的網路。

輸入以下指令：

    docker rm n8n
    docker rm PostgreSQL-school

這兩個指令將分別刪除名為 "n8n" 和 "PostgreSQL-school" 的容器。

接著輸入原本創建 n8n 和 PostgreSQL 容器的指令，但在裡面再加上 "--network my_internal_net"

    docker run --name n8n --network my_internal_net -p 5678:5678 -v n8n-file -d n8nio/n8n
    
    docker run --name PostgreSQL-school --network my_internal_net -e POSTGRES_USER=myuser -e POSTGRES_PASSWORD=mypassword -e POSTGRES_DB=schooldb -p 5432:5432 -v postgres-data -d postgres

**⚠️注意：不可將變數設在 -d 之後，否則開啟容器時會出錯。**

如此，n8n 和 PostgreSQL 的容器便安裝完成，且有網路來讓彼此互相溝通。

到此，安裝的步驟就全部完成了。



<h2 id="introduction">n8n 的基本節點和工作流認識</h2>

在使用 n8n 之前，我們需要先將 n8n 的容器打開，並透過瀏覽器來開啟 n8n 頁面。

<img width="1575" height="494" alt="image" src="https://github.com/user-attachments/assets/8d65981f-bb2f-441d-b5df-683b1672460e" />

<img width="1571" height="857" alt="image" src="https://github.com/user-attachments/assets/eab7f477-6936-4514-a323-c39e1a54d2e3" />

接著便是填入你的註冊資訊，便可以開始執行 n8n 的作業了。

關於 free license key 的部分可拿可不拿，但是建議是拿一下，畢竟不拿白不拿。

拿到 license key 之後，前往 **Settings -> Usage and plan -> Enter activation key** 便可輸入 license key 來開通進階功能了。

前者全部完成之後，回到 n8n 主頁面，按下 **Start from scratch** 便可開始 n8n 之旅了。

### 各節點的類型和功能介紹

n8n 有許多不同類型和功能的節點，我將從其中挑選幾個重要或常用的來進行介紹。

**1. Trigger Manually**

<img width="306" height="223" alt="image" src="https://github.com/user-attachments/assets/d69efc4c-d30f-41dc-af9c-53318be56eef" />
<img width="456" height="100" alt="image" src="https://github.com/user-attachments/assets/23fcd836-cb1c-4701-b6df-5fe3352c0ff1" />

* 類型：觸發節點
* 功能：點擊 **Execute workflow** 後，此節點便會輸出一個信號，用來觸發在此之後的下個節點。

**2. Merge**

<img width="153" height="207" alt="image" src="https://github.com/user-attachments/assets/81fca06c-5877-4d3e-850e-69201b769ea9" />
<img width="469" height="97" alt="image" src="https://github.com/user-attachments/assets/6af9b189-d4cd-4d19-bb57-2e0577238eb3" />

* 類型：資料處理/資料變形節點
* 功能：此節點有兩個重要的功能：
  * 資料合併：將多條分支 (branch) 的資料合併。
  * 工作流檢查點 (checkpoint)：前面所有分支都必須完成才會繼續往下的流程。
 
**3. Google Gemini**

<img width="310" height="175" alt="image" src="https://github.com/user-attachments/assets/ca0b3b5c-1b53-4a9e-a511-35c1c4cb5580" />
<img width="481" height="74" alt="image" src="https://github.com/user-attachments/assets/7bdfb53a-b5a9-4aeb-8ea5-e925852c23d1" />

* 類型：AI節點
* 功能：此節點的功能十分強大，你可以透過它來詢問問題、分析圖片、轉錄語音、分析文件等。根據給予的提示詞 (prompt) 則會生成不同的回應。

**4. Gmail**

<img width="201" height="196" alt="image" src="https://github.com/user-attachments/assets/4c093aa2-4d02-4067-9299-c1442dc110c6" />
<img width="481" height="61" alt="image" src="https://github.com/user-attachments/assets/d575ca1b-a300-490c-8969-ce20db053845" />

* 類型：觸發/輸出節點
* 功能：根據節點的設定，此節點可以當作輸入或輸出節點。
  * 作為輸入：收到 Gmail 的時候此節點會自動觸發。
  * 作為輸出：此節點可向其他信箱發送訊息，或者將訊息標示為已讀/未讀、新增草稿、刪除特定信件等。

**5. Postgres**

<img width="227" height="205" alt="image" src="https://github.com/user-attachments/assets/c122e832-cf4c-4f7d-86cc-c5b5e2b5fe4d" />
<img width="481" height="69" alt="image" src="https://github.com/user-attachments/assets/9b561053-3dc6-46bd-901a-f62a00c6fd4c" />

* 類型：觸發/輸出節點
* 功能：根據節點的設定，此節點可以當作輸入或輸出節點。
  * 作為輸入：Postgres 中有檢測到特定活動時自動觸發。
  * 作為輸出：此節點可向 Postgres 資料庫做多項變動，例如新增一行資料、刪除特定資料、執行特定 SQL query 等。
 
**6. Code**

<img width="219" height="193" alt="image" src="https://github.com/user-attachments/assets/acca06e0-5eef-40ff-9dbf-394f263e7c54" />
<img width="469" height="87" alt="image" src="https://github.com/user-attachments/assets/4c539a94-350d-4ccc-bb1d-960adedc2337" />

* 類型：核心/邏輯控制節點
* 功能：算是最萬用的節點，藉由此節點可以用 Javascript/Python 程式來執行一般節點做不到的事情。

### Credential 的介紹和設置

前面我們介紹了幾個常用和重要的節點，接著我們要來介紹讓他們能運作的心臟：**Credential**。

Credential 可以說是讓 n8n 節點得以和各種 AI 工具、 API 和資料庫有效並安全溝通的鑰匙，像是 Google Gemini, Gmail, Postgres 皆需要有 Credential 才能正常運作。所以在使用這些節點之前，我們必須要先設置 Credential。

要新增 Credential，可以直接從該結點中新增，或者直接返回 n8n 主頁面 -> Credentials 來新增。

#### 1. Google Gemini

首先前往 [Google AI studio][google_ai_studio_url] 網頁，點選 **Get started**，接著執行各個註冊程序。

  [google_ai_studio_url]:https://aistudio.google.com/welcome?utm_source=PMAX&utm_medium=display&utm_campaign=FY25-global-DR-pmax-1710442&utm_content=pmax&gclsrc=aw.ds&gad_source=1&gad_campaignid=21772729580&gbraid=0AAAAACn9t66KgxFqg0b-uPDUBc_gGg3Qz&gclid=Cj0KCQiA6NTJBhDEARIsAB7QHD1s9RWtaHhnfuBdhsEx1-Iv3UkDVuMaX6tP8QTSqxDb1nzBQlEl0M8aAkzIEALw_wcB

註冊完成後，點選主頁面右下角的 **Get API key -> Create API key**。
  * Name your key 可留空
  * Choose an imported project 選擇 Create Project 並命名為 n8n-Google
  * 最後點選 Create key 則可拿到 API key

將拿到的 API key 複製下來，回到 n8n Credentials 頁面，新增 **Google Gemini** 的 Credential。

<img width="1488" height="630" alt="image" src="https://github.com/user-attachments/assets/29ee9abf-c9af-4363-b9c6-eff1938f6ec8" />

沒問題的話會顯示 **Connection tested successfully**，到此，Google Gemini 的 Credential 設置便完成了。

#### 2. PostgreSQL

首先打開 n8n Credentials 頁面，新增 **Postgres** 的 Credential。

這裡的 Credential 設置要按照你當初建立 PostgreSQL 容器時的指令變數來設置。
* Host：填入容器名稱 (--name 後的變數，預設為 "PostgreSQL-school")
* Database：填入資料庫名稱 (-e POSTGRES_DB= 後的變數，預設為 "schooldb")
* User：填入使用者名稱 (-e POSTGRES_USER= 後的變數，預設為 "myuser")
* Password：填入密碼 (-e POSTGRES_PASSWORD= 後的變數，預設為 "mypassword")

<img width="1483" height="686" alt="image" src="https://github.com/user-attachments/assets/f2ea4d5a-6611-4f72-94d0-57239faa9e90" />

設置完成後，點擊 **Save**，沒問題的話會顯示 **Connection tested successfully**，到此 PostgreSQL 的 Credential 也設置完成了。

#### 3. Gmail, Google Sheets, Google Drive

首先打開 n8n Credentials 頁面，新增 Gmail 的 Credential，將其中 **OAuth Redirect URL** 的內容記下來。

接著前往 [Google Cloud][google_cloud_url] 網頁，按**免費試用**，接著執行各個註冊程序。

  [google_cloud_url]:https://cloud.google.com/free?utm_source=google&utm_medium=cpc&utm_campaign=japac-TW-all-zh-dr-BKWS-all-core-trial-EXA-dr-1710102&utm_content=text-ad-none-none-DEV_c-CRE_768448051378-ADGP_Hybrid+%7C+BKWS+-+BRO+%7C+Txt+-+Generic+Cloud+-+Cloud+Generic+-+Core+GCP+-+TW_en-KWID_6458750523-aud-970366092687:kwd-6458750523&userloc_9222658-network_g&utm_term=KW_google%20cloud&gclsrc=aw.ds&gad_source=1&gad_campaignid=19506976549&gclid=EAIaIQobChMIv7XJ2ZKrkQMVQNIWBR3_2jSbEAAYASAAEgK--PD_BwE
  
前往 Google Cloud 主頁面，左上角**選取專案**。

<img width="385" height="66" alt="image" src="https://github.com/user-attachments/assets/b1a7c175-d147-4f03-9357-2d8f1b23cf5c" />

選擇**新增專案**，專案名稱可以自己取 (這裡取為 "n8n-tutorial")，接著按**建立**。

等待專案建立完成，在**選取專案**中選取該專案，接著便可前往下一步。

首先在上方搜尋欄中分別查找 Gmail, Google sheets, Google drive。

<img width="883" height="70" alt="image" src="https://github.com/user-attachments/assets/5e090eba-62bb-470a-a775-123ab6a79672" />\
<img width="879" height="66" alt="image" src="https://github.com/user-attachments/assets/7da79405-3a2a-4fba-b517-3b6e50d050cd" />
<img width="879" height="70" alt="image" src="https://github.com/user-attachments/assets/98888e6e-60ab-4098-8fd3-b5e9dd72fd3e" />

點進去後分別按下**啟用**。

全部啟用完畢後，在搜尋欄查找 OAuth。

<img width="869" height="66" alt="image" src="https://github.com/user-attachments/assets/b45d9544-81ac-4d0e-b022-95154ee465fe" />

點進去後，首先要設定 Google 驗證平台，點擊**開始**。

* 應用程式資訊：
  * 應用程式名稱：n8n
  * 使用者支援電子郵件：自己登入 Google Cloud 的電子郵件
* 目標對象：選擇**外部**
* 聯絡資訊： 自己登入 Google Cloud 的電子郵件
* 完成：勾選選項

最後按下**建立**，則成功設定驗證平台。

在同一個頁面 (OAuth)，左側欄選擇**目標對象 -> 測試使用者**，確認自己的 gmail 有沒有在其中。

<img width="665" height="294" alt="image" src="https://github.com/user-attachments/assets/20817fde-158f-46eb-a54c-3b0862426921" />

若無，則點選 **Add users**，並填入自己的 gmail。

接著在左側欄選擇**用戶端 -> 建立用戶端**。

* 應用程式類型：網頁應用程式
* 名稱：n8n
* 已授權的重新導向 URL：回到剛剛 n8n Credentials 的頁面，Gmail Credential 中的 **OAuth Redirect URL** 複製過去

接著按下**建立**，會出現**用戶端 ID**和**用戶端密碼**，將這兩項分別複製到 Gmail Credential 的對應欄位。

<img width="1479" height="722" alt="image" src="https://github.com/user-attachments/assets/ac6ecae2-01e3-434c-9ab2-3a012b21b96c" />

接著按下方的 **Sign in with Google**

<img width="620" height="394" alt="image" src="https://github.com/user-attachments/assets/2f285dc7-55c9-4093-8b4e-cb87c1043feb" />
<img width="604" height="848" alt="image" src="https://github.com/user-attachments/assets/d5f19f71-fb8e-4340-a0e2-10ae79513c0f" />

點擊**繼續**，看到 **Connection successful** 即代表成功。

Google sheet 和 Google drive 的 Credential 可直接使用**同一個**用戶端 ID和用戶端密碼，並且一樣要記得登入。

全部 Credential 設置完後， n8n Credentials 的頁面應該像下圖一樣。

<img width="1505" height="678" alt="image" src="https://github.com/user-attachments/assets/1e7c9885-49d0-4937-b712-6f97dbd2fe0c" />

至此，我們所需要的 Credential 便設置完成了。

備註：若在設定完全部的 Credential 之前關閉 Google Cloud OAuth 頁面，用戶端密碼將無法再被複製，這時可以點擊 **Add secret** 來取得額外的密碼 (同個用戶端最多只能有兩個密碼)。


### 簡易工作流的介紹與示範

這裡我們創建一個簡單的工作流，用以示範各節點如何運行。

# 待完成

### 工作流的匯出

在 n8n，匯出工作流是一件非常簡單的事，只需要一個按鍵便可以搞定。

在工作流頁面中，右上角 **Save** 旁有 **...** 的按鈕，接著選擇 **Download** 便可將工作流下載下來了。下載下來的工作流將會以 **json** 的格式儲存。

<img width="520" height="398" alt="image" src="https://github.com/user-attachments/assets/904c85bc-87fb-4753-bdef-14c0582c229b" />

### 工作流的重新導入

導入 n8n 工作流同樣是一件只需要一個按鍵便能搞定的事情。你也可以在不同的裝置上導入工作流，這便是 n8n 的高移植性。

在空白的工作流頁面中，同樣選擇 **...** 按鈕，這次選擇 **Import from File**，接著選擇下載下來的 **json** 檔，便可重新導入工作流。

**⚠️注意：重新導入工作流後，需要 Credential 的節點皆會預設為未選擇 Credential，需要點入每個需要 Credential 的節點重新選擇。若將工作流導入到新裝置，請確保有重新建立各個 Credential。**



<h2 id="database">資料庫的基本節構和功能</h2>

n8n 能夠利用的資料庫有很多種，例如 MySQL, Oracle Database, Supabase等，而這裡我們要利用的則是 PostgreSQL。

PostgreSQL 可以算是所有資料庫中功能最齊全、且最具彈性的選擇，接下來我將就等等會用到的部分進行簡單的講解。

### PostgreSQL 的節構介紹

首先為 PostgreSQL 的整體結構，因為我們暫時只會用到儲存、讀取資料的功能，這裡我們將聚焦於 **Schemas** 中 **Tables** 的部分。

<img width="336" height="932" alt="image" src="https://github.com/user-attachments/assets/ae398c49-0a2f-4bf9-bfc1-55300ba7f070" />

<img width="459" height="394" alt="image" src="https://github.com/user-attachments/assets/eb892be2-a6e7-49a8-8e01-d6a26b0e91ca" />

在 Tables 中，這裡可以看到我們所創建的各個資料，你可以想像每個 table 皆對應著一個 Excel 表格 (在這裡為 project_code_info 和 project_host_info)。

* **Columns**：table 的各個資料欄位，你可以想像成 Excel 表格中對應的每一**列**。

* **Constraints**：table 的資料限制，會對輸入進的資料施加**規則**，當滿足或違反特定規則時對資料施加特定動作 (通常為拒絕該資料或覆蓋元資料)。

* **Indexes**： table 的索引。PostgreSQL 可以對各個 Column 進行索引化，如此在讀取資料時，便可用更快的速度取得資料，只不過代價是要消耗更多記憶體空間。

以上為我們「每月自動寄送信件」系統所會用到的功能，剩下的功能因為跟此系統無關，所以暫時不論。

### PostgreSQL 的欄位和規則建立

在 PostgreSQL 上建立 table 有很多種方法，這裡我們將直接使用 n8n 來建立。

首先隨便開起一個工作流，在裡面添加一個 Postgres 的節點，並選擇 **Execute a SQL query**。

所謂的 SQL query，可以當作是資料庫版本的程式碼，用於執行各種較複雜的指令。

這裡我們將分別使用 SQL Script 資料夾中：
* part_time_main_info_CREATE：建立 part_time_main_info 的 table
* project_code_info_CREATE：建立 project_code_info 的 table
* project_host_info_CREATE：建立 project_host_info 的 table

每個 SQL query 皆包含對應 column, constraint 和 index 的建立，詳細的部分可參考 query 中的註解。

將每個 SQL query 複製並添加到 **Execute a SQL query** 節點中，並按下右上角的 **Execute step** 即可執行 (只會執行該節點，不會執行整個工作流)。

### PostgreSQL 的資料導入和刪除

導入和刪除資料的部分，都可以透過 n8n 的 Postgres 節點完成。

在輸入的部分，我們通常會使用 **Insert, Insert or Update, Update** 這三種模式來執行。
* Insert：直接向該 table 添加資料
* Insert or Update (Upsert)：檢查 constraints，若符合條件則**更新**特定已存在資料，否則**新增**該筆資料
* Update：檢查 constraints，若符合條件則**更新**特定資料已存在資料，否則不做任何動作

在刪除部分，通常使用 **Delete** 來執行，而這又分成三種模式。
* Truncate：將整個 table 的資料清空，但保留 table 的整體架構 (column, constraint, index..)
* Delete：藉由特定條件刪除 table 中的特定資料
* Drop：直接將整個 table 刪除

以上為簡要的資料導入和刪除方法，更多的部分將在介紹「每月自動寄送信件」系統的工作流時講解。

### PostgreSQL 的資料查詢

在查詢 (輸出) 的部分，通常使用 **Select, Execute Query** 兩種模式執行。
* Select：直接搜索並輸出特定行的資料
* Execute Query：透過 SQL query 使用特殊的方法篩選、組合並輸出資料

這裡舉例一個用 SQL query 查詢資料的方法：

```sql
(
    SELECT
        'PERSONNEL' AS data_type,  -- 標記數據來源為人員資訊
        id,
        project_code,
        NULL AS corresponding_project,
        NULL AS code_filter_condition
    FROM
        part_time_main_info
)

UNION ALL

(
    SELECT
        'PROJECT' AS data_type,    -- 標記數據來源為專案資訊
        NULL AS id,
        NULL AS project_code,
        corresponding_project,
        code_filter_condition
    FROM
        project_code_info
);
```

執行該 query，將會輸出從 part_time_main_info 和 project_code_info 整合在一起的資料。
* part_time_main_info 只輸出 id 和 project_code 的 column
* project_code_info 輸出所有 column (corresponding_project, code_filter_condition)
* 兩者合併，彼此所缺失的 column 皆輸出為 NULL

以上為 PostgreSQL 資料查詢的簡易介紹和範例，更多的部分將在介紹「每月自動寄送信件」系統的工作流時講解。





<h2 id="system">系統的架構和設計</h2>

前面講了非常多，我們總算可以進入正題 - 介紹「每月自動寄送信件」的系統了。

只不過在介紹工作流之前，還有一件需要處理的事，那便是搞清楚要怎麼上傳資料，並了解資料的欄位和格式應該為何。

這裡請打開你的 **Google 試算表** (Google Sheets)，接著**創建新的試算表**。這個試算表便是我們輸入資料的地方。

試算表的名稱暫時改成「郵件資料_輸入」，然後看到左下角 "工作表1" 旁的 **+** 按鈕，點選它讓整個檔案有 **3** 個工作表。

接著我們重新命名各個工作表：
* 工作表1 -> PartTimeMainInfo
* 工作表2 -> ProjectCodeInfo
* 工作表3 -> ProjectHostInfo

如此，下方欄位應該長得像這樣：

<img width="769" height="49" alt="image" src="https://github.com/user-attachments/assets/b5de32f8-f5bb-4606-ad8c-b82a621b1539" />

接著到 PartTimeMainInfo 的工作表，創建各個欄位，如下圖：

<img width="1645" height="97" alt="image" src="https://github.com/user-attachments/assets/f44d51c6-08cb-4fb0-ad09-c2840ec17f58" />

然後是 ProjectCodeInfo，創建如下圖的欄位：

<img width="791" height="109" alt="image" src="https://github.com/user-attachments/assets/7a9984d8-0d5d-49b4-9f45-05179d29d838" />

最後是 ProjectHostInfo：

<img width="704" height="106" alt="image" src="https://github.com/user-attachments/assets/f94d88a3-be13-425d-bc51-4f73958f9ba8" />

如此我們便完成了基本資料輸入形式的創建。

這裡我將各個 n8n 工作流放入 workflow 的資料夾中：
* 1_Upload：此工作流負責將資料上傳到資料庫並交由 AI (Google Gemini) 進行對應處理
* 2_Send：此工作流負責將比較和讀取資料庫中的資料，並將其透過 Gmail 發送給特定的人

### 工作流1：資料傳進資料庫的具體架構

首先，將 "**1_Upload**" json 檔導入新的工作流中，工作流應該長的像下圖這樣：

<img width="1764" height="989" alt="image" src="https://github.com/user-attachments/assets/d69c788e-e461-47ec-9fda-62e128ffd41e" />

這裡要記得先把每個未選擇 Credential 的節點 (節點右下角有紅色警示符號的) 都重新設置對應的 Credential。

接下來便來介紹對應的節點：
* 開始執行：即 "Trigger manually"。按下 **Execute workflow** 後開始執行整個工作流。
* 重製所有 table：為 Execute Query 模式的 Postgres 節點。此節點所執行的 query 將重製所以的 table (part_time_main_info, project_code_info, project_host_info)。
* 取得試算表資料：這裡請把這個節點中的 **File -> From list** 後的檔案調整為 "**郵件資料_輸入**"，此節點將把此檔案 (試算表) 下載下來並交給下一個節點。
* Extract From XLSX
  * Get PartTimeMainInfo：取得 PartTimeMainInfo 工作表中各行的資訊並轉換為 json 格式。
  * Get ProjectCodeInfo：取得 ProjectCodeInfo 工作表中各行的資訊並轉換為 json 格式。
  * Get ProjectHostInfo：取得 ProjectHostInfo 工作表中各行的資訊並轉換為 json 格式。
* 變換日期格式：將日期變換格式 (範例：114/11 -> 2025-11)，使日期可以被資料庫所儲存。
* Edit Fields：將各個欄位轉換名稱，並剔除不必要的資料 (這個版本沒有會被剔除的資料)，使各個欄位可以被上傳到資料庫的對應欄位。
* Upsert (Insert or Update)
  * Upsert part_time_main_info：對輸入進的資料執行 Upsert，並上傳到 part_time_main_info table 中。
  * Upsert project_code_info：對輸入進的資料執行 Upsert，並上傳到 project_code_info table 中。
  * Upsert project_host_info：對輸入進的資料執行 Upsert，並上傳到 project_host_info table 中。
* 等待所有分支完成：即為 "Merge"，此處作為工作留的檢查點，所有前者的分支都要執行完成才會執行下一步。
* 提取資料庫資料：這個節點會提取來自 part_time_main_info 和 project_code_info 的資料。
  * part_time_main_info 會提取其 **id** 和 **project_code** 欄位；
  * project_code_info 會提取其 **corresponding_project** 和 **code_filter_condition** 欄位；
  * 提取完成後會將兩者資料結合，並交送給下一個節點。
* 將所有資料整合並建立prompt：Javascript 節點。這裡的 Javascript 會將前面所收到的資料全部整合，並且建立提示詞 (prompt)，準備傳送給 AI 做處理。
* AI 篩選計畫代碼：為 Message a Model 模式的 Google Gemini 節點，這裡的 Model 選擇 "**models/gemini-2.5-flash**"，Prompt 則直接貼上上個 Javascript 節點的輸出。此節點預期會輸出包含 **id** 和 **corresponding_project** 整合而成的 json 陣列。
* 提取AI回應並分割物件：Javascript 節點。這裡的 Javascript 會將前面 AI (Google Gemini) 的回應進行拆解，並將其分割為多個物件，以便後續處理。
* 轉為SQL物件：Javascript 節點。這裡的 Javascript 會整合前個節點輸出的資料並製作成可被 query 閱讀的物件，用以將資料傳回資料庫。
* 篩選計畫代碼和日期 & 輸入計畫名稱：為 Execute Query 模式的 Postgres 節點。此節點會執行以下的動作：
  * 確認合法日期：start_date 必須在 CURRENT_DATE (今天) 之前；end_date 必須在該月之內 (範例：11月 -> 11/1 ~ 11/30)。
  * 根據 AI 的回應，配合合法日期限制，將特定欄位資料 (由 AI 回傳的 **id** 決定) 嵌入計畫名稱，並將該欄位的 **send_email_flag 設為 true**，代表此欄位的對象會被寄送 Gmail。

到此，我們已探討完 1_Upload 工作流的運作方式。接著，我們來看看下一個工作流。
 
### 工作流2：寄送信件的具體架構

首先，將 "**2_Send**" json 檔導入新的工作流中，工作流應該長的像下圖這樣：

<img width="1401" height="989" alt="image" src="https://github.com/user-attachments/assets/8d9b4517-cd0c-4b60-90bd-134c4da627fd" />

這裡一樣要記得先把每個未選擇 Credential 的節點 (節點右下角有紅色警示符號的) 都重新設置對應的 Credential。

