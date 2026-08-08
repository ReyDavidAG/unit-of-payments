-- Types, tables and constraints. No business logic, no policies.

create type public.billing_cycle as enum ('weekly', 'monthly', 'yearly', 'custom');
create type public.card_brand as enum ('visa', 'mastercard', 'amex', 'other');

create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  currency     char(3) not null default 'MXN',
  timezone     text not null default 'America/Mexico_City',
  created_at   timestamptz not null default now(),

  constraint profiles_currency_fmt check (currency ~ '^[A-Z]{3}$')
);

-- Card aliases only. Never a PAN, a CVV or an expiry date: this app does not process payments.
create table public.cards (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  alias      text not null,
  brand      public.card_brand not null default 'other',
  last4      char(4),
  cutoff_day smallint,
  -- One of the eight curated swatches in DESIGN.md. No free colour picker.
  color      text not null default '#4B84E2',
  archived   boolean not null default false,
  created_at timestamptz not null default now(),

  constraint cards_alias_len  check (char_length(alias) between 1 and 40),
  -- Rejects anything but 4 digits, so a full card number cannot be pasted here.
  constraint cards_last4_fmt  check (last4 is null or last4 ~ '^[0-9]{4}$'),
  constraint cards_cutoff_rng check (cutoff_day is null or cutoff_day between 1 and 31),
  constraint cards_color_fmt  check (color ~ '^#[0-9A-Fa-f]{6}$'),
  constraint cards_alias_uniq unique (user_id, alias),
  -- Target of the composite FK below, which keeps a subscription on its own owner's card.
  constraint cards_id_user_uniq unique (id, user_id)
);

create table public.subscriptions (
  id                   uuid primary key default gen_random_uuid(),
  user_id              uuid not null default auth.uid() references auth.users (id) on delete cascade,
  card_id              uuid,
  name                 text not null,
  amount               numeric(12, 2) not null,
  cycle                public.billing_cycle not null default 'monthly',
  custom_days          smallint,
  first_charge_date    date not null,
  ends_on              date,
  reminder_days_before smallint not null default 1,
  category             text,
  active               boolean not null default true,
  notes                text,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),

  constraint subs_name_len      check (char_length(name) between 1 and 60),
  constraint subs_amount_pos    check (amount > 0),
  constraint subs_reminder_rng  check (reminder_days_before between 0 and 30),
  constraint subs_notes_len     check (notes is null or char_length(notes) <= 500),
  -- custom_days belongs to the 'custom' cycle and to no other: blocks impossible states.
  constraint subs_custom_days   check (
    (cycle = 'custom' and custom_days between 1 and 365)
    or (cycle <> 'custom' and custom_days is null)
  ),
  constraint subs_ends_after    check (ends_on is null or ends_on >= first_charge_date),
  -- Composite FK: a subscription can only point at a card owned by the same user.
  -- RLS hides other users' cards but would not stop the row from being written.
  constraint subs_card_fk foreign key (card_id, user_id)
    references public.cards (id, user_id) on delete set null (card_id)
);

create table public.notification_log (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null default auth.uid() references auth.users (id) on delete cascade,
  subscription_id uuid not null references public.subscriptions (id) on delete cascade,
  charge_date     date not null,
  scheduled_for   timestamptz not null,
  delivered_at    timestamptz,
  opened_at       timestamptz,
  amount          numeric(12, 2) not null,
  title           text not null,
  created_at      timestamptz not null default now(),

  -- The client reschedules on every launch; this makes the insert idempotent.
  constraint notif_once unique (subscription_id, charge_date)
);

-- RLS filters by user_id on every query, so it must be indexed.
create index cards_user_idx on public.cards (user_id);
create index subs_user_idx on public.subscriptions (user_id);
create index subs_card_idx on public.subscriptions (card_id);
create index notif_user_idx on public.notification_log (user_id);
create index notif_pending_idx on public.notification_log (user_id, charge_date)
  where delivered_at is null;
