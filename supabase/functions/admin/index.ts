// Yoho 管理后台 Edge Function — 纯 API 模式
// HTML 由 Supabase Storage 托管，此函数仅处理 API 请求
// 不需要 JWT 验证（verify_jwt = false），手动检查 anon key

const SUPABASE_URL = "https://uzrqvoftpyjjbbdsqngc.supabase.co";
const ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6cnF2b2Z0cHlqamJiZHNxbmdjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMxNDA0MTAsImV4cCI6MjA5ODcxNjQxMH0.NJC6Z2yzcCmRQ5zxCLpPAUEXobrZDtUhnRePRj8CCJg";
const SERVICE_ROLE_KEY = Deno.env.get("ADMIN_SERVICE_ROLE_KEY") ?? "";

// ---- Supabase API（服务端，service_role key） ----
async function supabaseQuery(path: string) {
  const url = SUPABASE_URL + "/rest/v1/" + path;
  const res = await fetch(url, {
    headers: {
      apikey: SERVICE_ROLE_KEY,
      Authorization: "Bearer " + SERVICE_ROLE_KEY,
      Prefer: "count=exact",
    },
  });
  const total = res.headers.get("content-range")?.split("/")[1];
  const data = await res.json();
  return { data, total };
}

function todayStr() { return new Date().toISOString().slice(0, 10); }

function last30Dates(): string[] {
  const dates: string[] = [];
  for (let i = 29; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    dates.push(d.toISOString().slice(0, 10));
  }
  return dates;
}

// ---- CORS headers ----
function corsHeaders(): Headers {
  const h = new Headers();
  h.set("Access-Control-Allow-Origin", "*");
  h.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  h.set("Access-Control-Allow-Headers", "apikey, authorization, content-type");
  return h;
}

function jsonOk(data: unknown): Response {
  const h = corsHeaders();
  h.set("Content-Type", "application/json; charset=utf-8");
  return new Response(JSON.stringify(data), { status: 200, headers: h });
}

function jsonErr(msg: string, status = 500): Response {
  const h = corsHeaders();
  h.set("Content-Type", "application/json; charset=utf-8");
  return new Response(JSON.stringify({ error: msg }), { status, headers: h });
}

// ---- 手动鉴权 ----
function checkAuth(req: Request): boolean {
  const url = new URL(req.url);
  const apiKey = url.searchParams.get("apikey") ?? req.headers.get("apikey") ?? "";
  return apiKey === ANON_KEY;
}

// ---- 路由 ----
async function handleRequest(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const path = url.pathname;

  // OPTIONS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  // 鉴权
  if (!checkAuth(req)) {
    return jsonErr("Unauthorized. Append ?apikey=YOUR_ANON_KEY", 401);
  }

  // ---- /api/stats ----
  if (path.endsWith("/api/stats")) {
    try {
      const { data: users, total: totalUsers } = await supabaseQuery("users?select=id");
      const { data: dau } = await supabaseQuery("daily_activity?select=user_id&date=eq." + todayStr());
      const { data: subs } = await supabaseQuery("subscriptions?select=user_id,amount,status");
      const paidUsers = [...new Set(subs.filter((s: any) => s.status === "active").map((s: any) => s.user_id))];
      const totalRevenue = subs.filter((s: any) => s.status !== "refunded")
        .reduce((sum: number, s: any) => sum + Number(s.amount || 0), 0);
      return jsonOk({
        total_users: Number(totalUsers || 0),
        today_dau: dau.length,
        paid_users: paidUsers.length,
        total_revenue: totalRevenue,
      });
    } catch (e: any) {
      return jsonErr(e.message);
    }
  }

  // ---- /api/dau-trend ----
  if (path.endsWith("/api/dau-trend")) {
    try {
      const dates = last30Dates();
      const results: { date: string; count: number }[] = [];
      for (const date of dates) {
        const { data } = await supabaseQuery("daily_activity?select=user_id&date=eq." + date);
        results.push({ date: date.slice(5), count: data.length });
      }
      return jsonOk(results);
    } catch (e: any) {
      return jsonErr(e.message);
    }
  }

  // ---- /api/revenue-trend ----
  if (path.endsWith("/api/revenue-trend")) {
    try {
      const dates = last30Dates();
      const { data: revs } = await supabaseQuery("subscriptions?select=amount,started_at&status=neq.refunded");
      const map: Record<string, number> = {};
      revs.forEach((r: any) => {
        const d = (r.started_at || "").slice(0, 10);
        if (d) map[d] = (map[d] || 0) + Number(r.amount || 0);
      });
      return jsonOk(dates.map(d => ({ date: d.slice(5), amount: map[d] || 0 })));
    } catch (e: any) {
      return jsonErr(e.message);
    }
  }

  // ---- /api/payments ----
  if (path.endsWith("/api/payments")) {
    try {
      const { data } = await supabaseQuery("subscriptions?select=amount,product,started_at,user_id&order=started_at.desc&limit=20");
      const userIds = [...new Set(data.map((r: any) => r.user_id))];
      const emailMap: Record<string, string> = {};
      if (userIds.length > 0) {
        const ids = userIds.map((id: string) => `"${id}"`).join(",");
        const { data: users } = await supabaseQuery("users?select=id,email&id=in.(" + ids + ")");
        users.forEach((u: any) => { emailMap[u.id] = u.email || u.id; });
      }
      return jsonOk(data.map((r: any) => ({ ...r, email: emailMap[r.user_id] || r.user_id })));
    } catch (e: any) {
      return jsonErr(e.message);
    }
  }

  // 默认返回 404
  return jsonErr("Not found", 404);
}

Deno.serve(handleRequest);
