ALTER TABLE users ADD COLUMN IF NOT EXISTS platform TEXT DEFAULT 'mac';

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
    (SELECT COUNT(*) FROM teams WHERE disbanded_at IS NULL) AS active_teams,
    (SELECT COUNT(*) FROM users WHERE platform = 'mac') AS mac_users,
    (SELECT COUNT(*) FROM users WHERE platform = 'windows') AS windows_users;
