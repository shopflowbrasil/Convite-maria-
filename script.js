/* =====================================================
   SCRIPT PRINCIPAL — CONVITE 15 ANOS DA MARIA
===================================================== */
console.log('🔵 script.js carregado');

let supabaseClient = null;

/* ==================== SUPABASE ==================== */
function initSupabase() {
    console.log('🔵 Iniciando Supabase...');

    if (typeof window.CONFIG === 'undefined') {
        console.error('❌ window.CONFIG indefinido (config.js não carregou)');
        return false;
    }
    if (typeof window.supabase === 'undefined') {
        console.error('❌ Biblioteca Supabase não carregada');
        return false;
    }

    try {
        supabaseClient = window.supabase.createClient(
            window.CONFIG.SUPABASE_URL,
            window.CONFIG.SUPABASE_ANON_KEY
        );
        console.log('✅ Supabase OK! URL:', window.CONFIG.SUPABASE_URL);
        return true;
    } catch (e) {
        console.error('❌ Erro ao criar cliente:', e);
        return false;
    }
}

initSupabase();

/* ==================== QUANDO O DOM CARREGAR ==================== */
document.addEventListener('DOMContentLoaded', function () {
    console.log('🔵 DOM pronto');

    /* ==================== MÚSICA ==================== */
    const music = document.getElementById('bgMusic');
    const musicBtn = document.getElementById('musicBtn');
    const iconOn = document.querySelector('.music-on');
    const iconOff = document.querySelector('.music-off');

    let musicaTocando = false;

    function tentarTocarMusica() {
        if (!music) return;
        music.volume = 0.5;
        const playPromise = music.play();
        if (playPromise !== undefined) {
            playPromise
                .then(function () {
                    musicaTocando = true;
                    if (musicBtn) musicBtn.classList.add('playing');
                    if (iconOn) iconOn.style.display = 'block';
                    if (iconOff) iconOff.style.display = 'none';
                    console.log('🎵 Música tocando');
                })
                .catch(function (err) {
                    console.log('🔇 Autoplay bloqueado. Clique no botão de música.');
                    musicaTocando = false;
                    if (musicBtn) musicBtn.classList.remove('playing');
                    if (iconOn) iconOn.style.display = 'none';
                    if (iconOff) iconOff.style.display = 'block';
                });
        }
    }

    /* Tenta tocar automaticamente ao carregar */
    setTimeout(tentarTocarMusica, 300);

    /* Tenta tocar no primeiro clique/toque em qualquer lugar */
    function tocarNoPrimeiroToque() {
        if (musicaTocando) return;
        tentarTocarMusica();
        document.removeEventListener('click', tocarNoPrimeiroToque);
        document.removeEventListener('touchstart', tocarNoPrimeiroToque);
    }
    document.addEventListener('click', tocarNoPrimeiroToque, { once: true });
    document.addEventListener('touchstart', tocarNoPrimeiroToque, { once: true });

    /* Botão de música — liga/desliga */
    if (musicBtn) {
        musicBtn.addEventListener('click', function (e) {
            e.stopPropagation();
            if (!music) return;

            if (musicaTocando) {
                music.pause();
                musicaTocando = false;
                musicBtn.classList.remove('playing');
                if (iconOn) iconOn.style.display = 'none';
                if (iconOff) iconOff.style.display = 'block';
                console.log('⏸️ Música pausada');
            } else {
                music.volume = 0.5;
                music.play().then(function () {
                    musicaTocando = true;
                    musicBtn.classList.add('playing');
                    if (iconOn) iconOn.style.display = 'block';
                    if (iconOff) iconOff.style.display = 'none';
                    console.log('▶️ Música tocando');
                }).catch(function (err) {
                    console.error('❌ Erro ao tocar:', err);
                });
            }
        });
    }

    /* ==================== MODAL CONFIRMAR ==================== */
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

    function abrirModal() {
        if (!modal) return;
        modal.classList.add('open');
        document.body.style.overflow = 'hidden';
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
    }
    if (btnClose) btnClose.addEventListener('click', fecharModal);
    if (modal) {
        modal.addEventListener('click', function (e) {
            if (e.target === modal) fecharModal();
        });
    }
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') fecharModal();
    });

    /* ==================== MÁSCARA TELEFONE ==================== */
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

    /* ==================== ENVIO ==================== */
    if (form) {
        form.addEventListener('submit', async function (e) {
            e.preventDefault();
            e.stopPropagation();

            const nome = inpNome ? inpNome.value.trim() : '';
            const telefone = inpTel ? inpTel.value.trim() : '';
            const acompanhantes = inpAcomp ? (parseInt(inpAcomp.value) || 0) : 0;
            const mensagem = inpMsg ? inpMsg.value.trim() : '';

            console.log('📤 Enviando:', { nome, telefone, acompanhantes, mensagem });

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
            if (!supabaseClient) {
                mostrarMsg('Erro: Supabase não configurado. Verifique config.js', 'error');
                console.error('❌ supabaseClient é null');
                return;
            }

            if (btnSubmit) {
                btnSubmit.disabled = true;
                btnSubmit.textContent = 'Enviando...';
            }
            mostrarMsg('Enviando confirmação...', 'loading');

            try {
                console.log('📡 Chamando RPC confirmar_presenca...');
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
                else m += 'Verifique o console (F12).';
                mostrarMsg(m, 'error');
            } finally {
                if (btnSubmit) {
                    btnSubmit.disabled = false;
                    btnSubmit.textContent = 'Enviar Confirmação';
                }
            }
        });
    }
});
