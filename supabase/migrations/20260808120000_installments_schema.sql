-- Installment plans (MSI), third-party debt, and card statement dates.
-- Columns and constraints only. Functions and views live in the next migration.

create type public.charge_kind as enum ('subscription', 'installment');
create type public.notice_kind as enum ('charge', 'cutoff', 'payment_due');

-- The cutoff closes the statement; the due day is the one with consequences.
-- Alerting on the cutoff alone tells the user nothing they can act on.
alter table public.cards
  add column payment_due_day smallint;

alter table public.cards
  add constraint cards_due_rng check (payment_due_day is null or payment_due_day between 1 and 31);

-- An installment plan is a monthly charge with a known end. Reusing this table
-- keeps next_charge_date, the card totals and every RLS policy working on it
-- unchanged; a second table would turn each total into a union forever.
alter table public.subscriptions
  add column kind public.charge_kind not null default 'subscription',
  add column installments_total smallint,
  -- Set when someone else repays this charge: a lent card, a shared plan.
  add column owed_by text;

alter table public.subscriptions
  add constraint subs_installments check (
    (kind = 'installment' and installments_total between 2 and 60 and cycle = 'monthly')
    or (kind = 'subscription' and installments_total is null)
  ),
  add constraint subs_owed_by_len check (
    owed_by is null or char_length(owed_by) between 1 and 40
  );

-- Notices now come from a card as well as from a subscription.
alter table public.notification_log
  alter column subscription_id drop not null;

alter table public.notification_log
  add column card_id uuid,
  add column kind public.notice_kind not null default 'charge',
  -- A timestamp, not a boolean: it answers the same question via `is not null`
  -- and also says whether the user knew before or after the due date.
  -- Distinct from opened_at, which only means the notification was seen.
  add column acknowledged_at timestamptz;

alter table public.notification_log
  add constraint notif_target_xor check (
    (subscription_id is not null) <> (card_id is not null)
  ),
  -- Same reasoning as subs_card_fk: RLS hides another user's card but would
  -- not stop a row from being written against it.
  add constraint notif_card_fk foreign key (card_id, user_id)
    references public.cards (id, user_id) on delete cascade;

-- The old key assumed every notice had a subscription. One per target instead.
alter table public.notification_log
  drop constraint notif_once;

create unique index notif_once_sub on public.notification_log (subscription_id, charge_date)
  where subscription_id is not null;

create unique index notif_once_card on public.notification_log (card_id, charge_date, kind)
  where card_id is not null;

create index notif_card_idx on public.notification_log (card_id);
create index subs_owed_by_idx on public.subscriptions (user_id, owed_by)
  where owed_by is not null;
