-- ----------------------------------------------------------------------
-- 1. 基本設定與輔助函式 (僅用於確保完整性，如果已執行過則會跳過)
-- ----------------------------------------------------------------------

-- 基本：pgvector不用的話可不建
-- create extension if not exists vector;

-- ----------------------------------------------------------------------
-- 2. 主表：計畫代碼資訊表 (project_code_info)
-- ----------------------------------------------------------------------

-- 主表：project_code_info 儲存計畫主持人的資訊
create table if not exists project_code_info (
  corresponding_project   text,           -- 對應計畫
  code_filter_condition   text unique,    -- 計畫篩選條件
  created_at              timestamptz default now()
);
