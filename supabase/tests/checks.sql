-- Run in the Supabase SQL editor after applying the migrations.
-- Raises on the first failure, prints "all checks passed" otherwise. No framework, no fixtures.

do $$
begin
  -- next_charge_date: on the charge day itself, today is the answer.
  assert public.next_charge_date('2026-01-15', 'monthly', null, '2026-01-15') = '2026-01-15',
    'monthly: charge day must not roll forward';

  -- Month-end clamping.
  assert public.next_charge_date('2026-01-31', 'monthly', null, '2026-02-01') = '2026-02-28',
    'monthly: Jan 31 must clamp to Feb 28';

  -- The regression this function exists for: after clamping it must return to day 31, not stay on 28.
  assert public.next_charge_date('2026-01-31', 'monthly', null, '2026-03-01') = '2026-03-31',
    'monthly: must return to day 31 after a clamped month';

  assert public.next_charge_date('2024-02-29', 'yearly', null, '2026-01-01') = '2026-02-28',
    'yearly: leap day must clamp on non-leap years';

  assert public.next_charge_date('2026-08-01', 'weekly', null, '2026-08-08') = '2026-08-08',
    'weekly: exact multiple must not roll forward';

  assert public.next_charge_date('2026-01-01', 'custom', 45, '2026-02-16') = '2026-04-01',
    'custom: must step by custom_days';

  assert public.next_charge_date('2026-01-01', 'custom', null, '2026-02-16') is null,
    'custom without custom_days must be null, never an endless loop';

  -- monthly_amount: everything normalized to one month.
  assert public.monthly_amount(120, 'yearly', null) = 10.00, 'yearly: 120/12';
  assert public.monthly_amount(100, 'monthly', null) = 100.00, 'monthly: unchanged';
  assert public.monthly_amount(30, 'weekly', null) = 130.00, 'weekly: 30*52/12';
  assert public.monthly_amount(45, 'custom', 45) = 30.44, 'custom: 45 days ~ one month';

  raise notice 'all checks passed';
end;
$$;

-- Every user table must have RLS on. Catches the table someone adds and forgets to protect.
-- force lives on pg_class, not pg_tables.
select c.relname, c.relrowsecurity, c.relforcerowsecurity
from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
  and c.relname <> 'keepalive'
  and (not c.relrowsecurity
       or (not c.relforcerowsecurity and c.relname <> 'profiles'));
-- Expected: zero rows.

-- Views must run as the caller, or they leak rows across users.
select c.relname, c.reloptions
from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'v'
  and (c.reloptions is null or not ('security_invoker=true' = any (c.reloptions)));
-- Expected: zero rows.
