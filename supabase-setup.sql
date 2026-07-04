-- ============================================================
-- Yoho（呦吼）Supabase 一键部署脚本
-- 用法：Supabase Dashboard → SQL Editor → 粘贴全部 → Run
-- ============================================================

-- 1. 用户表
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    pet_breed TEXT DEFAULT '橘猫',           -- 橘猫/狸花/泰迪/金毛
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. 情侣绑定
CREATE TABLE IF NOT EXISTS couples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a UUID REFERENCES users(id) NOT NULL,
    user_b UUID REFERENCES users(id),
    pair_code TEXT UNIQUE NOT NULL,           -- 6 位配对码
    shared_pet_breed TEXT DEFAULT '橘猫',    -- 共养宠物品种，双方共同选择
    bound_at TIMESTAMPTZ DEFAULT now(),
    unbound_at TIMESTAMPTZ                   -- NULL = 未解绑
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
    user_id UUID REFERENCES users(id) UNIQUE NOT NULL,
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
('v1', 'couple_together', '温暖陪伴', '最好的约会，是一起种树。');

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
CREATE VIEW IF NOT EXISTS admin_stats AS
SELECT
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(DISTINCT user_id) FROM daily_activity WHERE date = CURRENT_DATE) AS today_dau,
    (SELECT COUNT(DISTINCT user_id) FROM subscriptions WHERE status = 'active') AS paid_users,
    (SELECT COALESCE(SUM(amount), 0) FROM subscriptions WHERE status != 'refunded') AS total_revenue;

-- RLS 策略
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_activity ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS subs_self ON subscriptions;
CREATE POLICY subs_self ON subscriptions FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS activity_self ON daily_activity;
CREATE POLICY activity_self ON daily_activity FOR ALL USING (auth.uid() = user_id);
