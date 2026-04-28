-- =========================================================================
-- FÁBRICA DE SONHOS (SAAS) - ARQUITETURA DO BANCO DE DADOS (SUPABASE)
-- =========================================================================
-- Este SQL cria toda a retaguarda relacional para rodar a Fábrica de Sonhos
-- Basta rodar no SQL Editor do Supabase.

-- =========================================================================
-- LIMPEZA DO BANCO DE DADOS ANTIGO (Zerar tabelas da versão de Teste)
-- =========================================================================
DROP TABLE IF EXISTS vip_briefings CASCADE;
DROP TABLE IF EXISTS finance_logs CASCADE;
DROP TABLE IF EXISTS mural_messages CASCADE;
DROP TABLE IF EXISTS invitations CASCADE;
DROP TABLE IF EXISTS themes CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS plans CASCADE;

-- 1. TABELA DE PLANOS DE REVENDA E B2C (PRICING)
create table plans (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  price numeric(10, 2) not null,
  plan_type text not null check (plan_type in ('b2c_single', 'b2b_subscription')),
  mp_checkout_link text,
  max_invites integer default 1,         -- Ilimitado = 99999
  has_white_label boolean default false,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 2. TABELA DE USUÁRIOS/CLIENTES E REVENDEDORES
create table profiles (
  id uuid primary key, -- Ideal: references auth.users no futuro
  full_name text not null,
  email text unique not null,
  role text default 'client' check (role in ('admin', 'reseller', 'client')),
  plan_id uuid references plans(id),
  status text default 'active' check (status in ('active', 'suspended', 'banned')),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 3. TABELA MOTOR DE TEMAS
create table themes (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  category text not null,
  css_variables jsonb not null default '{}'::jsonb, -- Cores e Gradientes injetados via React
  is_active boolean default true,
  usage_count integer default 0
);

-- 4. TABELA MESTRA DE CONVITES (O SISTEMA CORE)
create table invitations (
  id uuid default gen_random_uuid() primary key,
  slug text unique not null,                  -- Ex: 15-anos-emilly
  owner_id uuid references profiles(id) on delete cascade not null,
  theme_id uuid references themes(id),
  title text not null,
  event_date timestamp with time zone,
  maps_link text,
  audio_url text,                             -- MP3 externo ou do Pixabay
  views_count integer default 0,
  is_published boolean default true,          -- Corta o link no ar se virar false
  is_mural_active boolean default true,       -- Bloqueador Anti-Spam de mural
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- 5. TABELA DO MURAL DE RECADOS (ATUALIZADA PARA O SAAS)
create table mural_messages (
  id uuid default gen_random_uuid() primary key,
  invitation_id uuid references invitations(id) on delete cascade not null,
  guest_name text not null,
  message text not null,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 6. TABELA DE TRANSAÇÕES FINANCEIRAS (MERCADO PAGO)
create table finance_logs (
  id uuid default gen_random_uuid() primary key,
  gateway_transaction_id text unique,
  profile_id uuid references profiles(id),
  plan_id uuid references plans(id),
  amount numeric(10, 2) not null,
  payment_method text not null,               -- PIX, Cartão
  status text default 'pending' check (status in ('pending', 'approved', 'rejected', 'refunded')),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- 7. TABELA ESTÚDIO VIP (CONCIERGE DE LUXO)
create table vip_briefings (
  id uuid default gen_random_uuid() primary key,
  client_id uuid references profiles(id),
  event_type text not null,
  budget_estimation numeric(10, 2),
  details text,
  status text default 'analysis' check (status in ('analysis', 'negotiation', 'coding', 'delivered')),
  custom_code_injected text,                  -- O JS/CSS puro feito pelos Devs
  custom_url_bypass text,                     -- URL alternativa para redirecionamento
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- =========================================================================
-- INDEXAÇÃO DE ALTA PERFORMANCE (Evitar lentidão com MILHARES de eventos)
create index idx_invitations_slug on invitations (slug);
create index idx_mural_by_invitation on mural_messages (invitation_id);
create index idx_finance_by_status on finance_logs (status);
create index idx_profiles_role on profiles (role);

-- =========================================================================
-- CONFIGURAÇÃO INICIAL (SEEDS PARA TESTAR NO LOCALHOST O PAINEL B2B)
insert into plans (name, price, plan_type, max_invites, has_white_label)
values 
('Básico Limitado', 49.90, 'b2c_single', 1, false),
('High Elite VIP', 99.90, 'b2c_single', 1, false),
('Agência Franquia Ouro', 349.90, 'b2b_subscription', 99999, true);

insert into themes (name, category, css_variables)
values
('Patrulha Canina', 'Infantil', '{"primary": "#1E40AF", "secondary": "#EF4444", "bg_particle": "paw_print"}'),
('Luxo Moderno (Gatsby)', '15 Anos', '{"primary": "#F59E0B", "secondary": "#111827", "bg_particle": "gold_dust"}');
