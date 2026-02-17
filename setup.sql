-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. PROPERTIES TABLE
create table properties (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  address text not null,
  city text,
  zip text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. INSPECTIONS
create type inspection_status as enum ('pending', 'scheduled', 'in_progress', 'complete');
create table inspections (
  id uuid default uuid_generate_v4() primary key,
  property_id uuid references properties(id) not null,
  user_id uuid references auth.users not null,
  status inspection_status default 'pending',
  scheduled_at timestamp with time zone,
  notes text,
  price_cents integer default 15000,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. PHOTOS
create table photos (
  id uuid default uuid_generate_v4() primary key,
  inspection_id uuid references inspections(id) not null,
  storage_path text not null,
  url text not null,
  uploaded_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. SUBSCRIPTIONS
create table subscriptions (
  user_id uuid references auth.users primary key,
  stripe_customer_id text,
  stripe_subscription_id text,
  status text check (status in ('active', 'past_due', 'canceled', 'incomplete')),
  plan_type text default 'basic',
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- RLS POLICIES
alter table properties enable row level security;
alter table inspections enable row level security;
alter table photos enable row level security;
alter table subscriptions enable row level security;

create policy "Users can view own properties" on properties for select using (auth.uid() = user_id);
create policy "Users can insert own properties" on properties for insert with check (auth.uid() = user_id);
create policy "Users can view own inspections" on inspections for select using (auth.uid() = user_id);
create policy "Users can insert own inspections" on inspections for insert with check (auth.uid() = user_id);
