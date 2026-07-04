-- Yoho Storage 权限策略
-- 在 Supabase SQL Editor 中执行

-- 允许任何人读取 posters 里的文件（海报分享需要公开访问）
CREATE POLICY "Public read posters" ON storage.objects
  FOR SELECT USING (bucket_id = 'posters');

-- 允许已登录用户上传（用 Auth 注册过的就是已登录）
CREATE POLICY "Auth users upload" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'posters' AND auth.role() = 'authenticated');

-- 允许上传者删除自己的文件
CREATE POLICY "Owner delete" ON storage.objects
  FOR DELETE USING (bucket_id = 'posters' AND auth.uid() = owner);
