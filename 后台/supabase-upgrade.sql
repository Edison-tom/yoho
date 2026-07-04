-- ============================================================
-- Yoho 增量升级脚本（对已有数据库追加新列，不丢数据）
-- 用法：Supabase SQL Editor → 粘贴全部 → Run
-- ============================================================

-- 1. users 表补列
ALTER TABLE users ADD COLUMN IF NOT EXISTS mode TEXT DEFAULT 'single';
ALTER TABLE users ADD COLUMN IF NOT EXISTS mode_changed_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS nickname TEXT DEFAULT '主人';

-- 2. couples 表补列
ALTER TABLE couples ADD COLUMN IF NOT EXISTS nickname_a TEXT DEFAULT '主人';
ALTER TABLE couples ADD COLUMN IF NOT EXISTS nickname_b TEXT DEFAULT '主人';
ALTER TABLE couples ADD COLUMN IF NOT EXISTS callname_a TEXT DEFAULT '宝宝';
ALTER TABLE couples ADD COLUMN IF NOT EXISTS callname_b TEXT DEFAULT '宝宝';
ALTER TABLE couples ADD COLUMN IF NOT EXISTS tree_archived_reason TEXT;
ALTER TABLE couples ADD COLUMN IF NOT EXISTS goal_confirmed_by UUID[] DEFAULT '{}';
ALTER TABLE couples ADD COLUMN IF NOT EXISTS goal_confirmed_at TIMESTAMPTZ;

-- 3. 新建表（用 IF NOT EXISTS 安全）
CREATE TABLE IF NOT EXISTS pairing_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    code TEXT UNIQUE NOT NULL,
    status TEXT DEFAULT 'pending',
    expires_at TIMESTAMPTZ NOT NULL,
    accepted_by UUID REFERENCES users(id),
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT,
    mode TEXT NOT NULL,
    creator_id UUID REFERENCES users(id) NOT NULL,
    invite_code TEXT UNIQUE NOT NULL,
    member_ids UUID[] NOT NULL DEFAULT '{}',
    shared_tree_id UUID REFERENCES user_trees(id),
    shared_goal_name TEXT,
    shared_goal_type TEXT,
    shared_goal_date DATE,
    goal_confirmed_by UUID[] DEFAULT '{}',
    goal_confirmed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    disbanded_at TIMESTAMPTZ
);

-- 4. 索引（IF NOT EXISTS 幂等）
CREATE INDEX IF NOT EXISTS idx_pairing_code ON pairing_codes(code);
CREATE INDEX IF NOT EXISTS idx_pairing_user ON pairing_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_teams_mode ON teams(mode);
CREATE INDEX IF NOT EXISTS idx_teams_code ON teams(invite_code);

-- 5. 金句补插（ON CONFLICT DO NOTHING 防重复）
INSERT INTO quote_library (version, mode, category, content) VALUES
('v1', 'group_buddy', '热血', '兄弟齐心，树都能种成森林。'),
('v1', 'group_buddy', '热血', '话不多，就是干。'),
('v1', 'group_sis', '温暖', '姐妹成队，树都加倍。'),
('v1', 'group_sis', '温暖', '一起变瘦，一起变富，一起种树。')
ON CONFLICT DO NOTHING;

-- 6. 刷新管理后台视图
DROP VIEW IF EXISTS admin_stats;
CREATE VIEW admin_stats AS
SELECT
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(DISTINCT user_id) FROM daily_activity WHERE date = CURRENT_DATE) AS today_dau,
    (SELECT COUNT(DISTINCT user_id) FROM subscriptions WHERE status = 'active') AS paid_users,
    (SELECT COALESCE(SUM(amount), 0) FROM subscriptions WHERE status != 'refunded') AS total_revenue,
    (SELECT COUNT(*) FROM users WHERE mode = 'single') AS single_users,
    (SELECT COUNT(*) FROM users WHERE mode = 'couple') AS couple_users,
    (SELECT COUNT(*) FROM couples WHERE unbound_at IS NULL) AS active_couples,
    (SELECT COUNT(*) FROM users WHERE mode = 'buddy') AS buddy_users,
    (SELECT COUNT(*) FROM users WHERE mode = 'sis') AS sis_users,
    (SELECT COUNT(*) FROM pairing_codes WHERE status = 'accepted') AS total_pairings,
    (SELECT COUNT(*) FROM teams WHERE disbanded_at IS NULL) AS active_teams;

-- 7. RLS（幂等：先删再建）
ALTER TABLE pairing_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pairing_self ON pairing_codes;
CREATE POLICY pairing_self ON pairing_codes FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS teams_member ON teams;
CREATE POLICY teams_member ON teams FOR SELECT USING (auth.uid() = ANY(member_ids));

SELECT '✅ Yoho 增量升级完成！' AS status;
