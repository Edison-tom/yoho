// Yoho 管理后台 Edge Function v4
// 基于完整数据库 schema：admin_stats 视图 + 用户管理 + 付费记录

const SUPABASE_URL = "https://uzrqvoftpyjjbbdsqngc.supabase.co";
const SERVICE_ROLE_KEY = Deno.env.get("ADMIN_SERVICE_ROLE_KEY") ?? "";
const ADMIN_PASSWORD = Deno.env.get("ADMIN_PASSWORD") ?? "yoho2024";
const ADMIN_CODE = Deno.env.get("ADMIN_VERIFY_CODE") ?? "886644";

// ---- HMAC token ----
async function hmacSign(data: string, secret: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey("raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", key, encoder.encode(data));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}
async function createToken(): Promise<string> {
  const now = Date.now(), exp = now + 86400000;
  const payload = `${now}.${exp}`;
  return `${payload}.${await hmacSign(payload, SERVICE_ROLE_KEY)}`;
}
async function verifyToken(t: string): Promise<boolean> {
  try {
    const p = t.split("."); if (p.length !== 3) return false;
    const now = Date.now(); if (now > parseInt(p[1])) return false;
    return p[2] === await hmacSign(`${p[0]}.${p[1]}`, SERVICE_ROLE_KEY);
  } catch { return false; }
}

// ---- Supabase helpers ----
async function supabaseQuery(path: string) {
  const res = await fetch(SUPABASE_URL + "/rest/v1/" + path, {
    headers: { apikey: SERVICE_ROLE_KEY, Authorization: "Bearer " + SERVICE_ROLE_KEY, Prefer: "count=exact" },
  });
  const total = res.headers.get("content-range")?.split("/")[1];
  return { data: await res.json(), total };
}
async function fetchAuthUsers(): Promise<{ id: string; email: string }[]> {
  const res = await fetch(SUPABASE_URL + "/auth/v1/admin/users", {
    headers: { apikey: SERVICE_ROLE_KEY, Authorization: "Bearer " + SERVICE_ROLE_KEY },
  });
  return ((await res.json()).users || []).map((u: any) => ({ id: u.id, email: u.email || "" }));
}

function todayStr() { return new Date().toISOString().slice(0, 10); }
function last30Dates(): string[] { return Array.from({ length: 30 }, (_, i) => { const d = new Date(); d.setDate(d.getDate() - 29 + i); return d.toISOString().slice(0, 10); }); }

// ---- CORS ----
function cors(): Headers {
  const h = new Headers();
  h.set("Access-Control-Allow-Origin", "*");
  h.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  h.set("Access-Control-Allow-Headers", "apikey, authorization, content-type");
  return h;
}
function ok(d: unknown) { return new Response(JSON.stringify(d), { status: 200, headers: Object.assign(cors(), { "Content-Type": "application/json; charset=utf-8" }) }); }
function err(m: string, s = 500) { return new Response(JSON.stringify({ error: m }), { status: s, headers: Object.assign(cors(), { "Content-Type": "application/json; charset=utf-8" }) }); }

function extractToken(req: Request): string {
  return (req.headers.get("authorization") || "").replace("Bearer ", "");
}

// ---- 路由 ----
async function handle(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const path = url.pathname;
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors() });

  // 登录（无需鉴权）
  if (path.endsWith("/api/login") && req.method === "POST") {
    try {
      const { password, code } = await req.json();
      if (password !== ADMIN_PASSWORD || code !== ADMIN_CODE) return err("密码或验证码错误", 401);
      return ok({ token: await createToken(), expires_in: 86400 });
    } catch { return err("请求格式错误", 400); }
  }

  // 鉴权
  const token = extractToken(req);
  if (!token || !(await verifyToken(token))) return err("未登录或会话已过期", 401);

  // ---- /api/stats（使用 admin_stats 视图） ----
  if (path.endsWith("/api/stats")) {
    try {
      const { data: stats } = await supabaseQuery("admin_stats?limit=1");
      const s = stats[0] || {};
      return ok({
        total_users: Number(s.total_users || 0),
        today_dau: Number(s.today_dau || 0),
        paid_users: Number(s.paid_users || 0),
        total_revenue: Number(s.total_revenue || 0),
        download_users: 0,
        // 模式分布
        single_users: Number(s.single_users || 0),
        couple_users: Number(s.couple_users || 0),
        buddy_users: Number(s.buddy_users || 0),
        sis_users: Number(s.sis_users || 0),
        active_couples: Number(s.active_couples || 0),
        active_teams: Number(s.active_teams || 0),
        total_pairings: Number(s.total_pairings || 0),
        mac_users: Number(s.mac_users || 0),
        windows_users: Number(s.windows_users || 0),
      });
    } catch (e: any) { return err(e.message); }
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
      return ok(results);
    } catch (e: any) { return err(e.message); }
  }

  // ---- /api/revenue-trend ----
  if (path.endsWith("/api/revenue-trend")) {
    try {
      const dates = last30Dates();
      const { data: revs } = await supabaseQuery("subscriptions?select=amount,started_at&status=neq.refunded");
      const map: Record<string, number> = {};
      revs.forEach((r: any) => { const d = (r.started_at || "").slice(0, 10); if (d) map[d] = (map[d] || 0) + Number(r.amount || 0); });
      return ok(dates.map(d => ({ date: d.slice(5), amount: map[d] || 0 })));
    } catch (e: any) { return err(e.message); }
  }

  // ---- /api/payments/search?q=xxx ----
  if (path.endsWith("/api/payments/search")) {
    try {
      const q = (url.searchParams.get("q") || "").trim().toLowerCase();
      if (!q) return ok([]);
      const allAuth = await fetchAuthUsers();
      const matched = allAuth.filter(u => u.email.toLowerCase().includes(q));
      if (matched.length === 0) return ok([]);
      const ids = matched.map(u => `"${u.id}"`).join(",");
      const { data } = await supabaseQuery("subscriptions?select=amount,product,started_at,user_id&user_id=in.(" + ids + ")&order=started_at.desc&limit=50");
      const em: Record<string, string> = {}; matched.forEach(u => { em[u.id] = u.email; });
      return ok(data.map((r: any) => ({ ...r, email: em[r.user_id] || r.user_id })));
    } catch (e: any) { return err(e.message); }
  }

  // ---- /api/payments ----
  if (path.endsWith("/api/payments")) {
    try {
      const { data } = await supabaseQuery("subscriptions?select=amount,product,started_at,user_id&order=started_at.desc&limit=20");
      const ids = [...new Set(data.map((r: any) => r.user_id))] as string[];
      const em: Record<string, string> = {};
      if (ids.length > 0) {
        const allAuth = await fetchAuthUsers();
        allAuth.forEach(u => { if (ids.includes(u.id)) em[u.id] = u.email; });
      }
      return ok(data.map((r: any) => ({ ...r, email: em[r.user_id] || r.user_id })));
    } catch (e: any) { return err(e.message); }
  }

  // ---- /api/users/search?q=xxx ----
  if (path.endsWith("/api/users/search")) {
    try {
      const q = (url.searchParams.get("q") || "").trim().toLowerCase();
      if (!q) return ok([]);
      const enc = encodeURIComponent("*" + q + "*");
      const { data: byUsername } = await supabaseQuery("users?select=id,username,pet_breed,mode,nickname,created_at&username=ilike." + enc + "&limit=20");
      const foundIds = new Set((byUsername || []).map((u: any) => u.id));
      const allAuth = await fetchAuthUsers();
      const byEmail = allAuth.filter(u => u.email.toLowerCase().includes(q) && !foundIds.has(u.id));
      let emailUsers: any[] = [];
      if (byEmail.length > 0) {
        const eids = byEmail.map(u => `"${u.id}"`).join(",");
        const { data: eu } = await supabaseQuery("users?select=id,username,pet_breed,mode,nickname,created_at&id=in.(" + eids + ")");
        emailUsers = eu || [];
        const authMap: Record<string, string> = {};
        allAuth.forEach(u => { authMap[u.id] = u.email; });
        emailUsers.forEach((u: any) => { u.email = authMap[u.id] || ""; });
      }
      const results = (byUsername || []).map((u: any) => ({ ...u, pet_breed: u.pet_breed || "", mode: u.mode || "single", nickname: u.nickname || "", email: "" }));
      const authMap: Record<string, string> = {};
      allAuth.forEach(u => { authMap[u.id] = u.email; });
      results.forEach(r => { r.email = authMap[r.id] || ""; });
      for (const u of emailUsers) {
        results.push({ id: u.id, username: u.username || "", pet_breed: u.pet_breed || "", mode: u.mode || "single", nickname: u.nickname || "", created_at: u.created_at || "", email: u.email || "" });
        foundIds.add(u.id);
      }
      return ok(results);
    } catch (e: any) { return err(e.message); }
  }

  // ---- /api/users/update ----
  if (path.endsWith("/api/users/update") && req.method === "POST") {
    try {
      const { id, username, pet_breed, mode, nickname } = await req.json();
      if (!id) return err("缺少用户 ID", 400);
      const patch: Record<string, string> = {};
      if (username !== undefined) patch.username = username;
      if (pet_breed !== undefined) patch.pet_breed = pet_breed;
      if (mode !== undefined) patch.mode = mode;
      if (nickname !== undefined) patch.nickname = nickname;
      if (Object.keys(patch).length === 0) return err("没有需要修改的字段", 400);
      const res = await fetch(SUPABASE_URL + "/rest/v1/users?id=eq." + encodeURIComponent(id), {
        method: "PATCH",
        headers: { apikey: SERVICE_ROLE_KEY, Authorization: "Bearer " + SERVICE_ROLE_KEY, "Content-Type": "application/json", Prefer: "return=representation" },
        body: JSON.stringify(patch),
      });
      return ok({ success: true, user: ((await res.json()) || [])[0] || null });
    } catch (e: any) { return err(e.message); }
  }


  return err("Not found", 404);
}

Deno.serve(handle);
