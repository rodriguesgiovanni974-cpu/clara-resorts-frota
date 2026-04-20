-- ============================================================
--  CLARA RESORTS — SISTEMA DE MANUTENÇÃO DE FROTA
--  Execute este SQL no Supabase SQL Editor
--  Acesse: https://supabase.com → Seu projeto → SQL Editor
-- ============================================================

-- 1. TABELA DE PERFIS (estende auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  nome        TEXT NOT NULL,
  email       TEXT,
  role        TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('admin', 'gestor', 'viewer')),
  unidade     TEXT CHECK (unidade IN ('Ibiúna', 'Dourado', 'Arte')),
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TABELA DE MANUTENÇÃO
CREATE TABLE IF NOT EXISTS manutencao (
  id                  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  veiculo             TEXT NOT NULL,
  placa               TEXT,
  marca               TEXT,
  unidade             TEXT NOT NULL CHECK (unidade IN ('Ibiúna', 'Dourado', 'Arte')),
  data_solicitacao    DATE NOT NULL,
  km                  TEXT,
  tipo                TEXT NOT NULL,
  descricao           TEXT,
  status_veiculo      TEXT DEFAULT 'em operação',
  data_ocorrencia     DATE,
  status_aprovacao    TEXT DEFAULT 'agd aprovação',
  data_aprovacao      DATE,
  status_orcamento    TEXT DEFAULT 'orçamento pendente',
  custo               NUMERIC(10,2) DEFAULT 0,
  status_servico      TEXT DEFAULT 'agd veículo' CHECK (status_servico IN ('agd veículo', 'em andamento', 'finalizado')),
  data_retorno        DATE,
  prestador           TEXT,
  nota_fiscal         TEXT,
  created_by          UUID REFERENCES auth.users(id),
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TRIGGER para updated_at automático
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_updated_at ON manutencao;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON manutencao
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 4. TRIGGER para criar profile automaticamente ao criar usuário
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, nome, email)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'nome', split_part(NEW.email, '@', 1)), NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 5. ROW LEVEL SECURITY
ALTER TABLE profiles    ENABLE ROW LEVEL SECURITY;
ALTER TABLE manutencao  ENABLE ROW LEVEL SECURITY;

-- PROFILES: cada um vê o próprio, admin vê todos
DROP POLICY IF EXISTS "profiles_self_select" ON profiles;
CREATE POLICY "profiles_self_select" ON profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_admin_all" ON profiles;
CREATE POLICY "profiles_admin_all" ON profiles
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "profiles_self_update" ON profiles;
CREATE POLICY "profiles_self_update" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- MANUTENÇÃO: admin vê tudo, gestor vê sua unidade
DROP POLICY IF EXISTS "manutencao_admin" ON manutencao;
CREATE POLICY "manutencao_admin" ON manutencao
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "manutencao_gestor_select" ON manutencao;
CREATE POLICY "manutencao_gestor_select" ON manutencao
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (unidade = manutencao.unidade OR role = 'admin'))
  );

DROP POLICY IF EXISTS "manutencao_gestor_insert" ON manutencao;
CREATE POLICY "manutencao_gestor_insert" ON manutencao
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (unidade = manutencao.unidade OR role = 'admin'))
  );

DROP POLICY IF EXISTS "manutencao_gestor_update" ON manutencao;
CREATE POLICY "manutencao_gestor_update" ON manutencao
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND (unidade = manutencao.unidade OR role = 'admin'))
  );

DROP POLICY IF EXISTS "manutencao_gestor_delete" ON manutencao;
CREATE POLICY "manutencao_gestor_delete" ON manutencao
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 6. ÍNDICES para performance
CREATE INDEX IF NOT EXISTS idx_manutencao_unidade        ON manutencao(unidade);
CREATE INDEX IF NOT EXISTS idx_manutencao_status_servico ON manutencao(status_servico);
CREATE INDEX IF NOT EXISTS idx_manutencao_data_solic     ON manutencao(data_solicitacao);
CREATE INDEX IF NOT EXISTS idx_manutencao_tipo           ON manutencao(tipo);

-- ============================================================
--  APÓS EXECUTAR ESTE SQL:
--  1. Crie seu primeiro usuário em Authentication → Users
--  2. Atualize o role para 'admin' na tabela profiles:
--     UPDATE profiles SET role = 'admin', nome = 'Seu Nome' WHERE email = 'seu@email.com';
-- ============================================================
