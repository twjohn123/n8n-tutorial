-- ----------------------------------------------------------------------
-- 1. 基本設定與輔助函式 (僅用於確保完整性，如果已執行過則會跳過)
-- ----------------------------------------------------------------------

-- 基本：pgvector不用的話可不建
-- create extension if not exists vector;

-- ----------------------------------------------------------------------
-- 2. 主表：計畫主持人資訊表 (project_host_info)
-- ----------------------------------------------------------------------

-- 主表：project_host_info 儲存計畫主持人的資訊
create table if not exists project_host_info (
  id                  bigserial primary key,
  host_name           text unique,              -- 計畫主持人 (設定 unique 確保不重複)
  host_email          text,              -- 計畫主持人Email (設定 unique 確保不重複)
  created_at          timestamptz default now()
);

-- ----------------------------------------------------------------------
-- 3. 索引建立
-- ----------------------------------------------------------------------

-- 建立索引以加快查詢速度
create index if not exists idx_host_info_name on project_host_info(host_name);
create index if not exists idx_host_info_email on project_host_info(host_email);