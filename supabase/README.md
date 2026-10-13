# AlgoLens Database

The SQL models the roles and screens in the [shared app prompt](https://chatgpt.com/share/6ace5395-ca4c-83ec-9227-548959c5b12f).
The linked Stitch project could not be inspected in this environment; its layout
has not been treated as an additional source of database requirements.

## Apply the SQL

For a **fresh Supabase project**, open its SQL Editor and run
[`migrations/20261013000000_initial_schema.sql`](migrations/20261013000000_initial_schema.sql).
Then optionally run [`seed.sql`](seed.sql) to create 11 categories and 16 starter
topics. The seed is repeatable; the initial migration is intentionally run once.
Both scripts use transactions. They do not create a remote project or change
any existing deployment as part of generating these files.

Supabase already supplies `auth.users`, `auth.uid()`, and the `anon`,
`authenticated`, and `service_role` roles. Use Supabase Auth for signup, login,
password reset, sessions, and logout. Do not store passwords in application tables.

After signing up your administrator, promote that account in the SQL Editor
using a database-owner connection:

```sql
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'your-admin@example.com')
returning id, display_name, role;
```

Replace the email with your actual account and verify exactly one returned row.
Subsequent role changes use `admin_set_account`; it prevents removal of the last
active administrator. Signup always creates a learner, even if signup metadata
claims an admin or professor role. Existing Auth accounts are backfilled as learners.

## Screen-to-Table Mapping

| Feature | Tables / views |
| --- | --- |
| Profile and professor identity | `profiles` |
| Appearance and preferences | `user_settings` |
| Data structures / algorithms catalogs | `categories`, `topics` |
| Lessons, objectives, pseudocode, complexity | `lessons` |
| Example visualization configurations | `visualization_presets` |
| Exercises and hidden grading keys | `exercises`, `private.exercise_solutions` |
| Professor submission / admin approval | `lesson_reviews` |
| Continue learning / completion history | `lesson_progress` |
| Practice history / accuracy | `exercise_attempts` |
| Weekly activity / time / streak inputs | `learning_sessions` |
| Saved learning and playground canvases | `saved_workspaces` |
| Saved lessons | `lesson_bookmarks` |
| Stars and rating distributions | `lesson_ratings`, `lesson_rating_summary` |
| Discussions, replies, helpful sorting | `lesson_comments`, `comment_helpful_votes` |
| Comment moderation | `comment_reports` |
| Notification inbox | `notifications` |
| Personal dashboard statistics | `my_learning_stats` |

Profiles expose only display metadata, role, account status, and timestamps to
signed-in active users; email remains in Supabase Auth. User settings, bookmarks,
and workspaces are private to their owner. Administrators and lesson authors can
read learner progress, time, and attempts for analytics; professors see only their
own lessons. Anonymous clients have no application-table access. Suspending an
account removes its application access without depending on JWT refresh.

Catalog and profile tables are relational. Canvas nodes, edges, input, and
viewport state use versioned JSON objects because their shape depends on the
visualization engine. The Flutter engine handles animation, playback, and layout;
the database stores presets and snapshots rather than every animation frame.

## Lesson and Exercise Workflow

1. A professor or admin inserts a draft lesson with their own `author_id`.
2. Add one or two exercises using `position` 1 and/or 2, and optional presets.
3. Call `set_exercise_solution(target_exercise, expected_answer, feedback)` for
   each exercise. Authors can retrieve their own keys with `get_exercise_solution`.
4. Call `submit_lesson(target_lesson)`. Submission requires 1–2 exercises, each
   with an answer key. The lesson becomes `pending_review` and cannot be edited.
5. An admin calls `review_lesson(target_lesson, decision, review_note)` with
   `published`, `rejected`, or `archived`. Only published lessons reach learners.
6. Editing requires `return_lesson_to_draft(target_lesson)`, which unpublishes
   the lesson. Edit, submit, and approve it again. Separate live/draft revisions
   are a future extension, rather than part of this initial schema.

Call `submit_exercise(target_exercise, submitted_answer, used_hints)` to grade
an answer and record an immutable attempt. It returns the attempt ID, correctness,
and explanation. Clients cannot write correctness or read the answer-key table.
Attempts snapshot the question and feedback so later content edits preserve the
meaning of previous attempts.

Initial grading uses exact JSON equality. For multiple choice, use a stable
option ID such as `"option_b"`; for arranging values, use an ordered JSON array
such as `[1, 2, 3]`. Output, next-step, and pseudocode questions must have a
canonical JSON answer. Free-form code execution, fuzzy text grading, and AI
grading require a trusted backend and are not implemented by this SQL.

Example author calls (replace the UUID with your exercise ID):

```sql
select public.set_exercise_solution(
  '00000000-0000-0000-0000-000000000021',
  '"option_b"'::jsonb,
  'The pivot divides the remaining search interval.'
);
```

Store `question_config` as an object, for example:

```json
{"options": [{"id": "option_a", "text": "Linear scan"}, {"id": "option_b", "text": "Halve the interval"}]}
```

## Moderation and Statistics

Use `moderate_comment`, `moderate_rating`, and `resolve_comment_report` for
protected moderation. Professors moderate their own lessons; admins moderate all
lessons. Hidden ratings are excluded from the rating summary. Deleting a comment
keeps other users' replies, which become top-level comments.

Mark notifications read by updating `read_at`; only a trusted backend can create
them. Notification delivery and recommendation logic are application/backend work.
Lesson completion and active learning time are user-reported learning metrics,
not certification evidence. Marking a lesson complete requires both
`progress_percent = 100` and `completed_at`. Exercise accuracy is derived from
server-graded attempts; repeated tries count toward the attempt-based accuracy.

Compute weekly activity and streaks from session dates in the user's `time_zone`,
and topic mastery from correct exercises grouped through their lessons and topics.
Counts and progress percentages are derived, rather than maintained in duplicate
counter columns. No classes, enrollment payments, or live collaboration are assumed.

The initial permission model uses three fixed roles rather than a customizable
permission matrix. Lesson authors cannot be deleted while lessons reference them;
reassign or remove those lessons through a trusted backend before deleting an
author's Auth account. Deleting a lesson also deletes its progress and attempts.
Prefer archiving content when learning history should be retained.

## Validate and Extend

An in-memory PostgreSQL smoke test checks schema creation, seeds, Auth-trigger
behavior, RLS isolation, role escalation, publication, grading, and moderation:

```sh
npm install --prefix .dart_tool/schema_validation --no-save --package-lock=false @electric-sql/pglite@0.5.9
node tool/validate_schema.cjs
```

PGlite mocks the Supabase Auth SQL interface. It does not validate GoTrue, the
Data API, storage, or a hosted Supabase deployment. To validate the same policies
in a migrated disposable Supabase database, run the plain SQL
[`tests/initial_schema_test.sql`](tests/initial_schema_test.sql) as its database
owner. It creates temporary assertions and rolls back all fixtures; do not run
it concurrently with application traffic.

Keep future schema changes in new timestamped migrations. Define grants and RLS
together, restrict function execution, and give every definer function a fixed
search path. Keep the service-role key on a trusted server. Never include it in
the Flutter app. Storage buckets and upload policies should be added when avatar
or lesson-media uploads are implemented; `avatar_url` stores a URL for now.

Security patterns follow the official Supabase guidance for
[RLS](https://supabase.com/docs/guides/database/postgres/row-level-security) and
[Auth-linked profiles](https://supabase.com/docs/guides/auth/managing-user-data).
