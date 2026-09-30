-- Sổ chấm công: chạy 1 lần trong Supabase → SQL Editor → New query → Run

-- 1) Bảng lưu các lần chấm công
create table if not exists public.attendance_records (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  date        date not null,
  type        text not null check (type in ('in', 'out')),
  time        text not null check (time ~ '^\d{2}:\d{2}$'),
  orig_date   date,
  orig_time   text,
  source      text,
  note        text not null default '',
  photo_path  text,
  created_at  timestamptz not null default now()
);

create index if not exists attendance_records_user_date_idx
  on public.attendance_records (user_id, date);

-- Mỗi người chỉ xem/sửa/xoá được dữ liệu của chính mình
alter table public.attendance_records enable row level security;

drop policy if exists "attendance select own" on public.attendance_records;
drop policy if exists "attendance insert own" on public.attendance_records;
drop policy if exists "attendance update own" on public.attendance_records;
drop policy if exists "attendance delete own" on public.attendance_records;

create policy "attendance select own" on public.attendance_records
  for select to authenticated using (user_id = auth.uid());
create policy "attendance insert own" on public.attendance_records
  for insert to authenticated with check (user_id = auth.uid());
create policy "attendance update own" on public.attendance_records
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "attendance delete own" on public.attendance_records
  for delete to authenticated using (user_id = auth.uid());

-- 2) Kho ảnh riêng tư; ảnh của ai nằm trong thư mục <user_id>/...
insert into storage.buckets (id, name, public)
values ('attendance-photos', 'attendance-photos', false)
on conflict (id) do nothing;

drop policy if exists "photos select own" on storage.objects;
drop policy if exists "photos insert own" on storage.objects;
drop policy if exists "photos update own" on storage.objects;
drop policy if exists "photos delete own" on storage.objects;

create policy "photos select own" on storage.objects
  for select to authenticated
  using (bucket_id = 'attendance-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos insert own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'attendance-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos update own" on storage.objects
  for update to authenticated
  using (bucket_id = 'attendance-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos delete own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'attendance-photos' and (storage.foldername(name))[1] = auth.uid()::text);
