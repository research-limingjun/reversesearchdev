# Cron Job Token 消耗查询

## 查询方式

Hermes 在 state.db 中跟踪每个 session 的 token 使用量。

### 数据库路径
```
/Users/apple/.hermes/profiles/reversesearchdev/state.db
```

### 查询今日 Job 运行总消耗

```sql
-- 替换 job_id 和日期
SELECT 
  COUNT(*) as total_runs,
  SUM(input_tokens) as total_input_tokens,
  SUM(output_tokens) as total_output_tokens,
  SUM(cache_read_tokens) as total_cache_read_tokens,
  SUM(input_tokens + output_tokens) as total_tokens,
  SUM(message_count) as total_messages,
  SUM(tool_call_count) as total_tool_calls
FROM sessions 
WHERE id LIKE 'cron_a6538de319c0_20260603%';
```

### 查询大消耗运行详情

```sql
SELECT 
  id,
  datetime(started_at, 'unixepoch', '+8 hours') as start_time,
  datetime(ended_at, 'unixepoch', '+8 hours') as end_time,
  message_count, tool_call_count,
  input_tokens, output_tokens, cache_read_tokens,
  ROUND((input_tokens + output_tokens) / 1000.0, 1) as total_k_tokens
FROM sessions 
WHERE id LIKE 'cron_a6538de319c0_20260603%'
  AND (input_tokens + output_tokens) > 10000
ORDER BY input_tokens + output_tokens DESC;
```

### Session 表关键列

| 列名 | 说明 |
|------|------|
| id | 格式 `cron_{job_id}_{YYYYMMDD_HHMMSS}` |
| started_at / ended_at | Unix timestamp（UTC，+8小时为北京时间） |
| input_tokens | 输入 token 数 |
| output_tokens | 输出 token 数 |
| cache_read_tokens | 缓存命中 token（skill 内容等） |
| message_count | 消息总数 |
| tool_call_count | 工具调用总数 |
| estimated_cost_usd | 预估费用（部分 provider 为 0） |

### 注意事项

- mimo-v2.5-pro 的 estimated_cost 显示为 $0（小米 API 未接入计费）
- 缓存读取 token 通常很大（skill 内容每次注入），不代表实际 API 消耗
- 空轮询（无任务）通常只有 800-1600 input token
- 大消耗运行（代码审计+实现）可达 60K-114K input token
