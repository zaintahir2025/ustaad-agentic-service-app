create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  phone text,
  reputation_score integer not null default 98 check (reputation_score between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_providers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  role text not null check (role in ('Electrician', 'Plumber', 'AC Repair', 'Cleaning', 'General')),
  reliability numeric(4, 3) not null default 0.850 check (reliability between 0 and 1),
  distance_km integer not null default 5 check (distance_km >= 0),
  rating numeric(2, 1) not null default 4.5 check (rating between 0 and 5),
  price integer not null default 800 check (price >= 0),
  avatar_url text not null default '',
  verified boolean not null default false,
  city text not null default 'Islamabad',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider_id uuid references public.service_providers(id) on delete set null,
  provider_name text not null,
  service_role text not null,
  problem_text text not null,
  service_location text not null,
  urgency text not null default 'normal' check (urgency in ('normal', 'high')),
  quote_base integer not null default 0 check (quote_base >= 0),
  quote_distance integer not null default 0 check (quote_distance >= 0),
  quote_urgency integer not null default 0 check (quote_urgency >= 0),
  quote_total integer not null default 0 check (quote_total >= 0),
  status text not null default 'scheduled'
    check (status in ('scheduled', 'en_route', 'completed', 'cancelled', 'issue_reported')),
  eta_minutes integer not null default 15 check (eta_minutes >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists service_providers_set_updated_at on public.service_providers;
create trigger service_providers_set_updated_at
before update on public.service_providers
for each row execute function public.set_updated_at();

drop trigger if exists bookings_set_updated_at on public.bookings;
create trigger bookings_set_updated_at
before update on public.bookings
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.service_providers enable row level security;
alter table public.bookings enable row level security;

drop policy if exists "Users can read their own profile" on public.profiles;
create policy "Users can read their own profile"
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Users can insert their own profile"
on public.profiles for insert
to authenticated
with check ((select auth.uid()) = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

drop policy if exists "Anyone can read active providers" on public.service_providers;
create policy "Anyone can read active providers"
on public.service_providers for select
to anon, authenticated
using (active = true);

drop policy if exists "Users can read their own bookings" on public.bookings;
create policy "Users can read their own bookings"
on public.bookings for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own bookings" on public.bookings;
create policy "Users can create their own bookings"
on public.bookings for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own bookings" on public.bookings;
create policy "Users can update their own bookings"
on public.bookings for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

grant usage on schema public to anon, authenticated;
grant select on public.service_providers to anon, authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.bookings to authenticated;

insert into public.service_providers
  (id, name, role, reliability, distance_km, rating, price, avatar_url, verified, city, active)
values
  ('00000000-0000-0000-0000-000000000001', 'Ahmed Khan', 'Electrician', 0.950, 5, 4.9, 500, 'https://i.pravatar.cc/100?img=11', true, 'Islamabad', true),
  ('00000000-0000-0000-0000-000000000002', 'Bilal Tariq', 'Electrician', 0.800, 2, 4.2, 400, 'https://i.pravatar.cc/100?img=12', false, 'Rawalpindi', true),
  ('00000000-0000-0000-0000-000000000003', 'Kamran Ali', 'Plumber', 0.900, 8, 4.7, 600, 'https://i.pravatar.cc/100?img=13', true, 'Islamabad', true),
  ('00000000-0000-0000-0000-000000000004', 'Sajid Hussain', 'AC Repair', 0.850, 3, 4.5, 800, 'https://i.pravatar.cc/100?img=14', true, 'Lahore', true),
  ('00000000-0000-0000-0000-000000000005', 'Usman Ghani', 'Electrician', 0.980, 12, 5.0, 700, 'https://i.pravatar.cc/100?img=15', true, 'Karachi', true),
  ('00000000-0000-0000-0000-000000000006', 'Nadia Services', 'Cleaning', 0.920, 6, 4.8, 650, 'https://i.pravatar.cc/100?img=16', true, 'Islamabad', true)
on conflict (id) do update set
  name = excluded.name,
  role = excluded.role,
  reliability = excluded.reliability,
  distance_km = excluded.distance_km,
  rating = excluded.rating,
  price = excluded.price,
  avatar_url = excluded.avatar_url,
  verified = excluded.verified,
  city = excluded.city,
  active = excluded.active,
  updated_at = now();
