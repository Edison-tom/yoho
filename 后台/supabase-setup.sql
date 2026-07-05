-- ============================================================
-- Yoho（呦吼）Supabase 一键部署脚本
-- 用法：Supabase Dashboard → SQL Editor → 粘贴全部 → Run
-- ============================================================

-- 1. 用户表
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    pet_breed TEXT DEFAULT '银渐层',           -- 银渐层/布偶/泰迪/金毛
    nickname TEXT DEFAULT '主人',            -- 用户昵称（单身时宠物称呼，情侣时伴侣看到）
    platform TEXT DEFAULT 'unknown',           -- macos-arm64 / macos-x64 / windows-x64
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. 情侣绑定
CREATE TABLE IF NOT EXISTS couples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a UUID REFERENCES users(id) NOT NULL,
    user_b UUID REFERENCES users(id),
    pair_code TEXT UNIQUE NOT NULL,           -- 6 位配对码
    shared_pet_breed TEXT DEFAULT '银渐层',    -- 共养宠物品种，双方共同选择
    nickname_a TEXT DEFAULT '主人',          -- user_a 的昵称
    nickname_b TEXT DEFAULT '主人',          -- user_b 的昵称
    callname_a TEXT DEFAULT '宝宝',          -- user_a 对 user_b 的称呼
    callname_b TEXT DEFAULT '宝宝',          -- user_b 对 user_a 的称呼
    tree_archived_reason TEXT,               -- NULL=正常 / started_relationship=因恋爱封存 / abandoned=主动放弃
    goal_confirmed_by UUID[] DEFAULT '{}',    -- 已确认共同目标的成员 ID
    goal_confirmed_at TIMESTAMPTZ,            -- 全体确认时间
    bound_at TIMESTAMPTZ DEFAULT now(),
    unbound_at TIMESTAMPTZ                   -- NULL = 未解绑
);

-- 2b. 配对码（建立恋爱关系过渡用）
CREATE TABLE IF NOT EXISTS pairing_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    code TEXT UNIQUE NOT NULL,                -- 6 位配对码
    status TEXT DEFAULT 'pending',            -- pending / accepted / expired
    expires_at TIMESTAMPTZ NOT NULL,          -- 24 小时有效期
    accepted_by UUID REFERENCES users(id),    -- 接受配对码的用户
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. 同步事件日志（离线优先队列）
CREATE TABLE IF NOT EXISTS sync_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_id UUID REFERENCES couples(id) NOT NULL,
    from_user UUID REFERENCES users(id) NOT NULL,
    event_type TEXT NOT NULL,                 -- cookie_earned / pet_fed / fertilizer_added / tree_stage_up / pet_visit
    payload JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. 用户树的数据（当前进度）
CREATE TABLE IF NOT EXISTS user_trees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    couple_id UUID REFERENCES couples(id),
    tree_name TEXT NOT NULL,                  -- 树名（如"北大上岸树"）
    goal_type TEXT,                           -- 考研/旅行/买车/健身/自定义
    target_date DATE NOT NULL,                -- 目标截止日期
    target_amount NUMERIC,                    -- 辅助计量：目标金额（可为 NULL）
    target_unit TEXT,                         -- 辅助单位：元/次/小时
    total_fertilizer_target INT NOT NULL,     -- 目标肥料总数（D × 4）
    current_fertilizer INT DEFAULT 0,         -- 当前肥料数
    stage TEXT DEFAULT '种子期',              -- 种子期/萌芽期/成长期/繁茂期/开花期/结果期
    completed_at TIMESTAMPTZ,                -- 达成时间（NULL = 未达成）
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. 记忆胶囊（封存）
CREATE TABLE IF NOT EXISTS memory_capsules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    couple_id UUID REFERENCES couples(id),
    encrypted_data TEXT NOT NULL,             -- AES-256 加密后的 JSON（客户端加密，服务端零知识）
    locked_at TIMESTAMPTZ DEFAULT now(),
    password_hint TEXT                        -- 密码提示问题
);

-- 6. 诊断上报
CREATE TABLE IF NOT EXISTS diagnostic_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    report_data JSONB NOT NULL,
    uploaded_at TIMESTAMPTZ DEFAULT now()
);

-- 6b. 组队（老铁/闺蜜模式，暂不开发）
CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT,                                -- 队伍名（可选）
    mode TEXT NOT NULL,                       -- buddy / sis
    creator_id UUID REFERENCES users(id) NOT NULL,
    invite_code TEXT UNIQUE NOT NULL,         -- 6 位组队码
    member_ids UUID[] NOT NULL DEFAULT '{}',  -- 成员 ID 数组（含 creator，客户端限制 ≤ 10）
    shared_tree_id UUID REFERENCES user_trees(id),
    shared_goal_name TEXT,                    -- 共同目标：树名
    shared_goal_type TEXT,                    -- 目标类型
    shared_goal_date DATE,                    -- 截止日期
    goal_confirmed_by UUID[] DEFAULT '{}',    -- 已确认成员 ID 数组
    goal_confirmed_at TIMESTAMPTZ,            -- 全体确认时间
    created_at TIMESTAMPTZ DEFAULT now(),
    disbanded_at TIMESTAMPTZ
);

-- 6c. 宠物串门记录（老铁/闺蜜模式）
CREATE TABLE IF NOT EXISTS pet_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES teams(id) NOT NULL,
    pet_owner UUID REFERENCES users(id) NOT NULL,   -- 宠物主人
    pet_breed TEXT NOT NULL,                         -- 宠物品种
    current_host UUID REFERENCES users(id) NOT NULL, -- 当前持有者
    status TEXT DEFAULT 'active',                    -- active / returned
    arrived_at TIMESTAMPTZ DEFAULT now(),
    returned_at TIMESTAMPTZ,                         -- 回家时间
    daily_count INT DEFAULT 1,                       -- 当天该宠物串门次数
    visit_date DATE DEFAULT CURRENT_DATE             -- 用于每日冷却计数
);

CREATE INDEX IF NOT EXISTS idx_visits_team ON pet_visits(team_id);
CREATE INDEX IF NOT EXISTS idx_visits_owner ON pet_visits(pet_owner, visit_date);

-- 7. 鼓励金句库
CREATE TABLE IF NOT EXISTS quote_library (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version TEXT NOT NULL,                    -- 金句版本号（用于更新）
    mode TEXT NOT NULL,                       -- personal / couple_solo / couple_together
    category TEXT,                            -- 坚持/独处/激励/治愈/共同奋斗/俏皮等
    content TEXT NOT NULL,
    active BOOLEAN DEFAULT true
);

-- ============================================================
-- 索引
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_couples_user_a ON couples(user_a);
CREATE INDEX IF NOT EXISTS idx_couples_user_b ON couples(user_b);
CREATE INDEX IF NOT EXISTS idx_sync_couple ON sync_events(couple_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trees_user ON user_trees(user_id);
CREATE INDEX IF NOT EXISTS idx_memory_user ON memory_capsules(user_id);
CREATE INDEX IF NOT EXISTS idx_pairing_code ON pairing_codes(code);
CREATE INDEX IF NOT EXISTS idx_pairing_user ON pairing_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_teams_mode ON teams(mode);
CREATE INDEX IF NOT EXISTS idx_teams_code ON teams(invite_code);

-- ============================================================
-- RLS 策略（行级安全）
-- ============================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE couples ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_trees ENABLE ROW LEVEL SECURITY;
ALTER TABLE memory_capsules ENABLE ROW LEVEL SECURITY;

-- 用户只能读写自己的数据
DROP POLICY IF EXISTS users_self ON users;
CREATE POLICY users_self ON users FOR ALL USING (auth.uid() = id);

-- 情侣双方可读彼此的绑定关系
DROP POLICY IF EXISTS couples_both ON couples;
CREATE POLICY couples_both ON couples FOR SELECT
    USING (auth.uid() = user_a OR auth.uid() = user_b);

-- 同步事件：同组情侣可读
DROP POLICY IF EXISTS sync_couple_only ON sync_events;
CREATE POLICY sync_couple_only ON sync_events FOR SELECT
    USING (couple_id IN (
        SELECT id FROM couples WHERE user_a = auth.uid() OR user_b = auth.uid()
    ));

DROP POLICY IF EXISTS sync_self_insert ON sync_events;
CREATE POLICY sync_self_insert ON sync_events FOR INSERT
    WITH CHECK (from_user = auth.uid());

-- 树数据：自己可读写，对方可读
DROP POLICY IF EXISTS trees_self ON user_trees;
CREATE POLICY trees_self ON user_trees FOR ALL USING (auth.uid() = user_id);
DROP POLICY IF EXISTS trees_partner_read ON user_trees;
CREATE POLICY trees_partner_read ON user_trees FOR SELECT
    USING (couple_id IN (
        SELECT id FROM couples WHERE user_a = auth.uid() OR user_b = auth.uid()
    ));

-- 记忆胶囊：只有本人可读写
DROP POLICY IF EXISTS memory_self ON memory_capsules;
CREATE POLICY memory_self ON memory_capsules FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- 插入默认金句（首批 20 句示例，可后续追加）
-- ============================================================
INSERT INTO quote_library (version, mode, category, content) VALUES
('v1', 'personal', '坚持', '每一步都算数。'),
('v1', 'personal', '坚持', '走得很慢，但从不后退。'),
('v1', 'personal', '独处', '一个人的时候，星星格外亮。'),
('v1', 'personal', '独处', '安静生长，不需要观众。'),
('v1', 'personal', '激励', '你比自己想象的更强大。'),
('v1', 'personal', '激励', '今天流的汗，是明天的花。'),
('v1', 'personal', '治愈', '累了就趴一会儿，树不会怪你。'),
('v1', 'personal', '治愈', '停下来看看窗外吧，那也是生活。'),
('v1', 'couple_solo', '独自奋斗', '你一个人在战斗，但有个人在心里为你加油。'),
('v1', 'couple_solo', '独自奋斗', 'Ta也在努力，你们在朝同一个方向走。'),
('v1', 'couple_solo', '隔空陪伴', '不在屏幕前，也在你这边。'),
('v1', 'couple_solo', '不打扰', 'Ta没有上线，但你们的树还在长。'),
('v1', 'couple_together', '共同奋斗', '两个人一起种，树长得更快。'),
('v1', 'couple_together', '共同奋斗', '你们在同一片土里扎根。'),
('v1', 'couple_together', '俏皮互动', '别摸鱼了，Ta已经比你多一块饼干了！'),
('v1', 'couple_together', '俏皮互动', 'Ta的树在嘲笑你的树长得慢——骗你的。'),
('v1', 'couple_together', '温暖陪伴', '两颗心一起跳，两棵树一起长。'),
('v1', 'couple_together', '温暖陪伴', '最好的约会，是一起种树。'),
('v1', 'group_buddy', '热血', '兄弟齐心，树都能种成森林。'),
('v1', 'group_buddy', '热血', '话不多，就是干。'),
('v1', 'group_sis', '温暖', '姐妹成队，树都加倍。'),
('v1', 'group_sis', '温暖', '一起变瘦，一起变富，一起种树。');

-- ============================================================
-- 版本元数据表（客户端自动更新用）
-- ============================================================
CREATE TABLE IF NOT EXISTS app_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version TEXT NOT NULL,                    -- 如 "1.2.0"
    platform TEXT NOT NULL,                   -- macos-x64 / macos-arm64 / windows-x64
    download_url TEXT NOT NULL,
    release_notes TEXT,
    released_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 备注：个人小目标（MiniGoal）为纯本地数据，不上传服务端。
-- 客户端使用 GRDB 本地存储，换设备需手动迁移。
-- ============================================================

-- ============================================================
-- 完成！
-- ============================================================
SELECT '✅ Yoho Supabase 部署完成！' AS status;

-- ============================================================
-- 管理后台相关表（2026-07-04 追加）
-- ============================================================
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    product TEXT NOT NULL,
    plan TEXT,
    amount NUMERIC NOT NULL,
    status TEXT DEFAULT 'active',
    started_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS daily_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    date DATE DEFAULT CURRENT_DATE,
    focus_minutes INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_subs_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subs_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_activity_date ON daily_activity(date);

-- 管理后台快捷视图
-- 管理后台快捷视图（模式从关系推导，支持多关系并行）
CREATE OR REPLACE VIEW admin_stats AS
WITH
active_couples_users AS (
    SELECT DISTINCT user_a AS user_id FROM couples WHERE unbound_at IS NULL
    UNION
    SELECT DISTINCT user_b FROM couples WHERE unbound_at IS NULL AND user_b IS NOT NULL
),
active_buddy_users AS (
    SELECT DISTINCT unnest(member_ids) AS user_id FROM teams WHERE mode = 'buddy' AND disbanded_at IS NULL
),
active_sis_users AS (
    SELECT DISTINCT unnest(member_ids) AS user_id FROM teams WHERE mode = 'sis' AND disbanded_at IS NULL
),
any_relationship_users AS (
    SELECT user_id FROM active_couples_users
    UNION SELECT user_id FROM active_buddy_users
    UNION SELECT user_id FROM active_sis_users
)
SELECT
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(DISTINCT user_id) FROM daily_activity WHERE date = CURRENT_DATE) AS today_dau,
    (SELECT COUNT(DISTINCT user_id) FROM subscriptions WHERE status = 'active') AS paid_users,
    (SELECT COALESCE(SUM(amount), 0) FROM subscriptions WHERE status != 'refunded') AS total_revenue,
    -- 纯单身（无任何关系）
    (SELECT COUNT(*) FROM users WHERE id NOT IN (SELECT user_id FROM any_relationship_users)) AS single_users,
    -- 各模式用户数（可重叠：同一用户可能同时在情侣和老铁中）
    (SELECT COUNT(*) FROM active_couples_users) AS couple_users,
    (SELECT COUNT(*) FROM active_buddy_users) AS buddy_users,
    (SELECT COUNT(*) FROM active_sis_users) AS sis_users,
    -- 活跃关系数
    (SELECT COUNT(*) FROM couples WHERE unbound_at IS NULL) AS active_couples,
    (SELECT COUNT(*) FROM teams WHERE mode = 'buddy' AND disbanded_at IS NULL) AS active_buddy_teams,
    (SELECT COUNT(*) FROM teams WHERE mode = 'sis' AND disbanded_at IS NULL) AS active_sis_teams,
    (SELECT COUNT(*) FROM users WHERE platform LIKE 'macos%') AS mac_users,
    (SELECT COUNT(*) FROM users WHERE platform = 'windows-x64') AS windows_users,
    (SELECT COUNT(*) FROM pairing_codes WHERE status = 'accepted') AS total_pairings;

-- RLS 策略
ALTER TABLE pairing_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_activity ENABLE ROW LEVEL SECURITY;

-- 配对码：本人可读写
DROP POLICY IF EXISTS pairing_self ON pairing_codes;
CREATE POLICY pairing_self ON pairing_codes FOR ALL USING (auth.uid() = user_id);

-- 组队：成员可读
DROP POLICY IF EXISTS teams_member ON teams;
CREATE POLICY teams_member ON teams FOR SELECT
    USING (auth.uid() = ANY(member_ids));

DROP POLICY IF EXISTS subs_self ON subscriptions;
CREATE POLICY subs_self ON subscriptions FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS activity_self ON daily_activity;
CREATE POLICY activity_self ON daily_activity FOR ALL USING (auth.uid() = user_id);
