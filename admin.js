/* =====================================================
   PAINEL ADMIN — À PROVA DE FALHAS
===================================================== */
console.log('🔵 admin.js carregado');

let supabaseClient = null;
let allConfirmacoes = [];
let adminPwd = '';

function initSupabase() {
    if (!window.CONFIG) {
        console.error('❌ config.js NÃO carregado!');
        return false;
    }
    if (!window.supabase) {
        console.error('❌ Biblioteca Supabase NÃO carregada!');
        return false;
    }
    try {
        supabaseClient = window.supabase.createClient(
            window.CONFIG.SUPABASE_URL,
            window.CONFIG.SUPABASE_ANON_KEY
        );
        console.log('✅ Supabase admin OK!');
        return true;
    } catch (e) {
        console.error('❌ Erro Supabase:', e);
        return false;
    }
}

initSupabase();

document.addEventListener('DOMContentLoaded', function () {
    console.log('🔵 DOM admin pronto');

    const loginScreen = document.getElementById('loginScreen');
    const dashboard = document.getElementById('dashboard');
    const inpPwd = document.getElementById('adminPassword');
    const btnLogin = document.getElementById('btnLogin');
    const loginMsg = document.getElementById('loginMessage');
    const btnLogout = document.getElementById('btnLogout');
    const btnRefresh = document.getElementById('btnRefresh');
    const btnCSV = document.getElementById('btnExportCSV');
    const filtSearch = document.getElementById('filterSearch');
    const filtStatus = document.getElementById('filterStatus');
    const statsGrid = document.getElementById('statsGrid');
    const tbody = document.getElementById('adminTableBody');
    const emptyState = document.getElementById('emptyState');

    console.log('🔵 Login screen:', !!loginScreen, '| Dashboard:', !!dashboard);

    /* ==================== LOGIN ==================== */
    async function fazerLogin() {
        if (!inpPwd || !btnLogin) return;

        const pwd = inpPwd.value.trim();
        if (!pwd) {
            loginMsg.textContent = 'Digite a senha.';
            loginMsg.className = 'form-message error';
            return;
        }
        if (!supabaseClient) {
            loginMsg.textContent = 'Erro: Supabase não configurado. Edite config.js';
            loginMsg.className = 'form-message error';
            console.error('❌ supabaseClient é null');
            return;
        }

        btnLogin.disabled = true;
        btnLogin.textContent = 'Verificando...';
        loginMsg.textContent = '';
        loginMsg.className = 'form-message';

        try {
            console.log('📡 Testando senha:', pwd);
            const { data, error } = await supabaseClient.rpc('admin_listar_confirmacoes', {
                p_admin_token: pwd
            });

            console.log('📥 Resposta:', { data, error });

            if (error) throw error;

            if (data && data.success) {
                adminPwd = pwd;
                sessionStorage.setItem('admin_pwd', pwd);
                loginScreen.style.display = 'none';
                dashboard.style.display = 'block';
                allConfirmacoes = data.data || [];
                console.log('✅ Login OK! Registros:', allConfirmacoes.length);
                renderTudo();
            } else {
                loginMsg.textContent = '❌ Senha incorreta. Tente novamente.';
                loginMsg.className = 'form-message error';
            }
        } catch (err) {
            console.error('❌ Erro login:', err);
            let m = 'Erro: ';
            if (err && err.message) m += err.message;
            else if (err && err.error_description) m += err.error_description;
            else m += 'Verifique o console (F12).';
            loginMsg.textContent = m;
            loginMsg.className = 'form-message error';
        } finally {
            btnLogin.disabled = false;
            btnLogin.textContent = 'Entrar';
        }
    }

    if (btnLogin) {
        btnLogin.addEventListener('click', fazerLogin);
    }
    if (inpPwd) {
        inpPwd.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') fazerLogin();
        });
        setTimeout(function () { inpPwd.focus(); }, 300);
    }

    /* ==================== LOGOUT ==================== */
    if (btnLogout) {
        btnLogout.addEventListener('click', function () {
            sessionStorage.removeItem('admin_pwd');
            location.reload();
        });
    }

    /* ==================== AUTO-LOGIN ==================== */
    const salvo = sessionStorage.getItem('admin_pwd');
    if (salvo && inpPwd) {
        inpPwd.value = salvo;
        fazerLogin();
    }

    /* ==================== CARREGAR DADOS ==================== */
    async function carregarDados() {
        const pwd = adminPwd || sessionStorage.getItem('admin_pwd');
        if (!pwd) return;
        try {
            const { data, error } = await supabaseClient.rpc('admin_listar_confirmacoes', {
                p_admin_token: pwd
            });
            if (error) throw error;
            if (data && data.success) {
                allConfirmacoes = data.data || [];
                renderTudo();
            }
        } catch (err) {
            console.error('❌ Erro ao carregar:', err);
        }
    }

    if (btnRefresh) {
        btnRefresh.addEventListener('click', function () {
            btnRefresh.disabled = true;
            carregarDados().finally(function () {
                btnRefresh.disabled = false;
            });
        });
    }

    /* ==================== STATS ==================== */
    function renderStats() {
        if (!statsGrid) return;
        const conf = allConfirmacoes.filter(c => c.status === 'confirmado');
        const pend = allConfirmacoes.filter(c => c.status === 'pendente');
        const rec = allConfirmacoes.filter(c => c.status === 'recusado');
        const acomp = conf.reduce((s, c) => s + (c.acompanhantes || 0), 0);
        const total = conf.length + acomp;

        statsGrid.innerHTML =
            '<div class="stat-card confirmed">' +
                '<div class="stat-icon"><svg viewBox="0 0 24 24"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></div>' +
                '<span class="stat-value">' + conf.length + '</span>' +
                '<span class="stat-label">Confirmados</span>' +
            '</div>' +
            '<div class="stat-card gold">' +
                '<div class="stat-icon"><svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></div>' +
                '<span class="stat-value">' + total + '</span>' +
                '<span class="stat-label">Total de Pessoas</span>' +
            '</div>' +
            '<div class="stat-card">' +
                '<div class="stat-icon"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="M12 8v8M8 12h8"/></svg></div>' +
                '<span class="stat-value">' + acomp + '</span>' +
                '<span class="stat-label">Acompanhantes</span>' +
            '</div>' +
            '<div class="stat-card pending">' +
                '<div class="stat-icon"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg></div>' +
                '<span class="stat-value">' + pend.length + '</span>' +
                '<span class="stat-label">Pendentes</span>' +
            '</div>' +
            '<div class="stat-card refused">' +
                '<div class="stat-icon"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="M15 9l-6 6M9 9l6 6"/></svg></div>' +
                '<span class="stat-value">' + rec.length + '</span>' +
                '<span class="stat-label">Recusados</span>' +
            '</div>' +
            '<div class="stat-card">' +
                '<div class="stat-icon"><svg viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/></svg></div>' +
                '<span class="stat-value">' + allConfirmacoes.length + '</span>' +
                '<span class="stat-label">Total Registros</span>' +
            '</div>';
    }

    /* ==================== HELPERS ==================== */
    function formatarData(iso) {
        if (!iso) return '—';
        const d = new Date(iso);
        return d.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: '2-digit' })
            + ' ' + d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
    }

    function esc(text) {
        if (!text) return '';
        return String(text)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    function iniciais(nome) {
        if (!nome) return '?';
        const p = nome.trim().split(/\s+/);
        if (p.length === 1) return p[0].charAt(0).toUpperCase();
        return (p[0].charAt(0) + p[p.length - 1].charAt(0)).toUpperCase();
    }

    /* ==================== TABELA ==================== */
    function renderTabela() {
        if (!tbody) return;
        const busca = filtSearch ? filtSearch.value.toLowerCase().trim() : '';
        const status = filtStatus ? filtStatus.value : '';

        let filtrados = allConfirmacoes.filter(function (c) {
            if (status && c.status !== status) return false;
            if (busca) {
                const ok = (c.nome || '').toLowerCase().indexOf(busca) !== -1 ||
                           (c.telefone || '').toLowerCase().indexOf(busca) !== -1;
                if (!ok) return false;
            }
            return true;
        });

        if (filtrados.length === 0) {
            tbody.innerHTML = '';
            if (emptyState) emptyState.style.display = 'block';
            return;
        }
        if (emptyState) emptyState.style.display = 'none';

        tbody.innerHTML = filtrados.map(function (c) {
            return '<tr>' +
                '<td class="cell-name">' +
                    '<div class="avatar">' + iniciais(c.nome) + '</div>' +
                    '<span>' + esc(c.nome) + '</span>' +
                '</td>' +
                '<td class="cell-phone">' + esc(c.telefone) + '</td>' +
                '<td>' + (c.acompanhantes || 0) + '</td>' +
                '<td class="cell-message" title="' + esc(c.mensagem || '') + '">' + esc(c.mensagem || '—') + '</td>' +
                '<td>' + formatarData(c.created_at) + '</td>' +
                '<td><span class="badge ' + c.status + '">' + c.status + '</span></td>' +
                '<td>' +
                    '<div class="row-actions">' +
                        '<button class="icon-btn" data-action="toggle" data-id="' + c.id + '" title="Alternar status">' +
                            '<svg viewBox="0 0 24 24"><path d="M23 4v6h-6M1 20v-6h6"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>' +
                        '</button>' +
                        '<button class="icon-btn danger" data-action="delete" data-id="' + c.id + '" title="Excluir">' +
                            '<svg viewBox="0 0 24 24"><path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/></svg>' +
                        '</button>' +
                    '</div>' +
                '</td>' +
            '</tr>';
        }).join('');

        tbody.querySelectorAll('[data-action]').forEach(function (btn) {
            btn.addEventListener('click', async function () {
                const action = btn.getAttribute('data-action');
                const id = btn.getAttribute('data-id');
                if (action === 'toggle') await alternarStatus(id);
                else if (action === 'delete') {
                    if (confirm('Excluir este registro?')) await excluir(id);
                }
            });
        });
    }

    /* ==================== ALTERAR STATUS ==================== */
    async function alternarStatus(id) {
        const item = allConfirmacoes.find(function (c) { return String(c.id) === String(id); });
        if (!item) return;
        const proximo = item.status === 'confirmado' ? 'pendente'
                      : item.status === 'pendente' ? 'recusado'
                      : 'confirmado';
        const pwd = adminPwd || sessionStorage.getItem('admin_pwd');
        try {
            const { data, error } = await supabaseClient.rpc('admin_atualizar_status', {
                p_admin_token: pwd,
                p_id: parseInt(id),
                p_status: proximo
            });
            if (error) throw error;
            if (data && data.success) {
                item.status = proximo;
                renderTudo();
            } else {
                alert((data && data.error) || 'Erro ao atualizar.');
            }
        } catch (err) {
            console.error(err);
            alert('Erro ao atualizar status.');
        }
    }

    /* ==================== EXCLUIR ==================== */
    async function excluir(id) {
        const pwd = adminPwd || sessionStorage.getItem('admin_pwd');
        try {
            const { data, error } = await supabaseClient.rpc('admin_excluir_confirmacao', {
                p_admin_token: pwd,
                p_id: parseInt(id)
            });
            if (error) throw error;
            if (data && data.success) {
                allConfirmacoes = allConfirmacoes.filter(function (c) {
                    return String(c.id) !== String(id);
                });
                renderTudo();
            } else {
                alert((data && data.error) || 'Erro ao excluir.');
            }
        } catch (err) {
            console.error(err);
            alert('Erro ao excluir.');
        }
    }

    /* ==================== RENDER TUDO ==================== */
    function renderTudo() {
        renderStats();
        renderTabela();
    }

    if (filtSearch) filtSearch.addEventListener('input', renderTabela);
    if (filtStatus) filtStatus.addEventListener('change', renderTabela);

    /* ==================== EXPORTAR CSV ==================== */
    if (btnCSV) {
        btnCSV.addEventListener('click', function () {
            if (allConfirmacoes.length === 0) {
                alert('Nenhum dado para exportar.');
                return;
            }
            const headers = ['ID', 'Nome', 'Telefone', 'Acompanhantes', 'Mensagem', 'Status', 'Data'];
            const rows = allConfirmacoes.map(function (c) {
                return [
                    c.id,
                    c.nome || '',
                    c.telefone || '',
                    c.acompanhantes || 0,
                    (c.mensagem || '').replace(/"/g, '""'),
                    c.status || '',
                    c.created_at || ''
                ];
            });
            const csv = [headers].concat(rows).map(function (row) {
                return row.map(function (cell) { return '"' + cell + '"'; }).join(',');
            }).join('\n');
            const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'confirmacoes_maria_' + new Date().toISOString().slice(0, 10) + '.csv';
            a.click();
            URL.revokeObjectURL(url);
        });
    }
});
