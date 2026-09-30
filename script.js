/* =====================================================
   SCRIPT PRINCIPAL COM DIAGNÓSTICO VISÍVEL
===================================================== */
console.log('🔵 script.js carregado');

let supabaseClient = null;
let errosConfig = [];

/* ---------- INICIALIZAÇÃO COM DIAGNÓSTICO ---------- */
function initSupabase() {
    console.log('🔵 Iniciando Supabase...');

    if (typeof window.CONFIG === 'undefined') {
        errosConfig.push('config.js não foi carregado ou não definiu window.CONFIG');
        console.error('❌ window.CONFIG undefined');
        return false;
    }

    if (typeof window.supabase === 'undefined') {
        errosConfig.push('Biblioteca Supabase (@supabase/supabase-js) não carregou');
        console.error('❌ window.supabase undefined');
        return false;
    }

    if (!window.CONFIG.SUPABASE_URL || window.CONFIG.SUPABASE_URL.indexOf('supabase.co') === -1) {
        errosConfig.push('SUPABASE_URL inválida: ' + window.CONFIG.SUPABASE_URL);
        console.error('❌ URL inválida:', window.CONFIG.SUPABASE_URL);
        return false;
    }

    if (!window.CONFIG.SUPABASE_ANON_KEY || window.CONFIG.SUPABASE_ANON_KEY.indexOf('eyJ') !== 0) {
        errosConfig.push('SUPABASE_ANON_KEY inválida (deve começar com "eyJ")');
        console.error('❌ KEY inválida (não começa com eyJ)');
        return false;
    }

    try {
        supabaseClient = window.supabase.createClient(
            window.CONFIG.SUPABASE_URL,
            window.CONFIG.SUPABASE_ANON_KEY
        );
        console.log('✅ Supabase criado com sucesso!');
        return true;
    } catch (e) {
        errosConfig.push('Erro ao criar cliente: ' + e.message);
        console.error('❌ Erro createClient:', e);
        return false;
    }
}

initSupabase();

/* ---------- QUANDO O DOM CARREGAR ---------- */
document.addEventListener('DOMContentLoaded', function () {
    console.log('🔵 DOM pronto');

    const modal = document.getElementById('confirmModal');
    const btnOpen = document.getElementById('btnOpenConfirm');
    const btnClose = document.getElementById('btnCloseConfirm');
    const form = document.getElementById('confirmForm');
    const msg = document.getElementById('formMessage');
    const btnSubmit = document.getElementById('btnSubmitConfirm');
    const inpNome = document.getElementById('inputNome');
    const inpTel = document.getElementById('inputTelefone');
    const inpAcomp = document.getElementById('inputAcompanhantes');
    const inpMsg = document.getElementById('inputMensagem');

    console.log('🔵 Modal:', !!modal, '| Botão:', !!btnOpen);

    /* ---------- ABRIR MODAL ---------- */
    function abrirModal() {
        if (!modal) {
            alert('ERRO: Modal #confirmModal não encontrado no HTML!');
            return;
        }
        modal.classList.add('open');
        document.body.style.overflow = 'hidden';
        console.log('🟢 Modal aberto');

        /* SE HOUVER ERRO DE CONFIG, MOSTRA NA HORA */
        if (errosConfig.length > 0) {
            setTimeout(function () {
                if (msg) {
                    msg.textContent = '⚠️ ' + errosConfig[0];
                    msg.className = 'form-message error';
                }
            }, 200);
        }

        setTimeout(function () { if (inpNome) inpNome.focus(); }, 400);
    }

    function fecharModal() {
        if (!modal) return;
        modal.classList.remove('open');
        document.body.style.overflow = '';
        if (msg) {
            msg.className = 'form-message';
            msg.textContent = '';
        }
    }

    if (btnOpen) {
        btnOpen.addEventListener('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            abrirModal();
        });
        console.log('✅ Botão OK');
    } else {
        console.error('❌ btnOpenConfirm NÃO ENCONTRADO!');
    }

    if (btnClose) btnClose.addEventListener('click', fecharModal);
    if (modal) modal.addEventListener('click', function (e) {
        if (e.target === modal) fecharModal();
    });
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') fecharModal();
    });

    /* ---------- MÁSCARA ---------- */
    if (inpTel) {
        inpTel.addEventListener('input', function (e) {
            let v = e.target.value.replace(/\D/g, '');
            if (v.length > 11) v = v.slice(0, 11);
            if (v.length > 10) v = v.replace(/^(\d{2})(\d{5})(\d{4}).*/, '($1) $2-$3');
            else if (v.length > 6) v = v.replace(/^(\d{2})(\d{4})(\d{0,4}).*/, '($1) $2-$3');
            else if (v.length > 2) v = v.replace(/^(\d{2})(\d{0,5}).*/, '($1) $2');
            else if (v.length > 0) v = v.replace(/^(\d{0,2}).*/, '($1');
            e.target.value = v;
        });
    }

    function mostrarMsg(texto, tipo) {
        if (!msg) return;
        msg.textContent = texto;
        msg.className = 'form-message ' + tipo;
    }

    /* ---------- ENVIO ---------- */
    if (form) {
        form.addEventListener('submit', async function (e) {
            e.preventDefault();
            e.stopPropagation();

            const nome = inpNome ? inpNome.value.trim() : '';
            const telefone = inpTel ? inpTel.value.trim() : '';
            const acompanhantes = inpAcomp ? (parseInt(inpAcomp.value) || 0) : 0;
            const mensagem = inpMsg ? inpMsg.value.trim() : '';

            console.log('📤 Enviando:', { nome, telefone, acompanhantes, mensagem });

            /* VALIDAÇÕES */
            if (nome.length < 2) {
                mostrarMsg('Por favor, digite seu nome completo.', 'error');
                if (inpNome) inpNome.focus();
                return;
            }
            if (telefone.replace(/\D/g, '').length < 10) {
                mostrarMsg('Digite um WhatsApp válido com DDD.', 'error');
                if (inpTel) inpTel.focus();
                return;
            }

            /* SE SUPABASE FALHOU, MOSTRA O ERRO EXATO */
            if (!supabaseClient) {
                let detalhe = errosConfig.length > 0 ? errosConfig[0] : 'Cliente Supabase não inicializado';
                mostrarMsg('⚠️ ' + detalhe, 'error');
                console.error('❌ Erros de config:', errosConfig);
                alert('ERRO DE CONFIGURAÇÃO:\n\n' + detalhe + '\n\nVerifique o console (F12) para mais detalhes.');
                return;
            }

            if (btnSubmit) {
                btnSubmit.disabled = true;
                btnSubmit.textContent = 'Enviando...';
            }
            mostrarMsg('Enviando confirmação...', 'loading');

            try {
                const { data, error } = await supabaseClient.rpc('confirmar_presenca', {
                    p_nome: nome,
                    p_telefone: telefone,
                    p_acompanhantes: acompanhantes,
                    p_mensagem: mensagem || null
                });

                console.log('📥 Resposta:', { data, error });

                if (error) throw error;

                if (data && data.success) {
                    mostrarMsg('✓ Presença confirmada! Obrigada! 💙', 'success');
                    form.reset();
                    setTimeout(fecharModal, 2800);
                } else {
                    mostrarMsg((data && data.error) || 'Erro ao confirmar.', 'error');
                }
            } catch (err) {
                console.error('❌ Erro:', err);
                let m = 'Erro: ';
                if (err && err.message) m += err.message;
                else if (err && err.error_description) m += err.error_description;
                else if (err && err.details) m += err.details;
                else m += 'Abra o console (F12).';
                mostrarMsg(m, 'error');
            } finally {
                if (btnSubmit) {
                    btnSubmit.disabled = false;
                    btnSubmit.textContent = 'Enviar Confirmação';
                }
            }
        });
        console.log('✅ Form OK');
    } else {
        console.error('❌ confirmForm NÃO ENCONTRADO!');
    }
});
