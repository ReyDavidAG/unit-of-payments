-- Row level security. Deny by default: no policy means no access.

alter table public.profiles enable row level security;
alter table public.cards enable row level security;
alter table public.subscriptions enable row level security;
alter table public.notification_log enable row level security;

-- force also subjects the table owner to RLS. Left off profiles on purpose: the signup trigger
-- writes as the owner, and forcing it there would make account creation depend on bypassrls.
alter table public.cards force row level security;
alter table public.subscriptions force row level security;
alter table public.notification_log force row level security;

-- Nothing in this schema is readable without a session.
revoke all on public.profiles, public.cards, public.subscriptions, public.notification_log from anon;

grant select, insert, update, delete
  on public.profiles, public.cards, public.subscriptions, public.notification_log
  to authenticated;
grant select on public.v_subscriptions, public.v_card_totals, public.v_upcoming to authenticated;

create policy profiles_select on public.profiles
  for select using (auth.uid() = id);
create policy profiles_update on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- with check on update is what stops a row from being handed to another user by rewriting user_id.
create policy cards_select on public.cards
  for select using (auth.uid() = user_id);
create policy cards_insert on public.cards
  for insert with check (auth.uid() = user_id);
create policy cards_update on public.cards
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy cards_delete on public.cards
  for delete using (auth.uid() = user_id);

create policy subs_select on public.subscriptions
  for select using (auth.uid() = user_id);
create policy subs_insert on public.subscriptions
  for insert with check (auth.uid() = user_id);
create policy subs_update on public.subscriptions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy subs_delete on public.subscriptions
  for delete using (auth.uid() = user_id);

create policy notif_select on public.notification_log
  for select using (auth.uid() = user_id);
create policy notif_insert on public.notification_log
  for insert with check (auth.uid() = user_id);
create policy notif_update on public.notification_log
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy notif_delete on public.notification_log
  for delete using (auth.uid() = user_id);
