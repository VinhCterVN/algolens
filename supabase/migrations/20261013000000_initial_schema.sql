-- AlgoLens initial schema. Run once on a fresh Supabase project (Postgres 15+).
-- Supabase manages auth.users, passwords, sessions, and JWTs.
begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated, service_role;

create type public.app_role as enum ('learner', 'professor', 'admin');
create type public.content_status as enum ('draft', 'pending_review', 'published', 'rejected', 'archived');
create type public.catalog_kind as enum ('data_structure', 'algorithm');
create type public.difficulty_level as enum ('beginner', 'intermediate', 'advanced');
create type public.exercise_kind as enum ('multiple_choice', 'next_step', 'output', 'arrange', 'pseudocode');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Learner' check (length(btrim(display_name)) between 1 and 100),
  avatar_url text,
  bio text not null default '' check (length(bio) <= 2000),
  role public.app_role not null default 'learner',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  theme text not null default 'system' check (theme in ('light', 'dark', 'system')),
  locale text not null default 'en' check (locale in ('en', 'vi')),
  time_zone text not null default 'Asia/Ho_Chi_Minh',
  playback_speed numeric not null default 1 check (playback_speed in (0.5, 1, 2)),
  email_notifications boolean not null default true,
  in_app_notifications boolean not null default true,
  updated_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  kind public.catalog_kind not null,
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name text not null check (length(btrim(name)) between 1 and 100),
  description text not null default '',
  sort_order integer not null default 0
);

create table public.topics (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories(id) on delete restrict,
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  title text not null check (length(btrim(title)) between 1 and 150),
  description text not null default '',
  difficulty public.difficulty_level not null default 'beginner',
  estimated_minutes integer not null default 10 check (estimated_minutes > 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
create index topics_category_idx on public.topics(category_id, sort_order);

create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.topics(id) on delete restrict,
  author_id uuid not null references public.profiles(id) on delete restrict,
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  title text not null check (length(btrim(title)) between 1 and 200),
  summary text not null default '',
  objectives text[] not null default '{}',
  body_markdown text not null default '',
  pseudocode text not null default '',
  code_language text not null default 'pseudocode',
  time_complexity text,
  space_complexity text,
  difficulty public.difficulty_level not null default 'beginner',
  estimated_minutes integer not null default 10 check (estimated_minutes > 0),
  sort_order integer not null default 0,
  status public.content_status not null default 'draft',
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index lessons_topic_idx on public.lessons(topic_id, sort_order);
create index lessons_author_idx on public.lessons(author_id, status);
create index lessons_published_idx on public.lessons(published_at desc) where status = 'published';
create index lessons_search_idx on public.lessons using gin (
  to_tsvector('english', title || ' ' || summary || ' ' || body_markdown)
);

create table public.visualization_presets (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  title text not null,
  engine_key text not null check (length(btrim(engine_key)) between 1 and 100),
  input_data jsonb not null default '{}' check (jsonb_typeof(input_data) = 'object'),
  canvas_state jsonb not null default '{}' check (jsonb_typeof(canvas_state) = 'object'),
  explanation text not null default '',
  schema_version integer not null default 1 check (schema_version > 0),
  sort_order integer not null default 0
);
create index visualization_presets_lesson_idx on public.visualization_presets(lesson_id, sort_order);

create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  position smallint not null check (position in (1, 2)),
  kind public.exercise_kind not null,
  prompt text not null check (length(btrim(prompt)) > 0),
  question_config jsonb not null default '{}' check (jsonb_typeof(question_config) = 'object'),
  hints text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (lesson_id, position)
);
-- Answers are deliberately outside the exposed API schema.
create table private.exercise_solutions (
  exercise_id uuid primary key references public.exercises(id) on delete cascade,
  correct_answer jsonb not null check (correct_answer <> 'null'::jsonb),
  explanation text not null default ''
);

create table public.lesson_reviews (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  reviewer_id uuid references public.profiles(id) on delete set null,
  decision public.content_status not null check (decision in ('published', 'rejected', 'archived')),
  note text not null default '',
  created_at timestamptz not null default now()
);
create index lesson_reviews_lesson_idx on public.lesson_reviews(lesson_id, created_at desc);
create index lesson_reviews_reviewer_idx on public.lesson_reviews(reviewer_id);

create table public.lesson_progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  progress_percent smallint not null default 0 check (progress_percent between 0 and 100),
  last_section text,
  last_accessed_at timestamptz not null default now(),
  completed_at timestamptz,
  primary key (user_id, lesson_id),
  check ((progress_percent = 100) = (completed_at is not null))
);
create index lesson_progress_lesson_idx on public.lesson_progress(lesson_id);
create index lesson_progress_recent_idx on public.lesson_progress(user_id, last_accessed_at desc);

create table public.exercise_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete cascade,
  answer jsonb not null,
  is_correct boolean not null,
  explanation text not null,
  question_snapshot jsonb not null,
  hints_used integer not null default 0 check (hints_used >= 0),
  submitted_at timestamptz not null default now()
);
create index exercise_attempts_user_idx on public.exercise_attempts(user_id, submitted_at desc);
create index exercise_attempts_exercise_idx on public.exercise_attempts(exercise_id);

create table public.learning_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete set null,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  active_seconds integer not null check (active_seconds between 0 and 86400),
  check (ended_at >= started_at),
  check (active_seconds <= extract(epoch from (ended_at - started_at)))
);
create index learning_sessions_user_idx on public.learning_sessions(user_id, started_at desc);
create index learning_sessions_lesson_idx on public.learning_sessions(lesson_id);

create table public.saved_workspaces (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete set null,
  title text not null default 'Untitled workspace' check (length(btrim(title)) between 1 and 200),
  mode text not null default 'playground' check (mode in ('learning', 'playground')),
  engine_key text not null,
  input_data jsonb not null default '{}' check (jsonb_typeof(input_data) = 'object'),
  canvas_state jsonb not null default '{}' check (jsonb_typeof(canvas_state) = 'object'),
  viewport jsonb not null default '{}' check (jsonb_typeof(viewport) = 'object'),
  current_step integer not null default 0 check (current_step >= 0),
  playback_speed numeric not null default 1 check (playback_speed in (0.5, 1, 2)),
  schema_version integer not null default 1 check (schema_version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index saved_workspaces_user_idx on public.saved_workspaces(user_id, updated_at desc);
create index saved_workspaces_lesson_idx on public.saved_workspaces(lesson_id);

create table public.lesson_bookmarks (
  user_id uuid not null references public.profiles(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, lesson_id)
);
create index lesson_bookmarks_lesson_idx on public.lesson_bookmarks(lesson_id);

create table public.lesson_ratings (
  user_id uuid not null references public.profiles(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  is_hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, lesson_id)
);
create index lesson_ratings_lesson_idx on public.lesson_ratings(lesson_id);

create table public.lesson_comments (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  parent_id uuid,
  body text not null check (length(btrim(body)) between 1 and 5000),
  is_hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, lesson_id),
  foreign key (parent_id, lesson_id) references public.lesson_comments(id, lesson_id) on delete set null (parent_id),
  check (parent_id is distinct from id)
);
create index lesson_comments_lesson_idx on public.lesson_comments(lesson_id, created_at desc);
create index lesson_comments_user_idx on public.lesson_comments(user_id);
create index lesson_comments_parent_idx on public.lesson_comments(parent_id, lesson_id);

create table public.comment_helpful_votes (
  comment_id uuid not null references public.lesson_comments(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);
create index comment_helpful_votes_user_idx on public.comment_helpful_votes(user_id);

create table public.comment_reports (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references public.lesson_comments(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (length(btrim(reason)) between 1 and 2000),
  status text not null default 'open' check (status in ('open', 'resolved', 'dismissed')),
  resolution_note text,
  resolved_by uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  unique (comment_id, reporter_id),
  check ((status = 'open') = (resolved_at is null))
);
create index comment_reports_reporter_idx on public.comment_reports(reporter_id);
create index comment_reports_resolver_idx on public.comment_reports(resolved_by);
create index comment_reports_open_idx on public.comment_reports(created_at) where status = 'open';

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null,
  title text not null,
  body text not null default '',
  data jsonb not null default '{}' check (jsonb_typeof(data) = 'object'),
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications(user_id, created_at desc);

-- Definer helpers bypass profile RLS to avoid recursive policies. No dynamic SQL.
create function private.current_role() returns public.app_role
language sql stable security definer set search_path = '' as $$
  select role from public.profiles where id = (select auth.uid()) and is_active;
$$;
create function private.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce(private.current_role() = 'admin', false);
$$;
create function private.manages_lesson(target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.is_admin() or exists (
    select 1 from public.lessons where id = target and author_id = (select auth.uid())
      and private.current_role() = 'professor'
  );
$$;
create function private.can_read_lesson(target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.current_role() is not null and exists (
    select 1 from public.lessons where id = target
      and (status = 'published' or private.manages_lesson(target))
  );
$$;
create function private.can_edit_lesson(target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.manages_lesson(target) and exists (
    select 1 from public.lessons where id = target and status in ('draft', 'rejected')
  );
$$;
create function private.can_read_comment(target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.lesson_comments c where c.id = target
    and private.can_read_lesson(c.lesson_id)
    and (not c.is_hidden or c.user_id = (select auth.uid()) or private.manages_lesson(c.lesson_id)));
$$;

create function private.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at := now(); return new; end;
$$;
do $$
declare table_name text;
begin
  foreach table_name in array array['profiles', 'user_settings', 'lessons', 'exercises',
    'saved_workspaces', 'lesson_ratings', 'lesson_comments'] loop
    execute format('create trigger touch_updated_at before update on public.%I for each row execute function private.touch_updated_at()', table_name);
  end loop;
end;
$$;

create function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  -- Never trust signup metadata to set a privileged role.
  insert into public.profiles(id, display_name)
  values (new.id, coalesce(nullif(left(btrim(new.raw_user_meta_data ->> 'display_name'), 100), ''), 'Learner'));
  insert into public.user_settings(user_id) values (new.id);
  return new;
end;
$$;
create trigger on_algolens_user_created after insert on auth.users
for each row execute function private.handle_new_user();
insert into public.profiles(id) select id from auth.users on conflict do nothing;
insert into public.user_settings(user_id) select id from public.profiles on conflict do nothing;

-- Access and privileges: no anonymous access; catalog requires an active login.
do $$
declare table_name text;
begin
  foreach table_name in array array['profiles', 'user_settings', 'categories', 'topics', 'lessons',
    'visualization_presets', 'exercises', 'lesson_reviews', 'lesson_progress', 'exercise_attempts',
    'learning_sessions', 'saved_workspaces', 'lesson_bookmarks', 'lesson_ratings', 'lesson_comments',
    'comment_helpful_votes', 'comment_reports', 'notifications'] loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('revoke all on public.%I from public, anon, authenticated', table_name);
    execute format('grant select on public.%I to authenticated', table_name);
    execute format('grant all on public.%I to service_role', table_name);
  end loop;
end;
$$;
alter table private.exercise_solutions enable row level security;
revoke all on private.exercise_solutions from public, anon, authenticated;
grant all on private.exercise_solutions to service_role;

create policy profiles_read on public.profiles for select to authenticated
using (id = (select auth.uid()) or private.current_role() is not null);
create policy profiles_update on public.profiles for update to authenticated
using (id = (select auth.uid()) and private.current_role() is not null)
with check (id = (select auth.uid()) and private.current_role() is not null);
grant update(display_name, avatar_url, bio) on public.profiles to authenticated;

create policy settings_own on public.user_settings for all to authenticated
using (user_id = (select auth.uid()) and private.current_role() is not null)
with check (user_id = (select auth.uid()) and private.current_role() is not null);
grant update(theme, locale, time_zone, playback_speed, email_notifications, in_app_notifications)
on public.user_settings to authenticated;

create policy categories_read on public.categories for select to authenticated using (private.current_role() is not null);
create policy categories_admin on public.categories for all to authenticated using (private.is_admin()) with check (private.is_admin());
create policy topics_read on public.topics for select to authenticated using (private.current_role() is not null);
create policy topics_admin on public.topics for all to authenticated using (private.is_admin()) with check (private.is_admin());
grant insert, update, delete on public.categories, public.topics to authenticated;

create policy lessons_read on public.lessons for select to authenticated using (private.can_read_lesson(id));
create policy lessons_insert on public.lessons for insert to authenticated
with check (author_id = (select auth.uid()) and private.current_role() in ('professor', 'admin') and status = 'draft');
create policy lessons_update on public.lessons for update to authenticated
using (private.can_edit_lesson(id)) with check (private.can_edit_lesson(id));
create policy lessons_delete on public.lessons for delete to authenticated
using (private.can_edit_lesson(id) or private.is_admin());
grant insert(id, topic_id, author_id, slug, title, summary, objectives, body_markdown,
  pseudocode, code_language, time_complexity, space_complexity, difficulty, estimated_minutes, sort_order)
on public.lessons to authenticated;
grant update(topic_id, slug, title, summary, objectives, body_markdown, pseudocode,
  code_language, time_complexity, space_complexity, difficulty, estimated_minutes, sort_order)
on public.lessons to authenticated;
grant delete on public.lessons to authenticated;

do $$
declare table_name text;
begin
  foreach table_name in array array['exercises', 'visualization_presets'] loop
    execute format('create policy content_read on public.%I for select to authenticated using (private.can_read_lesson(lesson_id))', table_name);
    execute format('create policy content_write on public.%I for all to authenticated using (private.can_edit_lesson(lesson_id)) with check (private.can_edit_lesson(lesson_id))', table_name);
    execute format('grant insert, update, delete on public.%I to authenticated', table_name);
  end loop;
end;
$$;

create policy reviews_read on public.lesson_reviews for select to authenticated using (private.manages_lesson(lesson_id));
create policy attempts_read on public.exercise_attempts for select to authenticated
using (private.current_role() is not null and (user_id = (select auth.uid()) or private.is_admin()
  or exists (select 1 from public.exercises e where e.id = exercise_id and private.manages_lesson(e.lesson_id))));
-- Attempts have no client INSERT/UPDATE/DELETE grants: only the grading RPC writes them.

do $$
declare table_name text;
begin
  foreach table_name in array array['lesson_progress', 'learning_sessions'] loop
    execute format('create policy learning_read on public.%I for select to authenticated using (private.current_role() is not null and (user_id = (select auth.uid()) or private.manages_lesson(lesson_id)))', table_name);
    execute format('create policy learning_insert on public.%I for insert to authenticated with check (private.current_role() is not null and user_id = (select auth.uid()) and (lesson_id is null or private.can_read_lesson(lesson_id)))', table_name);
    execute format('grant insert on public.%I to authenticated', table_name);
  end loop;
end;
$$;
create policy progress_update on public.lesson_progress for update to authenticated
using (user_id = (select auth.uid()) and private.current_role() is not null)
with check (user_id = (select auth.uid()) and private.can_read_lesson(lesson_id));
grant update(progress_percent, last_section, last_accessed_at, completed_at) on public.lesson_progress to authenticated;

do $$
declare table_name text;
begin
  foreach table_name in array array['saved_workspaces', 'lesson_bookmarks'] loop
    execute format('create policy personal_read on public.%I for select to authenticated using (user_id = (select auth.uid()) and private.current_role() is not null)', table_name);
    execute format('create policy personal_insert on public.%I for insert to authenticated with check (user_id = (select auth.uid()) and private.current_role() is not null and (lesson_id is null or private.can_read_lesson(lesson_id)))', table_name);
    execute format('create policy personal_delete on public.%I for delete to authenticated using (user_id = (select auth.uid()) and private.current_role() is not null)', table_name);
    execute format('grant insert, delete on public.%I to authenticated', table_name);
  end loop;
end;
$$;
create policy workspace_update on public.saved_workspaces for update to authenticated
using (user_id = (select auth.uid()) and private.current_role() is not null)
with check (user_id = (select auth.uid()) and (lesson_id is null or private.can_read_lesson(lesson_id)));
grant update(title, lesson_id, mode, engine_key, input_data, canvas_state, viewport,
  current_step, playback_speed, schema_version) on public.saved_workspaces to authenticated;

create policy ratings_read on public.lesson_ratings for select to authenticated
using (private.can_read_lesson(lesson_id) and (not is_hidden or user_id = (select auth.uid()) or private.manages_lesson(lesson_id)));
create policy ratings_insert on public.lesson_ratings for insert to authenticated
with check (user_id = (select auth.uid()) and private.can_read_lesson(lesson_id) and not is_hidden);
create policy ratings_update on public.lesson_ratings for update to authenticated
using (user_id = (select auth.uid()) and private.can_read_lesson(lesson_id))
with check (user_id = (select auth.uid()) and private.can_read_lesson(lesson_id));
create policy ratings_delete on public.lesson_ratings for delete to authenticated
using (user_id = (select auth.uid()) and private.current_role() is not null);
grant insert(user_id, lesson_id, rating), update(rating), delete on public.lesson_ratings to authenticated;

create policy comments_read on public.lesson_comments for select to authenticated using (private.can_read_comment(id));
create policy comments_insert on public.lesson_comments for insert to authenticated
with check (user_id = (select auth.uid()) and private.can_read_lesson(lesson_id) and not is_hidden
  and (parent_id is null or private.can_read_comment(parent_id)));
create policy comments_update on public.lesson_comments for update to authenticated
using (user_id = (select auth.uid()) and private.can_read_lesson(lesson_id))
with check (user_id = (select auth.uid()) and private.can_read_lesson(lesson_id));
create policy comments_delete on public.lesson_comments for delete to authenticated
using (user_id = (select auth.uid()) and private.current_role() is not null);
grant insert(id, lesson_id, user_id, parent_id, body), update(body), delete on public.lesson_comments to authenticated;

create policy votes_read on public.comment_helpful_votes for select to authenticated using (private.can_read_comment(comment_id));
create policy votes_insert on public.comment_helpful_votes for insert to authenticated
with check (user_id = (select auth.uid()) and private.can_read_comment(comment_id));
create policy votes_delete on public.comment_helpful_votes for delete to authenticated
using (user_id = (select auth.uid()) and private.current_role() is not null);
grant insert, delete on public.comment_helpful_votes to authenticated;

create policy reports_read on public.comment_reports for select to authenticated
using (private.current_role() is not null and (reporter_id = (select auth.uid()) or exists (
  select 1 from public.lesson_comments c where c.id = comment_id and private.manages_lesson(c.lesson_id))));
create policy reports_insert on public.comment_reports for insert to authenticated
with check (reporter_id = (select auth.uid()) and private.can_read_comment(comment_id) and status = 'open');
grant insert(id, comment_id, reporter_id, reason) on public.comment_reports to authenticated;

create policy notifications_own on public.notifications for select to authenticated
using (user_id = (select auth.uid()) and private.current_role() is not null);
create policy notifications_update on public.notifications for update to authenticated
using (user_id = (select auth.uid()) and private.current_role() is not null)
with check (user_id = (select auth.uid()) and private.current_role() is not null);
grant update(read_at) on public.notifications to authenticated;

-- Protected workflow RPCs. Lock the lesson to serialize publication and edits.
create function public.set_exercise_solution(target_exercise uuid, expected_answer jsonb, feedback text)
returns void language plpgsql security definer set search_path = '' as $$
declare target_lesson uuid;
begin
  select lesson_id into target_lesson from public.exercises where id = target_exercise;
  perform 1 from public.lessons where id = target_lesson for update;
  if not private.can_edit_lesson(target_lesson) then raise exception 'Not permitted' using errcode = '42501'; end if;
  insert into private.exercise_solutions(exercise_id, correct_answer, explanation)
  values (target_exercise, expected_answer, coalesce(feedback, ''))
  on conflict (exercise_id) do update set correct_answer = excluded.correct_answer, explanation = excluded.explanation;
end;
$$;
create function public.get_exercise_solution(target_exercise uuid)
returns table(correct_answer jsonb, explanation text)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.exercises where id = target_exercise and private.manages_lesson(lesson_id))
    then raise exception 'Not permitted' using errcode = '42501'; end if;
  return query select s.correct_answer, s.explanation from private.exercise_solutions s where s.exercise_id = target_exercise;
end;
$$;

create function private.validate_lesson(target uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if (select count(*) from public.exercises where lesson_id = target) not between 1 and 2 then
    raise exception 'A submitted lesson must contain 1 or 2 exercises';
  end if;
  if exists (select 1 from public.exercises e left join private.exercise_solutions s on s.exercise_id = e.id
    where e.lesson_id = target and s.exercise_id is null) then raise exception 'Each exercise needs an answer and explanation'; end if;
end;
$$;

create function public.submit_lesson(target_lesson uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform 1 from public.lessons where id = target_lesson for update;
  if not private.can_edit_lesson(target_lesson) then raise exception 'Not permitted' using errcode = '42501'; end if;
  perform private.validate_lesson(target_lesson);
  update public.lessons set status = 'pending_review' where id = target_lesson;
end;
$$;
create function public.return_lesson_to_draft(target_lesson uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform 1 from public.lessons where id = target_lesson for update;
  if not private.manages_lesson(target_lesson) then raise exception 'Not permitted' using errcode = '42501'; end if;
  update public.lessons set status = 'draft' where id = target_lesson;
end;
$$;
create function public.review_lesson(target_lesson uuid, decision public.content_status, review_note text default '')
returns void language plpgsql security definer set search_path = '' as $$
declare previous public.content_status;
begin
  if not private.is_admin() then raise exception 'Admin required' using errcode = '42501'; end if;
  select status into previous from public.lessons where id = target_lesson for update;
  if previous is null then raise exception 'Lesson not found'; end if;
  if decision in ('published', 'rejected') and previous <> 'pending_review' then raise exception 'Lesson must be pending review'; end if;
  if decision is null or decision not in ('published', 'rejected', 'archived') then raise exception 'Invalid decision'; end if;
  if decision = 'published' then perform private.validate_lesson(target_lesson); end if;
  update public.lessons set status = decision,
    published_at = case when decision = 'published' then now() else published_at end where id = target_lesson;
  insert into public.lesson_reviews(lesson_id, reviewer_id, decision, note)
  values (target_lesson, auth.uid(), decision, coalesce(review_note, ''));
end;
$$;

-- Serialize child edits with the same parent lock used by publishing.
create function private.guard_lesson_content() returns trigger
language plpgsql security definer set search_path = '' as $$
declare target uuid;
begin
  target := case when tg_op = 'DELETE' then old.lesson_id else new.lesson_id end;
  if tg_op = 'UPDATE' and old.lesson_id is distinct from new.lesson_id then
    raise exception 'Moving content between lessons is not supported';
  end if;
  perform 1 from public.lessons where id = target for update;
  if exists (select 1 from public.lessons where id = target and status not in ('draft', 'rejected')) then
    raise exception 'Return the lesson to draft before editing its exercises or presets';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;
create trigger guard_exercises before insert or update or delete on public.exercises
for each row execute function private.guard_lesson_content();
create trigger guard_presets before insert or update or delete on public.visualization_presets
for each row execute function private.guard_lesson_content();

create function public.submit_exercise(target_exercise uuid, submitted_answer jsonb, used_hints integer default 0)
returns table(attempt_id uuid, is_correct boolean, explanation text)
language plpgsql security definer set search_path = '' as $$
declare question public.exercises; solution private.exercise_solutions; result_id uuid; correct boolean;
begin
  if private.current_role() is null then raise exception 'Active login required' using errcode = '42501'; end if;
  select * into question from public.exercises where id = target_exercise;
  if question.id is null or not exists (select 1 from public.lessons where id = question.lesson_id and status = 'published') then
    raise exception 'Published exercise not found' using errcode = '42501';
  end if;
  if submitted_answer is null or submitted_answer = 'null'::jsonb or octet_length(submitted_answer::text) > 65536 then
    raise exception 'Invalid answer';
  end if;
  if used_hints is null or used_hints not between 0 and cardinality(question.hints) then raise exception 'Invalid hint count'; end if;
  select * into solution from private.exercise_solutions where exercise_id = target_exercise;
  if solution.exercise_id is null then raise exception 'Exercise has no grading configuration'; end if;
  correct := submitted_answer = solution.correct_answer;
  insert into public.exercise_attempts(user_id, exercise_id, answer, is_correct, explanation, question_snapshot, hints_used)
  values (auth.uid(), target_exercise, submitted_answer, correct, solution.explanation,
    jsonb_build_object('prompt', question.prompt, 'kind', question.kind, 'config', question.question_config), used_hints)
  returning id into result_id;
  return query select result_id, correct, solution.explanation;
end;
$$;

create function public.admin_set_account(target_user uuid, new_role public.app_role, active boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  -- Role changes are rare; this lock also prevents concurrent removal of all admins.
  lock table public.profiles in share row exclusive mode;
  if not private.is_admin() then raise exception 'Admin required' using errcode = '42501'; end if;
  if new_role is null or active is null then raise exception 'Role and active flag are required'; end if;
  if not exists (select 1 from public.profiles where id = target_user) then raise exception 'User not found'; end if;
  if exists (select 1 from public.profiles where id = target_user and role = 'admin' and is_active)
    and (new_role <> 'admin' or not active)
    and (select count(*) from public.profiles where role = 'admin' and is_active) <= 1 then
    raise exception 'Cannot remove the last active admin';
  end if;
  update public.profiles set role = new_role, is_active = active where id = target_user;
end;
$$;

create function public.moderate_comment(target_comment uuid, hidden boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.lesson_comments where id = target_comment and private.manages_lesson(lesson_id)) then
    raise exception 'Not permitted' using errcode = '42501'; end if;
  update public.lesson_comments set is_hidden = hidden where id = target_comment;
end;
$$;
create function public.moderate_rating(target_user uuid, target_lesson uuid, hidden boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not private.manages_lesson(target_lesson) then raise exception 'Not permitted' using errcode = '42501'; end if;
  update public.lesson_ratings set is_hidden = hidden where user_id = target_user and lesson_id = target_lesson;
end;
$$;
create function public.resolve_comment_report(target_report uuid, resolution text, note text default '') returns void
language plpgsql security definer set search_path = '' as $$
begin
  if resolution is null or resolution not in ('resolved', 'dismissed') then raise exception 'Invalid resolution'; end if;
  if not exists (select 1 from public.comment_reports r join public.lesson_comments c on c.id = r.comment_id
    where r.id = target_report and private.manages_lesson(c.lesson_id)) then
    raise exception 'Not permitted' using errcode = '42501'; end if;
  update public.comment_reports set status = resolution, resolution_note = note,
    resolved_by = auth.uid(), resolved_at = now() where id = target_report;
end;
$$;

-- Views run as the caller, preserving table RLS (PostgreSQL 15+).
create view public.lesson_rating_summary with (security_invoker = true) as
select lesson_id, count(*) as rating_count, avg(rating)::numeric(3,2) as average_rating,
  count(*) filter (where rating = 1) as one_star,
  count(*) filter (where rating = 2) as two_star,
  count(*) filter (where rating = 3) as three_star,
  count(*) filter (where rating = 4) as four_star,
  count(*) filter (where rating = 5) as five_star
from public.lesson_ratings where not is_hidden group by lesson_id;

create view public.my_learning_stats with (security_invoker = true) as
select (select auth.uid()) as user_id,
  (select count(*) from public.lesson_progress where user_id = (select auth.uid()) and completed_at is not null) as lessons_completed,
  (select count(*) from public.exercise_attempts where user_id = (select auth.uid())) as exercises_attempted,
  (select count(distinct exercise_id) from public.exercise_attempts where user_id = (select auth.uid()) and is_correct) as exercises_completed,
  (select coalesce(avg(is_correct::integer), 0) from public.exercise_attempts where user_id = (select auth.uid())) as exercise_accuracy,
  (select coalesce(sum(active_seconds), 0) from public.learning_sessions where user_id = (select auth.uid())) as total_learning_seconds
where private.current_role() is not null;
revoke all on public.lesson_rating_summary, public.my_learning_stats from public, anon, authenticated;
grant select on public.lesson_rating_summary, public.my_learning_stats to authenticated, service_role;

-- PostgreSQL grants EXECUTE to PUBLIC by default. Restrict every new function.
do $$
declare fn record;
begin
  for fn in select p.oid::regprocedure as signature from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'private' and p.proname in ('current_role', 'is_admin', 'manages_lesson',
      'can_read_lesson', 'can_edit_lesson', 'can_read_comment', 'touch_updated_at',
      'handle_new_user', 'validate_lesson', 'guard_lesson_content') loop
    execute format('revoke all on function %s from public, anon, authenticated', fn.signature);
  end loop;
  for fn in select p.oid::regprocedure as signature from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname in ('set_exercise_solution', 'get_exercise_solution',
      'submit_lesson', 'return_lesson_to_draft', 'review_lesson', 'submit_exercise', 'admin_set_account',
      'moderate_comment', 'moderate_rating', 'resolve_comment_report') loop
    execute format('revoke all on function %s from public, anon, authenticated', fn.signature);
    execute format('grant execute on function %s to authenticated', fn.signature);
  end loop;
end;
$$;
grant execute on function private.current_role(), private.is_admin(), private.manages_lesson(uuid),
  private.can_read_lesson(uuid), private.can_edit_lesson(uuid), private.can_read_comment(uuid) to authenticated;

commit;
