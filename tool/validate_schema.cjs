// Local PostgreSQL smoke test. PGlite emulates the Supabase Auth SQL interface.
// npm install --prefix .dart_tool/schema_validation --no-save --package-lock=false @electric-sql/pglite@0.5.9
const fs = require('node:fs');
const path = require('node:path');
const { PGlite } = require('../.dart_tool/schema_validation/node_modules/@electric-sql/pglite');

async function main() {
  const db = new PGlite();
  const root = path.resolve(__dirname, '..');
  try {
    await db.exec(`
      create role anon;
      create role authenticated;
      create role service_role bypassrls;
      grant usage on schema public to anon, authenticated, service_role;
      create schema auth;
      create table auth.users (id uuid primary key, email text, raw_user_meta_data jsonb);
      create function auth.uid() returns uuid language sql stable as
        $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
      grant usage on schema auth to anon, authenticated, service_role;
      grant execute on function auth.uid() to anon, authenticated, service_role;
    `);
    for (const file of [
      'supabase/migrations/20261013000000_initial_schema.sql',
      'supabase/seed.sql',
      'supabase/seed.sql',
      'supabase/tests/initial_schema_test.sql',
    ]) {
      await db.exec(fs.readFileSync(path.join(root, file), 'utf8'));
      console.log(`PASS ${file}`);
    }
    const result = await db.query('select count(*)::integer as count from public.topics');
    if (result.rows[0].count !== 16) throw new Error('Expected 16 seeded topics');
    console.log('PASS taxonomy and transactional fixture rollback');
  } finally {
    await db.close();
  }
}

main().catch((error) => {
  console.error(error.message);
  if (error.query) console.error(error.query);
  process.exitCode = 1;
});
