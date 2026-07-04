# Yoho（呦吼）服务器信息

> 敏感凭据见项目根目录 `.env`，切勿提交到 Git。

## Supabase 项目

| 项目 | 值 |
|---|---|
| 项目名称 | Yoho |
| Project Ref | `uzrqvoftpyjjbbdsqngc` |
| Project URL | `https://uzrqvoftpyjjbbdsqngc.supabase.co` |
| Dashboard | https://supabase.com/dashboard/project/uzrqvoftpyjjbbdsqngc |

## 凭据（存储在 `.env`）

| Key | 用途 | 安全级别 |
|---|---|---|
| `VITE_SUPABASE_ANON_KEY` | 浏览器端 API 调用 | 公开（可暴露） |
| `SUPABASE_SERVICE_ROLE_KEY` | 服务端 API（绕过 RLS） | 机密（仅服务器） |
| `SUPABASE_ACCESS_TOKEN` | CLI 部署命令 | 机密（仅本地） |

## Edge Function：管理后台 API

- **函数名**：`admin`
- **部署命令**：
  ```bash
  cd /Volumes/file/Codex/Yoho
  SUPABASE_ACCESS_TOKEN=$SUPABASE_ACCESS_TOKEN npx supabase functions deploy admin
  ```
- **访问 URL**：
  ```
  https://uzrqvoftpyjjbbdsqngc.supabase.co/functions/v1/admin
  ```
- **鉴权方式**：URL 参数 `?apikey=<ANON_KEY>`
- **API 端点**：

| 端点 | 说明 |
|---|---|
| `/api/stats` | 统计数据（注册/日活/付费/收入） |
| `/api/dau-trend` | 30 天日活趋势 |
| `/api/revenue-trend` | 30 天付费趋势 |
| `/api/payments` | 最近 20 笔付费记录 |

## 管理后台访问

- **GitHub Pages**（推荐）：`https://edison-tom.github.io/yoho/`（需推送并启用 Pages）
- **本地**：浏览器打开 `docs/index.html`

## Supabase Storage Bucket

| Bucket | 权限 | 用途 |
|---|---|---|
| `posters` | Public | 海报、诊断报告、管理后台 HTML |

## 数据库表（supabase-setup.sql）

| 表 | 说明 |
|---|---|
| `users` | 用户表 |
| `daily_activity` | 每日活跃记录 |
| `subscriptions` | 付费订阅记录 |
