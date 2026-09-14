create extension if not exists pgcrypto;

create table if not exists public.ed_records (
  user_id uuid not null references auth.users(id) on delete cascade,
  collection text not null,
  id text not null,
  payload jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, collection, id)
);

alter table public.ed_records enable row level security;

drop policy if exists "ed_records_select_own" on public.ed_records;
create policy "ed_records_select_own"
  on public.ed_records
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "ed_records_insert_own" on public.ed_records;
create policy "ed_records_insert_own"
  on public.ed_records
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "ed_records_update_own" on public.ed_records;
create policy "ed_records_update_own"
  on public.ed_records
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "ed_records_delete_own" on public.ed_records;
create policy "ed_records_delete_own"
  on public.ed_records
  for delete
  to authenticated
  using (auth.uid() = user_id);

create index if not exists ed_records_collection_idx
  on public.ed_records (user_id, collection, updated_at desc);
