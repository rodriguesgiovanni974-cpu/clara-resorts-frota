// ============================================================
//  APP.JS — Utilitários compartilhados
// ============================================================

// Auth guard — redireciona para login se não autenticado
async function requireAuth() {
  const { data: { session } } = await sb.auth.getSession();
  if (!session) { window.location.href = 'index.html'; return null; }
  return session;
}

// Busca o perfil do usuário logado
async function getProfile(userId) {
  const { data } = await sb.from('profiles').select('*').eq('id', userId).single();
  return data;
}

// Renderiza o header com nome/unidade do usuário
function renderUserHeader(profile) {
  const el = document.getElementById('user-name');
  const unEl = document.getElementById('user-unidade');
  if (el) el.textContent = profile?.nome || 'Usuário';
  if (unEl) unEl.textContent = profile?.role === 'admin' ? 'Administrador' : (profile?.unidade || '');
}

// Logout
async function logout() {
  await sb.auth.signOut();
  window.location.href = 'index.html';
}

// Marca o link ativo na sidebar
function setActiveNav(page) {
  document.querySelectorAll('.nav-link').forEach(el => {
    el.classList.toggle('active', el.dataset.page === page);
  });
}

// Formata moeda
function fmtMoeda(val) {
  return (val || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

// Formata data DD/MM/YYYY
function fmtData(str) {
  if (!str) return '—';
  const d = new Date(str + 'T00:00:00');
  return d.toLocaleDateString('pt-BR');
}

// Badge de status do serviço
function badgeServico(status) {
  const map = {
    'finalizado':   ['badge-green',  'Finalizado'],
    'em andamento': ['badge-amber',  'Em Andamento'],
    'agd veículo':  ['badge-red',    'Agd. Veículo'],
  };
  const [cls, label] = map[status] || ['badge-gray', status];
  return `<span class="badge ${cls}">${label}</span>`;
}

// Badge de aprovação
function badgeAprovacao(status) {
  const map = {
    'aprovado':          ['badge-blue',    'Aprovado'],
    'agd aprovação':     ['badge-orange',  'Agd. Aprovação'],
    'enviado s/ aprov.': ['badge-purple',  'Enviado s/ Aprov.'],
  };
  const [cls, label] = map[status] || ['badge-gray', status];
  return `<span class="badge ${cls}">${label}</span>`;
}

// Badge de unidade
function badgeUnidade(u) {
  const cls = u === 'Ibiúna' ? 'u-ibiuna' : u === 'Dourado' ? 'u-dourado' : 'u-arte';
  return `<span class="unidade-tag ${cls}">${u}</span>`;
}

// Filtro de unidade para queries (admin vê tudo, gestor só a sua)
function unidadeFilter(query, profile) {
  if (profile?.role !== 'admin' && profile?.unidade) {
    return query.eq('unidade', profile.unidade);
  }
  return query;
}

// Toast notification
function toast(msg, type = 'success') {
  const t = document.createElement('div');
  t.className = `toast toast-${type}`;
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => t.classList.add('show'), 10);
  setTimeout(() => { t.classList.remove('show'); setTimeout(() => t.remove(), 300); }, 3000);
}

// Export para CSV
function exportCSV(data, filename) {
  if (!data.length) return;
  const cols = Object.keys(data[0]);
  const rows = [cols.join(';')];
  data.forEach(r => {
    rows.push(cols.map(c => {
      const v = r[c] ?? '';
      const s = String(v).replace(/"/g, '""');
      return s.includes(';') || s.includes('\n') ? `"${s}"` : s;
    }).join(';'));
  });
  const blob = new Blob(['\uFEFF' + rows.join('\n')], { type: 'text/csv;charset=utf-8;' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = filename;
  a.click();
}
