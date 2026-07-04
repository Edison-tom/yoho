// Supabase Edge Function: Yoho 管理后台
// 部署方式：Supabase Dashboard → Edge Functions → New Function → 粘贴此文件 → Deploy

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const HTML = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Yoho 管理后台</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"><\/script>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,"Microsoft YaHei",sans-serif;background:#f5f7fa;color:#1a1a2e}
.header{background:#1F4E79;color:#fff;padding:16px 24px;display:flex;justify-content:space-between;align-items:center}
.header h1{font-size:20px}
.header span{font-size:13px;opacity:.8}
.cards{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;padding:20px 24px}
.card{background:#fff;border-radius:10px;padding:20px;box-shadow:0 1px 4px rgba(0,0,0,.06)}
.card .label{font-size:13px;color:#888;margin-bottom:8px}
.card .value{font-size:28px;font-weight:700}
.charts{display:grid;grid-template-columns:1fr 1fr;gap:16px;padding:0 24px 20px}
.chart-box{background:#fff;border-radius:10px;padding:16px;box-shadow:0 1px 4px rgba(0,0,0,.06)}
.chart-box h3{font-size:15px;margin-bottom:12px;color:#1F4E79}
.table-box{margin:0 24px 24px;background:#fff;border-radius:10px;padding:16px;box-shadow:0 1px 4px rgba(0,0,0,.06)}
.table-box h3{font-size:15px;margin-bottom:12px;color:#1F4E79}
table{width:100%;border-collapse:collapse;font-size:13px}
th{text-align:left;padding:8px 12px;background:#EBF5FB;color:#1F4E79;font-weight:600}
td{padding:8px 12px;border-bottom:1px solid #f0f0f0}
tr:hover td{background:#fafbfc}
</style>
</head>
<body>
<div class="header"><h1>🌳 Yoho 管理后台</h1><span id="time"></span></div>
<div class="cards">
  <div class="card"><div class="label">注册用户</div><div class="value" id="totalUsers">-</div></div>
  <div class="card"><div class="label">今日日活</div><div class="value" id="todayDau">-</div></div>
  <div class="card"><div class="label">付费用户</div><div class="value" id="paidUsers">-</div></div>
  <div class="card"><div class="label">累计收入</div><div class="value" id="totalRevenue">-</div></div>
</div>
<div class="charts">
  <div class="chart-box"><h3>📈 30 天日活趋势</h3><canvas id="dauChart"></canvas></div>
  <div class="chart-box"><h3>💰 30 天付费趋势</h3><canvas id="revenueChart"></canvas></div>
</div>
<div class="table-box">
  <h3>💳 最近 20 笔付费</h3>
  <table><thead><tr><th>时间</th><th>用户</th><th>产品</th><th>金额</th></tr></thead><tbody id="paymentsBody"></tbody></table>
</div>
<script>
const URL = 'https://uzrqvoftpyjjbbdsqngc.supabase.co';
const KEY = '${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""}';

let dauChart, revenueChart;

setInterval(() => document.getElementById('time').textContent = new Date().toLocaleString('zh-CN'), 1000);

async function query(table, params = '') {
  const url = URL + '/rest/v1/' + table + params;
  const res = await fetch(url, { headers: { apikey: KEY, Authorization: 'Bearer ' + KEY } });
  return res.json();
}

async function loadAll() {
  try {
    // 统计卡片
    const [users, dau, subs] = await Promise.all([
      query('users', '?select=id&limit=0&head=1'),
      query('daily_activity', '?select=user_id&date=eq.' + new Date().toISOString().slice(0,10)),
      query('subscriptions', '?select=amount,status')
    ]);
    document.getElementById('todayDau').textContent = dau.length;

    // 通过 API 总量来估注册数，或直接查
    try {
      const r = await fetch(URL + '/rest/v1/users?select=id', { headers: { apikey: KEY, Authorization: 'Bearer ' + KEY, 'Prefer': 'count=exact' } });
      const cnt = r.headers.get('content-range')?.split('/')[1];
      document.getElementById('totalUsers').textContent = cnt || '?';
    } catch { document.getElementById('totalUsers').textContent = '?'; }

    const paid = subs.filter(s => s.status === 'active');
    document.getElementById('paidUsers').textContent = [...new Set(paid.map(s => s.user_id || ''))].filter(Boolean).length;
    document.getElementById('totalRevenue').textContent = '¥' + subs.filter(s => s.status !== 'refunded').reduce((s, r) => s + Number(r.amount||0), 0).toLocaleString();

    // 日活趋势
    const dates = []; for (let i = 29; i >= 0; i--) { const d = new Date(); d.setDate(d.getDate() - i); dates.push(d.toISOString().slice(0,10)); }
    const dauData = await Promise.all(dates.map(d => query('daily_activity', '?select=user_id&date=eq.' + d).then(r => r.length).catch(() => 0)));
    const ctx1 = document.getElementById('dauChart').getContext('2d');
    if (dauChart) dauChart.destroy();
    dauChart = new Chart(ctx1, { type: 'line', data: { labels: dates.map(d => d.slice(5)), datasets: [{ label: '日活', data: dauData, borderColor: '#1F4E79', backgroundColor: 'rgba(31,78,121,0.1)', fill: true, tension: 0.3 }] }, options: { responsive: true, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } } });

    // 付费趋势
    const revs = await query('subscriptions', '?select=amount,started_at&status=neq.refunded&order=started_at.asc');
    const map = {}; revs.forEach(r => { const d = (r.started_at||'').slice(0,10); if (d) map[d] = (map[d]||0) + Number(r.amount||0); });
    const values = dates.map(d => map[d] || 0);
    const ctx2 = document.getElementById('revenueChart').getContext('2d');
    if (revenueChart) revenueChart.destroy();
    revenueChart = new Chart(ctx2, { type: 'bar', data: { labels: dates.map(d => d.slice(5)), datasets: [{ label: '日收入 ¥', data: values, backgroundColor: '#1F4E79' }] }, options: { responsive: true, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } } });

    // 付费明细
    const pmts = await query('subscriptions', '?select=amount,product,started_at,user_id&order=started_at.desc&limit=20');
    document.getElementById('paymentsBody').innerHTML = pmts.map(r => '<tr><td>'+(r.started_at||'').slice(0,16).replace('T',' ')+'</td><td>'+(r.user_id||'').slice(0,12)+'...</td><td>'+r.product+'</td><td>¥'+Number(r.amount||0).toFixed(2)+'</td></tr>').join('');
  } catch(e) { console.error(e); }
}

loadAll();
setInterval(loadAll, 30000);
<\/script>
</body>
</html>`;

serve(async (req) => {
  return new Response(HTML, {
    headers: { "Content-Type": "text/html; charset=utf-8" },
  });
});
