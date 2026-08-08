-- Fixes everything `supabase db advisors` flagged on the first push.

-- 1. Pin search_path. A mutable search_path lets a caller shadow an unqualified
--    name with their own schema and change what the function actually runs.
alter function public.next_charge_date(date, public.billing_cycle, int, date)
  set search_path = '';
alter function public.monthly_amount(numeric, public.billing_cycle, int)
  set search_path = '';
alter function public.set_updated_at() set search_path = '';

-- 2. handle_new_user is a trigger function, but PostgREST exposed it as
--    /rest/v1/rpc/handle_new_user, callable by anon as security definer.
--    Triggers check EXECUTE at creation time, not at fire time, so revoking
--    closes the endpoint without breaking signup.
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- 3. auth.uid() was re-evaluated once per row. Wrapping it in a subquery makes
--    Postgres treat it as a constant for the statement.
alter policy profiles_select on public.profiles
  using ((select auth.uid()) = id);
alter policy profiles_update on public.profiles
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

alter policy cards_select on public.cards
  using ((select auth.uid()) = user_id);
alter policy cards_insert on public.cards
  with check ((select auth.uid()) = user_id);
alter policy cards_update on public.cards
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
alter policy cards_delete on public.cards
  using ((select auth.uid()) = user_id);

alter policy subs_select on public.subscriptions
  using ((select auth.uid()) = user_id);
alter policy subs_insert on public.subscriptions
  with check ((select auth.uid()) = user_id);
alter policy subs_update on public.subscriptions
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
alter policy subs_delete on public.subscriptions
  using ((select auth.uid()) = user_id);

alter policy notif_select on public.notification_log
  using ((select auth.uid()) = user_id);
alter policy notif_insert on public.notification_log
  with check ((select auth.uid()) = user_id);
alter policy notif_update on public.notification_log
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
alter policy notif_delete on public.notification_log
  using ((select auth.uid()) = user_id);
