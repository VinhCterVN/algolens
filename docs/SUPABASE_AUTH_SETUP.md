# Supabase Auth Setup

The app already uses `supabase_flutter` for authentication and GoRouter for
`/login`, `/register`, `/forgot-password`, and the protected `/home` route.
Your initial migration creates profile/settings records when an Auth user signs up.
Do not rerun that migration to enable authentication.

## 1. Configure Email Authentication

In your Supabase dashboard, open **Authentication → Sign In / Providers → Email**
(some dashboard versions call this **Providers**). Enable email/password sign-in
and allow new users to sign up.

For development, turn **Confirm email** off if you want registration to open Home
immediately. With confirmation enabled, registration displays the verification
screen; Home opens after the email is confirmed. Keep confirmation enabled for
your production signup flow.

Match the app's signup password rules: at least 8 characters, a numeric digit,
and a symbol. Existing-user login accepts the password originally set for that account.

## 2. Add the Mobile Callback

Under **Authentication → URL Configuration → Redirect URLs**, add:

```text
io.algolens.app://auth/callback
```

The Android manifest already handles this URL. Supabase receives confirmation,
recovery, and OAuth callbacks through `app_links`; GoRouter then responds to the
session state. The Site URL can remain your website URL; the Android service
explicitly supplies the mobile callback.

## 3. Connect the App to Your Project

Copy the project URL and **publishable key** from your project's Connect dialog
or Settings → API Keys. A legacy `anon` key also works. Use values from the same
project in which you ran the migration. Do not use a secret or `service_role` key.

Create `.env` in the repository root using `.env.example` as a template:

```dotenv
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_ACTUAL_KEY
```

The `.env` file is ignored by Git and included as a Flutter asset.
`flutter_dotenv` loads it before `Supabase.initialize` runs. Launch from the repository root:

```powershell
flutter pub get
flutter run
```

For a specific emulator or device, append `-d <device-id>`. Stop and relaunch
after changing `.env` so the updated asset is bundled and loaded.
No `--dart-define` flags are needed for running or building the app.

Keep `.env` present for asset bundling. Authentication is unavailable if either value
is empty. Flutter assets can be extracted from the app, so include only the project
URL and publishable/anon key; keep secret and service-role keys on your server.

## 4. Register and Sign In

Open **Register here**, enter your name and email, choose a password meeting the
three displayed requirements, accept the academic guidelines, and select
**Initialize Account**. If email confirmation is disabled, the app opens Home.
Otherwise, confirm via the email link or code first.

Use the same email/password on **Sign In to Workspace**. Existing users can be
created through **Authentication → Users → Add user** with their email confirmed.
Do not insert user credentials into `public.profiles`: login accounts belong to
Supabase Auth. The database trigger creates the corresponding profile and settings.

GoRouter opens Home when a session exists and redirects signed-out users to Login.
Remembered Android sessions use secure storage and are restored for up to 30 days;
unchecking Remember keeps the session in memory. Backend session policies may expire
access sooner. Sign out is available in the Home header.

Selecting Professor / TA records a requested role in metadata. It never grants
professor or admin permissions. Use the database's administrator workflow to approve
that access after signup.

## 5. Enable the Six-Digit Email Flows

If signup emails contain only a fallback link, open **Authentication → Email
Templates → Confirm signup** (sometimes grouped under **Emails → Templates**).
Replace the body with the contents of
[`confirm_signup.html`](../supabase/templates/confirm_signup.html), then save.
Keep **Confirm email** enabled so registration waits for verification.

The essential variable is `{{ .Token }}`, not `{{ .TokenHash }}` or
`{{ .ConfirmationURL }}`. The supplied template contains the OTP and omits the
fallback link. Saving a template does not change emails already delivered:
return to the registration verification screen and request a new confirmation
email after the sending cooldown. The app verifies signup codes using `OtpType.email`.

For password recovery, paste
[`reset_password.html`](../supabase/templates/reset_password.html) into the
**Reset password** template. Files in this repository do not automatically update
hosted Supabase templates; paste and save each one in the dashboard.

Under **Authentication → Email Templates**, include the token in the **Reset
Password** template. Include it in **Confirm Signup** too if you want users to
enter a code in the registration screen:

```html
<h2>Your AlgoLens verification code</h2>
<p>{{ .Token }}</p>
```

You can retain the existing `{{ .ConfirmationURL }}` link alongside the code.
Set the email OTP length to 6 where configurable; a 900-second expiry matches a
15-minute recovery window. The forgot-password screen sends a recovery email,
verifies it with `OtpType.recovery`, then updates the password. A recovery session
stays on Reset Password until that update succeeds or the user cancels and signs out.

The default Supabase mail service restricts recipients and sending frequency.
Configure **Authentication → SMTP Settings** with your own SMTP provider to send
confirmation/reset emails to ordinary app users. Check Auth logs when an email
does not arrive. No SMTP secret belongs in the Flutter app.

## Optional GitHub and Google Sign-In

Enable the desired provider under Authentication → Sign In / Providers. Create
the corresponding OAuth application with GitHub or Google, copy the **Supabase
provider callback URL shown in the dashboard** into that provider's configuration,
and enter its client ID/secret in Supabase. This HTTPS provider callback is distinct
from the mobile redirect above. The existing provider buttons launch the OAuth flow.
Institutional SAML SSO requires separate provider setup and is not implemented by
the Learner/Educator selector.

## Auth State and Motion

Riverpod's `authRepositoryProvider` supplies the configured Supabase repository.
`authSessionProvider` owns session/recovery state and drives GoRouter redirects.
The auto-disposed `authFormProvider` family isolates loading, errors, and messages
for sign-in, registration, and recovery. Text controllers and short-lived field
preferences stay local to their screens; passwords are not stored in providers.

Auth routes fade and slide slightly, buttons animate presses/loading, role and
checkbox selection colors transition, and verification/recovery stages and
feedback fade between states. Durations are centralized in `AppMotion`; transforms
and transitions are disabled when the device requests reduced motion.

## Troubleshooting

| Symptom | Action |
| --- | --- |
| Authentication unavailable | Fill both keys in the root `.env` and relaunch the app. |
| Incorrect email/password | Confirm the account exists in Auth Users in the same project. |
| Email not confirmed | Confirm the email or confirm a development user in Auth Users. |
| Registration fails with a database error | Check Auth logs and the profile/settings signup trigger from the migration. |
| No recovery code | Include `{{ .Token }}` in the Reset Password template and configure SMTP. |
| Email link does not reopen Android app | Verify the exact redirect allowlist entry and reinstall the updated app. |
| Provider unavailable | Enable/configure that provider, or use email/password. |

Official references: [password authentication](https://supabase.com/docs/guides/auth/passwords),
[API keys](https://supabase.com/docs/guides/getting-started/api-keys),
[email templates](https://supabase.com/docs/guides/auth/auth-email-templates),
[SMTP](https://supabase.com/docs/guides/auth/auth-smtp), and
[mobile callbacks](https://supabase.com/docs/guides/auth/native-mobile-deep-linking).
