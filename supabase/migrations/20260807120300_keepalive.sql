-- Target of the GitHub Actions ping. Free projects pause after 7 days without database activity.
-- Deliberately empty of real data: it is the only surface anon can touch.

create table public.keepalive (
  id        smallint primary key default 1,
  pinged_at timestamptz not null default now(),

  constraint keepalive_single_row check (id = 1)
);

insert into public.keepalive (id) values (1);

alter table public.keepalive enable row level security;

create policy keepalive_read on public.keepalive
  for select to anon, authenticated using (true);

grant select on public.keepalive to anon, authenticated;
