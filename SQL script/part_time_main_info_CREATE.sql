-- ----------------------------------------------------------------------
-- 1. 基本設定與輔助函式
-- ----------------------------------------------------------------------

-- 基本：pgvector不用的話可不建
-- create extension if not exists vector;

-- 民國日期字串 → 西元 date（113.07.01 或 113/07.01）
-- 此函數用於處理Excel中可能出現的民國日期格式
create or replace function parse_roc_date(p text)
returns date language sql immutable as $$
  select case
    when p ~ '^\d{2,3}[./]\d{1,2}[./]\d{1,2}$'
      then make_date(1911 + split_part(p, '[./]', 1)::int,
                     split_part(regexp_replace(p,'.','/','g'), '/', 2)::int,
                     split_part(regexp_replace(p,'.','/','g'), '/', 3)::int)
    else null
  end
$$;

-- ----------------------------------------------------------------------
-- 2. 主表：兼任人員主要資訊表 (part_time_main_info)
-- ----------------------------------------------------------------------

-- 主表：part_time_main_info 儲存您提供的欄位資訊
create table if not exists part_time_main_info (
  id                  bigserial primary key,
  name                text,                     -- 姓名
  email               text,                     -- EMail
  grade				  text,						-- 級別
  work_type           text,						-- 類別職稱
  pay_type			  text,						-- 型態
  start_date          date,                     -- 聘期起始日
  end_date            date,                     -- 聘期結束日
  project_code        text,                     -- 本校計畫代碼
  project_name		  text,						-- 計畫名稱
  project_host        text,                     -- 計畫主持人
  created_at          timestamptz default now(),
  send_email_flag     boolean default false,

  unique (name, project_code)
);

-- ----------------------------------------------------------------------
-- 3. 索引建立
-- ----------------------------------------------------------------------

-- 建立索引以加快查詢速度
create index if not exists idx_pt_main_info_code on part_time_main_info(project_code);
create index if not exists idx_pt_main_info_email on part_time_main_info(email);
create index if not exists idx_pt_main_info_name on part_time_main_info(name);