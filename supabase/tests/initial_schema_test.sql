-- Run with a database-owner connection on a disposable migrated Supabase database.
-- Transaction rolls back every fixture. This is a plain SQL test, not pgTAP.
begin;

create function pg_temp.assert_true(value boolean, message text) returns void
language plpgsql as $$
begin if value is distinct from true then raise exception 'Assertion failed: %', message; end if; end;
$$;
create function pg_temp.expect_error(command text, expected_state text default '42501') returns void
language plpgsql as $$
declare failed boolean := false;
begin
  begin execute command;
  exception when others then
    if sqlstate <> expected_state then raise exception 'Expected %, got %: %', expected_state, sqlstate, sqlerrm; end if;
    failed := true;
  end;
  if not failed then raise exception 'Expected command to fail: %', command; end if;
end;
$$;

insert into auth.users(id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-000000000001', 'schema-admin@example.invalid', '{"role":"admin"}'),
  ('00000000-0000-0000-0000-000000000002', 'schema-professor@example.invalid', '{}'),
  ('00000000-0000-0000-0000-000000000003', 'schema-other-professor@example.invalid', '{}'),
  ('00000000-0000-0000-0000-000000000004', 'schema-learner@example.invalid', '{}'),
  ('00000000-0000-0000-0000-000000000005', 'schema-other-learner@example.invalid', '{}');
select pg_temp.assert_true((select role = 'learner' from public.profiles where id = '00000000-0000-0000-0000-000000000001'), 'Signup metadata cannot promote users');
select pg_temp.assert_true((select count(*) = 5 from public.user_settings where user_id::text like '00000000-0000-0000-0000-00000000000%'), 'Signup creates settings');
update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-000000000001';
update public.profiles set role = 'professor' where id in ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000003');
insert into public.categories(id, kind, slug, name) values ('00000000-0000-0000-0000-000000000010', 'algorithm', 'schema-test-category', 'Test');
insert into public.topics(id, category_id, slug, title) values ('00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000010', 'schema-test-topic', 'Test');

set local role anon;
select pg_temp.expect_error('select * from public.profiles');
select pg_temp.expect_error('select * from public.lessons');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000002"}', true);
insert into public.lessons(id, topic_id, author_id, slug, title) values
  ('00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000002', 'schema-test-lesson', 'Test Lesson');
select pg_temp.expect_error($q$select public.submit_lesson('00000000-0000-0000-0000-000000000020')$q$, 'P0001');
insert into public.exercises(id, lesson_id, position, kind, prompt) values
  ('00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000020', 1, 'multiple_choice', 'Choose one');
select pg_temp.expect_error($q$select public.submit_lesson('00000000-0000-0000-0000-000000000020')$q$, 'P0001');
select public.set_exercise_solution('00000000-0000-0000-0000-000000000021', '1', 'One is correct');
select pg_temp.expect_error($q$insert into public.exercises(lesson_id, position, kind, prompt) values ('00000000-0000-0000-0000-000000000020', 3, 'output', 'Invalid third exercise')$q$, '23514');
select pg_temp.expect_error($q$update public.lessons set status = 'published'$q$);
select public.submit_lesson('00000000-0000-0000-0000-000000000020');
select pg_temp.expect_error($q$select public.set_exercise_solution('00000000-0000-0000-0000-000000000021', '2', '')$q$);
select pg_temp.expect_error($q$select public.review_lesson('00000000-0000-0000-0000-000000000020', 'published')$q$);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000003', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000003"}', true);
select pg_temp.assert_true((select count(*) = 0 from public.lessons where id = '00000000-0000-0000-0000-000000000020'), 'Other professors cannot read drafts');
select pg_temp.expect_error($q$select public.get_exercise_solution('00000000-0000-0000-0000-000000000021')$q$);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000004', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000004"}', true);
select pg_temp.assert_true((select count(*) = 0 from public.lessons where id = '00000000-0000-0000-0000-000000000020'), 'Learners cannot read drafts');
select pg_temp.expect_error($q$select public.submit_exercise('00000000-0000-0000-0000-000000000021', '1')$q$);
select pg_temp.expect_error($q$update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-000000000004'$q$);
select pg_temp.expect_error($q$select public.admin_set_account('00000000-0000-0000-0000-000000000004', 'admin', true)$q$);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000001"}', true);
select public.review_lesson('00000000-0000-0000-0000-000000000020', 'published', 'Approved');
select pg_temp.expect_error($q$select public.admin_set_account('00000000-0000-0000-0000-000000000001', 'learner', true)$q$, 'P0001');

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000004', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000004"}', true);
select pg_temp.assert_true((select count(*) = 1 from public.lessons where id = '00000000-0000-0000-0000-000000000020'), 'Published lessons are visible');
select pg_temp.expect_error('select * from private.exercise_solutions');
select pg_temp.expect_error($q$select public.get_exercise_solution('00000000-0000-0000-0000-000000000021')$q$);
select pg_temp.assert_true((select not is_correct from public.submit_exercise('00000000-0000-0000-0000-000000000021', '2')), 'Incorrect answer is graded on the server');
select pg_temp.assert_true((select is_correct from public.submit_exercise('00000000-0000-0000-0000-000000000021', '1')), 'Correct answer is graded on the server');
select pg_temp.assert_true((select exercises_attempted = 2 and exercises_completed = 1 and exercise_accuracy = 0.5 from public.my_learning_stats), 'Statistics derive from attempts');
select pg_temp.expect_error($q$insert into public.exercise_attempts(user_id, exercise_id, answer, is_correct, explanation, question_snapshot) values ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000021', '1', true, '', '{}')$q$);
insert into public.saved_workspaces(user_id, title, engine_key) values ('00000000-0000-0000-0000-000000000004', 'Private workspace', 'bubble_sort');
insert into public.lesson_comments(id, user_id, lesson_id, body) values ('00000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000020', 'Helpful lesson');
insert into public.lesson_ratings(user_id, lesson_id, rating) values ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000020', 5);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000005', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000005"}', true);
select pg_temp.assert_true((select count(*) = 0 from public.saved_workspaces), 'Workspaces are private');
select pg_temp.assert_true((select count(*) = 0 from public.exercise_attempts), 'Learners cannot read others attempts');
select pg_temp.expect_error($q$insert into public.saved_workspaces(user_id, engine_key) values ('00000000-0000-0000-0000-000000000004', 'test')$q$);
insert into public.comment_reports(comment_id, reporter_id, reason) values ('00000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000005', 'Please review');
insert into public.lesson_comments(id, user_id, lesson_id, parent_id, body) values ('00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000030', 'A reply to preserve');
select pg_temp.expect_error($q$select public.moderate_comment('00000000-0000-0000-0000-000000000030', true)$q$);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000002"}', true);
select pg_temp.assert_true((select count(*) = 2 from public.exercise_attempts), 'Authors can inspect their own lesson attempts');
with edited as (update public.exercises set prompt = 'Changed live content' where id = '00000000-0000-0000-0000-000000000021' returning id)
select pg_temp.assert_true((select count(*) = 0 from edited), 'Published exercise content cannot be edited');
select pg_temp.expect_error($q$insert into public.exercises(lesson_id, position, kind, prompt) values ('00000000-0000-0000-0000-000000000020', 2, 'output', 'Changed live content')$q$, 'P0001');
select public.moderate_comment('00000000-0000-0000-0000-000000000030', true);
select public.moderate_rating('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000020', true);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000005', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000005"}', true);
select pg_temp.assert_true((select count(*) = 0 from public.lesson_comments where id = '00000000-0000-0000-0000-000000000030'), 'Hidden comments are not visible to other learners');
select pg_temp.assert_true((select count(*) = 0 from public.lesson_rating_summary), 'Hidden ratings are excluded from aggregates');

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000004', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000004"}', true);
delete from public.lesson_comments where id = '00000000-0000-0000-0000-000000000030';
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000005', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000005"}', true);
select pg_temp.assert_true((select parent_id is null from public.lesson_comments where id = '00000000-0000-0000-0000-000000000031'), 'Deleting a parent preserves other users replies');

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000001"}', true);
select public.admin_set_account('00000000-0000-0000-0000-000000000005', 'learner', false);
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000005', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000005"}', true);
select pg_temp.assert_true((select count(*) = 0 from public.topics), 'Suspended accounts lose catalog access');
select pg_temp.expect_error($q$select public.submit_exercise('00000000-0000-0000-0000-000000000021', '1')$q$);

reset role;
rollback;
