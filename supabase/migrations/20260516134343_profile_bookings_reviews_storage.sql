alter table public.profiles
  add column if not exists avatar_url text not null default '',
  add column if not exists city text not null default 'Islamabad',
  add column if not exists address text not null default '',
  add column if not exists preferred_language text not null default 'English'
    check (preferred_language in ('English', 'Urdu', 'Roman Urdu')),
  add column if not exists bio text not null default '';

alter table public.service_providers
  add column if not exists phone text not null default '+923001234567',
  add column if not exists whatsapp text not null default '+923001234567',
  add column if not exists response_time_minutes integer not null default 18
    check (response_time_minutes >= 0);

alter table public.bookings
  add column if not exists provider_phone text not null default '',
  add column if not exists provider_whatsapp text not null default '';

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  provider_id uuid not null references public.service_providers(id) on delete cascade,
  booking_id uuid references public.bookings(id) on delete set null,
  rating integer not null check (rating between 1 and 5),
  comment text not null check (length(trim(comment)) >= 3),
  customer_name text not null default 'Customer',
  customer_avatar_url text not null default '',
  language text not null default 'English'
    check (language in ('English', 'Urdu', 'Roman Urdu')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists reviews_provider_id_created_at_idx
on public.reviews (provider_id, created_at desc);

drop trigger if exists reviews_set_updated_at on public.reviews;
create trigger reviews_set_updated_at
before update on public.reviews
for each row execute function public.set_updated_at();

alter table public.reviews enable row level security;

drop policy if exists "Anyone can read provider reviews" on public.reviews;
create policy "Anyone can read provider reviews"
on public.reviews for select
to anon, authenticated
using (true);

drop policy if exists "Users can create their own reviews" on public.reviews;
create policy "Users can create their own reviews"
on public.reviews for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own reviews" on public.reviews;
create policy "Users can update their own reviews"
on public.reviews for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own reviews" on public.reviews;
create policy "Users can delete their own reviews"
on public.reviews for delete
to authenticated
using ((select auth.uid()) = user_id);

grant select on public.reviews to anon, authenticated;
grant insert, update, delete on public.reviews to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can read avatars" on storage.objects;
create policy "Public can read avatars"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'avatars');

drop policy if exists "Users can upload their own avatars" on storage.objects;
create policy "Users can upload their own avatars"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can update their own avatars" on storage.objects;
create policy "Users can update their own avatars"
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can delete their own avatars" on storage.objects;
create policy "Users can delete their own avatars"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

update public.service_providers set
  phone = case id
    when '00000000-0000-0000-0000-000000000001' then '+923001111001'
    when '00000000-0000-0000-0000-000000000002' then '+923001111002'
    when '00000000-0000-0000-0000-000000000003' then '+923001111003'
    when '00000000-0000-0000-0000-000000000004' then '+923001111004'
    when '00000000-0000-0000-0000-000000000005' then '+923001111005'
    when '00000000-0000-0000-0000-000000000006' then '+923001111006'
    when '00000000-0000-0000-0000-000000000007' then '+923001111007'
    when '00000000-0000-0000-0000-000000000008' then '+923001111008'
    else phone
  end,
  whatsapp = case id
    when '00000000-0000-0000-0000-000000000001' then '+923001111001'
    when '00000000-0000-0000-0000-000000000002' then '+923001111002'
    when '00000000-0000-0000-0000-000000000003' then '+923001111003'
    when '00000000-0000-0000-0000-000000000004' then '+923001111004'
    when '00000000-0000-0000-0000-000000000005' then '+923001111005'
    when '00000000-0000-0000-0000-000000000006' then '+923001111006'
    when '00000000-0000-0000-0000-000000000007' then '+923001111007'
    when '00000000-0000-0000-0000-000000000008' then '+923001111008'
    else whatsapp
  end,
  response_time_minutes = case role
    when 'Electrician' then 14
    when 'Plumber' then 16
    when 'AC Repair' then 20
    when 'Cleaning' then 24
    when 'Tutor' then 35
    when 'Beautician' then 40
    else 25
  end,
  updated_at = now();

insert into public.reviews
  (provider_id, rating, comment, customer_name, language)
values
  ('00000000-0000-0000-0000-000000000001', 5, 'Clean work, clear pricing, arrived on time.', 'Verified customer', 'English'),
  ('00000000-0000-0000-0000-000000000003', 5, 'Kitchen leak fixed fast. Bohat professional.', 'Verified customer', 'Roman Urdu'),
  ('00000000-0000-0000-0000-000000000004', 4, 'AC cooling restored and the status updates were useful.', 'Verified customer', 'English')
on conflict do nothing;
