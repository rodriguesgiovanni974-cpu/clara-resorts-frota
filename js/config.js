// ============================================================
//  CONFIGURE SUAS CREDENCIAIS SUPABASE AQUI
//  Acesse: https://supabase.com → Seu projeto → Settings → API
// ============================================================
const SUPABASE_URL = 'https://qvpsbbqpxeaspmxeoclq.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_Ep4IeIx0dbU7pWdGAE7o4g_x_LR9qQm';

const { createClient } = supabase;
const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Unidades disponíveis
const UNIDADES = ['Ibiúna', 'Dourado', 'Arte'];
const TIPOS = ['Mecânica', 'Elétrica', 'Funilaria', 'Pneu', 'Limpeza', 'Borracharia', 'Outros'];
const STATUS_SERVICO = ['agd veículo', 'em andamento', 'finalizado'];
const STATUS_APROVACAO = ['agd aprovação', 'aprovado', 'enviado s/ aprov.'];
