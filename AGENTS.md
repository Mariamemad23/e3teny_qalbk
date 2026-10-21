<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

- Keep opening-screen artwork and positioning in a dedicated presentation component; original multi-line assets stay intact to preserve lettering.
- Accounts are username-only: server functions in src/lib/accounts.functions.ts map usernames to an internal sign-in id, verify the chosen role server-side, and only admins (or the one-time ADMIN_SETUP_CODE bootstrap while no admin exists) create accounts; public signup stays disabled. Why: girls have no email and roles must never be client-trusted.
