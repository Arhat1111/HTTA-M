HTTA SUPABASE LOGIN TEST V1

This is intentionally NOT the HTTA management app.

1. Create one owner user under Supabase -> Authentication -> Users.
2. Auto-confirm the user.
3. Run START_TEST_MAC.command (or Windows .bat).
4. Open http://localhost:8080
5. Press "Test Supabase Connection".
6. Enter the exact owner email/password.
7. Press "Sign In".

Expected:
CONNECTION SUCCESS
then
LOGIN SUCCESS

If either fails, copy the exact error shown in the box.

There is NO service worker, NO Firebase, NO database code and NO external Supabase JS library in this test.
