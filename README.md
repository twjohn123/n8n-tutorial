n8n技術文章
============
**⚠️注意：本教學將在Windows 11系統上執行。**

摘要(Abstract)
------------
本文章以n8n自動化工作流平台來實踐「每月自動寄送信件」的系統，透過不同的條件篩選寄送信件的對象，動態設置每月的寄送時機，並且依照不同的對象和月份自動修改部分信件內容。

此系統將會使用到兩個n8n工作流：
1. 將資料傳進資料庫(PostgreSQL)中
2. 透過資料庫中的資料篩選對象並寄送信件

藉由此系統，可展示n8n對於校務的應用價值：
* 無需一封一封手動寄送信件
* 無需自行比對對象和篩選條件
* 高擴充性 (可自行增加對象和篩選條件)
* 高移植性 (可輕易打包整個工作流並部屬在其他電腦上)


目錄(Catalog)
-------------
### 1. [n8n的安裝和部署教學](#deployment)

* 本地Docker安裝
* 本地n8n安裝
* 本地PostgreSQL安裝
* n8n和PostgreSQL的連接教學

### 2. n8n的基本節點和工作流認識

* 各節點的介紹和操作實例
* Credential的介紹和設置
* 簡易工作流的介紹與示範

### 3. 資料庫的基本節構和功能

* PostgreSQL的節構介紹
* PostgreSQL的欄位和規則建立
* PostgreSQL的資料導入和刪除
* PostgreSQL的資料查詢

### 4. 系統的架構和設計

* 工作流1：資料傳進資料庫的具體架構
* 工作流2：篩選條件和寄送信件的具體架構

### 5. 校務自動化的應用實例

* 系統的執行結果
* 可行的系統擴充和延伸

### 6. 工作流的匯出與重新部屬

* 工作流的匯出
* 工作流的重新導入
* Credential的重新設置

### 7. 結語：n8n的校務價值和創新可能性

* 低程式碼和與AI結合的優勢
* 未來可行的應用場景

### 8. 附錄

* 工作流1：Upload.json
* 工作流2：Send.json


<h2 id="deployment">n8n的安裝和部署教學</h2>

### 本地Docker安裝

首先到[Docker官網][docker_url]，找到**Download Docker Desktop**，接著點擊**Download for Windows - AMD64**來下載Docker。

  [docker_url]: https://www.docker.com/
<img width="1465" height="924" alt="image" src="https://github.com/user-attachments/assets/b23d5106-27a5-42f1-ac4a-0298262ffe30" />

開啟下載好的安裝檔，接著按OK，之後便等待Docker安裝完成。

<img width="871" height="604" alt="image" src="https://github.com/user-attachments/assets/66e00797-984a-4682-bc77-580023868317" />

安裝完成後，開啟Docker Desktop，選擇**Accept**，接著選擇**Personal**，然後便登入或註冊帳號(也可以選擇Skip)，如此本地Docker便安裝完成了。

<img width="1571" height="887" alt="image" src="https://github.com/user-attachments/assets/c4be5b19-6dc6-4497-93f4-17303fd22651" />

### 本地n8n安裝

首先打開Windows的**命令提示字元**(可以在搜尋欄中輸入cmd來開啟)，
