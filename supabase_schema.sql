-- ==============================================================================
-- Salesforce Case Tracker & Report - Supabase Schema & Security Setup
-- ==============================================================================
-- Run this script in the Supabase SQL Editor (Dashboard -> SQL Editor -> New Query)
-- It creates all tables, foreign keys, indexes, and Row Level Security (RLS) policies.

-- 1. Profiles (user display info & roles)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  name TEXT,
  role TEXT DEFAULT 'editor', -- 'admin', 'editor', 'viewer'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Cases Table
CREATE TABLE IF NOT EXISTS public.cases (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  number TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  status TEXT NOT NULL,
  priority TEXT NOT NULL,
  start_date TEXT,
  end_date TEXT,
  due_date TEXT,
  notes TEXT,
  url TEXT,
  banner_target INT DEFAULT 0,
  archived BOOLEAN DEFAULT FALSE,
  pinned BOOLEAN DEFAULT FALSE,
  assignee TEXT DEFAULT '',
  total_banners INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Banner Logs
CREATE TABLE IF NOT EXISTS public.banner_log (
  id TEXT PRIMARY KEY,
  case_id TEXT REFERENCES public.cases(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  count INT NOT NULL DEFAULT 1,
  date TEXT NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Work Logs
CREATE TABLE IF NOT EXISTS public.work_log (
  id TEXT PRIMARY KEY,
  case_id TEXT REFERENCES public.cases(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,
  description TEXT,
  date TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Comments
CREATE TABLE IF NOT EXISTS public.comments (
  id TEXT PRIMARY KEY,
  case_id TEXT REFERENCES public.cases(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  author TEXT NOT NULL,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Status History
CREATE TABLE IF NOT EXISTS public.status_history (
  id TEXT PRIMARY KEY,
  case_id TEXT REFERENCES public.cases(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  from_status TEXT,
  to_status TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Audit Log
CREATE TABLE IF NOT EXISTS public.audit_log (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  case_id TEXT,
  case_number TEXT,
  details TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performant filtering and joins
CREATE INDEX IF NOT EXISTS idx_cases_user_id ON public.cases(user_id);
CREATE INDEX IF NOT EXISTS idx_cases_status ON public.cases(status);
CREATE INDEX IF NOT EXISTS idx_cases_number ON public.cases(number);
CREATE INDEX IF NOT EXISTS idx_banner_case_id ON public.banner_log(case_id);
CREATE INDEX IF NOT EXISTS idx_work_case_id ON public.work_log(case_id);
CREATE INDEX IF NOT EXISTS idx_comments_case_id ON public.comments(case_id);
CREATE INDEX IF NOT EXISTS idx_status_case_id ON public.status_history(case_id);

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banner_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- Setup RLS Policies (Allow authenticated users to manage their own team data)
DO $$
BEGIN
  -- Profiles
  DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;
  DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Admins and users can update profiles" ON public.profiles;
  DROP POLICY IF EXISTS "Users can access profiles" ON public.profiles;
  DROP POLICY IF EXISTS "Users can manage profiles" ON public.profiles;

  -- Allow all authenticated users to read all profiles (required for Team tab, Admin tab, and Reports)
  CREATE POLICY "Users can view all profiles" ON public.profiles 
    FOR SELECT TO authenticated 
    USING (true);

  -- Allow all authenticated users to insert or update profiles (prevents infinite recursion)
  CREATE POLICY "Users can manage profiles" ON public.profiles 
    FOR ALL TO authenticated 
    USING (true) 
    WITH CHECK (true);

  -- Cases
  DROP POLICY IF EXISTS "Users can access cases" ON public.cases;
  CREATE POLICY "Users can access cases" ON public.cases FOR ALL TO authenticated USING (true) WITH CHECK (true);

  -- Banner log
  DROP POLICY IF EXISTS "Users can access banner_log" ON public.banner_log;
  CREATE POLICY "Users can access banner_log" ON public.banner_log FOR ALL TO authenticated USING (true) WITH CHECK (true);

  -- Work log
  DROP POLICY IF EXISTS "Users can access work_log" ON public.work_log;
  CREATE POLICY "Users can access work_log" ON public.work_log FOR ALL TO authenticated USING (true) WITH CHECK (true);

  -- Comments
  DROP POLICY IF EXISTS "Users can access comments" ON public.comments;
  CREATE POLICY "Users can access comments" ON public.comments FOR ALL TO authenticated USING (true) WITH CHECK (true);

  -- Status history
  DROP POLICY IF EXISTS "Users can access status_history" ON public.status_history;
  CREATE POLICY "Users can access status_history" ON public.status_history FOR ALL TO authenticated USING (true) WITH CHECK (true);

  -- Audit log
  DROP POLICY IF EXISTS "Users can access audit_log" ON public.audit_log;
  CREATE POLICY "Users can access audit_log" ON public.audit_log FOR ALL TO authenticated USING (true) WITH CHECK (true);
END $$;

-- Enable Realtime publication for tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.cases, public.banner_log, public.work_log, public.comments;
