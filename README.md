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

* 各節點的介紹和操作實例
* Credential 的介紹和設置
* 簡易工作流的介紹與示範

### 3. 資料庫的基本節構和功能

* PostgreSQL 的節構介紹
* PostgreSQL 的欄位和規則建立
* PostgreSQL 的資料導入和刪除
* PostgreSQL 的資料查詢

### 4. 系統的架構和設計

* 工作流1：資料傳進資料庫的具體架構
* 工作流2：篩選條件和寄送信件的具體架構

### 5. 校務自動化的應用實例

* 系統的執行結果
* 可行的系統擴充和延伸

### 6. 工作流的匯出與重新部屬

* 工作流的匯出
* 工作流的重新導入
* Credential 的重新設置

### 7. 結語：n8n 的校務價值和創新可能性

* 低程式碼和與AI結合的優勢
* 未來可行的應用場景

### 8. 附錄

* 工作流1：Upload.json
* 工作流2：Send.json


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

**⚠️以上指令變數在容器創建之後皆無法再次變更，請注意⚠️**

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

**⚠️以上指令變數在容器創建之後皆無法再次變更，請注意⚠️**

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

**⚠️注意：不可將變數設在 -d 之後，否則開啟容器時會出錯⚠️**

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

### 各節點的介紹和操作實例

n8n 有許多不同種類和功能的節點，我將從其中挑選幾個重要或常用的來進行介紹。

<img width="306" height="223" alt="image" src="https://github.com/user-attachments/assets/d69efc4c-d30f-41dc-af9c-53318be56eef" />
