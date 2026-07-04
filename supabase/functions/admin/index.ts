// Yoho 管理后台 Edge Function v3
// 密码+验证码登录，HMAC session token，所有 API 需验 token

const SUPABASE_URL = "https://uzrqvoftpyjjbbdsqngc.supabase.co";
const SERVICE_ROLE_KEY = Deno.env.get("ADMIN_SERVICE_ROLE_KEY") ?? "";
const ADMIN_PASSWORD = Deno.env.get("ADMIN_PASSWORD") ?? "yoho2024";
const ADMIN_CODE = Deno.env.get("ADMIN_VERIFY_CODE") ?? "886644";

// ---- HMAC 签名工具 ----
async function hmacSign(data: string, secret: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey("raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", key, encoder.encode(data));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}

async function createToken(): Promise<string> {
  const now = Date.now();
  const exp = now + 24 * 60 * 60 * 1000; // 24 小时
  const payload = `${now}.${exp}`;
  const sig = await hmacSign(payload, SERVICE_ROLE_KEY);
  return `${payload}.${sig}`;
}

async function verifyToken(token: string): Promise<boolean> {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return false;
    const now = Date.now();
    const ts = parseInt(parts[0]), exp = parseInt(parts[1]);
    if (isNaN(ts) || isNaN(exp) || now > exp) return false;
    const expectedSig = await hmacSign(`${parts[0]}.${parts[1]}`, SERVICE_ROLE_KEY);
    return parts[2] === expectedSig;
  } catch { return false; }
}

// ---- Supabase REST API ----
async function supabaseQuery(path: string) {
  const url = SUPABASE_URL + "/rest/v1/" + path;
  const res = await fetch(url, {
    headers: { apikey: SERVICE_ROLE_KEY, Authorization: "Bearer " + SERVICE_ROLE_KEY, Prefer: "count=exact" },
  });
  const total = res.headers.get("content-range")?.split("/")[1];
  const data = await res.json();
  return { data, total };
}

// ---- Auth Admin API ----
async function fetchAllAuthUsers(): Promise<{ id: string; email: string }[]> {
  const res = await fetch(SUPABASE_URL + "/auth/v1/admin/users", {
    headers: { apikey: SERVICE_ROLE_KEY, Authorization: "Bearer " + SERVICE_ROLE_KEY },
  });
  const json = await res.json();
  return (json.users || []).map((u: any) => ({ id: u.id, email: u.email || "" }));
}

async function buildEmailMap(userIds?: string[]): Promise<Record<string, string>> {
  const users = await fetchAllAuthUsers();
  const map: Record<string, string> = {};
  const idSet = userIds ? new Set(userIds) : null;
  for (const u of users) {
    if (!idSet || idSet.has(u.id)) map[u.id] = u.email || u.id;
  }
  return map;
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

// ---- CORS & 响应 ----
function corsHeaders(): Headers {
  const h = new Headers();
  h.set("Access-Control-Allow-Origin", "*");
  h.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
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

// ---- 鉴权（提取 token） ----
function extractToken(req: Request): string {
  const auth = req.headers.get("authorization") || "";
  if (auth.startsWith("Bearer ")) return auth.slice(7);
  return "";
}

// ---- 路由 ----
async function handleRequest(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const path = url.pathname;

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  // ---- /api/login（无需鉴权） ----
  if (path.endsWith("/api/login") && req.method === "POST") {
    try {
      const body = await req.json();
      const pw = body.password || "";
      const code = body.code || "";
      if (pw !== ADMIN_PASSWORD || code !== ADMIN_CODE) {
        return jsonErr("密码或验证码错误", 401);
      }
      const token = await createToken();
      return jsonOk({ token, expires_in: 86400 });
    } catch { return jsonErr("请求格式错误", 400); }
  }

  // ---- 其他所有 API 需鉴权 ----
  const token = extractToken(req);
  if (!token || !(await verifyToken(token))) {
    return jsonErr("未登录或会话已过期", 401);
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

      // 下载用户数：distinct user count (查询 download_events 或 users)
      let downloadUsers = 0;
      try {
        const { total: dl } = await supabaseQuery("download_events?select=user_id&limit=1");
        downloadUsers = Number(dl || 0);
      } catch { /* 表可能还不存在 */ }

      return jsonOk({
        total_users: Number(totalUsers || 0),
        today_dau: dau.length,
        paid_users: paidUsers.length,
        total_revenue: totalRevenue,
        download_users: downloadUsers,
      });
    } catch (e: any) { return jsonErr(e.message); }
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
    } catch (e: any) { return jsonErr(e.message); }
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
    } catch (e: any) { return jsonErr(e.message); }
  }

  // ---- /api/payments/search?q=xxx ----
  if (path.endsWith("/api/payments/search")) {
    try {
      const q = (url.searchParams.get("q") || "").trim().toLowerCase();
      if (!q) return jsonOk([]);
      const allUsers = await fetchAllAuthUsers();
      const matched = allUsers.filter(u => u.email.toLowerCase().includes(q));
      if (matched.length === 0) return jsonOk([]);
      const matchedIds = matched.map(u => `"${u.id}"`).join(",");
      const { data } = await supabaseQuery("subscriptions?select=amount,product,started_at,user_id&user_id=in.(" + matchedIds + ")&order=started_at.desc&limit=50");
      const emailMap: Record<string, string> = {};
      matched.forEach(u => { emailMap[u.id] = u.email || u.id; });
      return jsonOk(data.map((r: any) => ({ ...r, email: emailMap[r.user_id] || r.user_id })));
    } catch (e: any) { return jsonErr(e.message); }
  }

  // ---- /api/payments ----
  if (path.endsWith("/api/payments")) {
    try {
      const { data } = await supabaseQuery("subscriptions?select=amount,product,started_at,user_id&order=started_at.desc&limit=20");
      const userIds = [...new Set(data.map((r: any) => r.user_id))];
      const emailMap = await buildEmailMap(userIds);
      return jsonOk(data.map((r: any) => ({ ...r, email: emailMap[r.user_id] || r.user_id })));
    } catch (e: any) { return jsonErr(e.message); }
  }

  // ---- /api/users/search?q=xxx（按 username 或 email） ----
  if (path.endsWith("/api/users/search")) {
    try {
      const q = (url.searchParams.get("q") || "").trim().toLowerCase();
      if (!q) return jsonOk([]);
      /* 1) 从 public.users 按 username 搜索 */
      const encodedQ = encodeURIComponent("*" + q + "*");
      const { data: byUsername } = await supabaseQuery("users?select=id,username,pet_breed,created_at&username=ilike." + encodedQ + "&limit=20");
      const foundIds = new Set((byUsername || []).map((u: any) => u.id));
      /* 2) 从 auth.users 按 email 搜索 */
      const allAuth = await fetchAllAuthUsers();
      const byEmail = allAuth.filter(u => u.email.toLowerCase().includes(q) && !foundIds.has(u.id));
      /* 对纯邮箱匹配的用户，补查 public.users */
      let emailOnlyUsers: any[] = [];
      if (byEmail.length > 0) {
        const emailIds = byEmail.map(u => `"${u.id}"`).join(",");
        const { data: eu } = await supabaseQuery("users?select=id,username,pet_breed,created_at&id=in.(" + emailIds + ")");
        emailOnlyUsers = eu || [];
        for (const u of emailOnlyUsers) {
          const authU = byEmail.find(au => au.id === u.id);
          if (authU) u.email = authU.email;
        }
      }
      /* 合并 */
      const results = (byUsername || []).map((u: any) => ({ id: u.id, username: u.username, pet_breed: u.pet_breed || "", created_at: u.created_at, email: "" }));
      for (const u of emailOnlyUsers) {
        results.push({ id: u.id, username: u.username || "", pet_breed: u.pet_breed || "", created_at: u.created_at || "", email: u.email || "" });
      }
      /* 补全 email（对 username 匹配到的用户） */
      const authMap: Record<string, string> = {};
      allAuth.forEach(u => { authMap[u.id] = u.email; });
      results.forEach(r => { r.email = authMap[r.id] || r.email; });
      return jsonOk(results);
    } catch (e: any) { return jsonErr(e.message); }
  }

  // ---- /api/users/update（修改用户数据） ----
  if (path.endsWith("/api/users/update") && req.method === "POST") {
    try {
      const body = await req.json();
      const { id, username, pet_breed } = body;
      if (!id) return jsonErr("缺少用户 ID", 400);
      const patch: Record<string, string> = {};
      if (username !== undefined) patch.username = username;
      if (pet_breed !== undefined) patch.pet_breed = pet_breed;
      if (Object.keys(patch).length === 0) return jsonErr("没有需要修改的字段", 400);
      const res = await fetch(SUPABASE_URL + "/rest/v1/users?id=eq." + encodeURIComponent(id), {
        method: "PATCH",
        headers: { apikey: SERVICE_ROLE_KEY, Authorization: "Bearer " + SERVICE_ROLE_KEY, "Content-Type": "application/json", Prefer: "return=representation" },
        body: JSON.stringify(patch),
      });
      const updated = await res.json();
      return jsonOk({ success: true, user: updated[0] || null });
    } catch (e: any) { return jsonErr(e.message); }
  }

  return jsonErr("Not found", 404);
}

Deno.serve(handleRequest);
