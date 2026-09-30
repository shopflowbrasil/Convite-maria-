#!/bin/bash
# =====================================================================
# PATCH — restaura o toque na tela para iniciar o mergulho
# =====================================================================

FILE="index.html"

if [ ! -f "$FILE" ]; then
  echo "ERRO: $FILE não encontrado."
  exit 1
fi

cp "$FILE" "${FILE}.bak3"
echo "Backup criado: ${FILE}.bak3"

python3 - << 'PYEOF'
import re

with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

# ---------------------------------------------------------------------
# 1) Remove qualquer bloco antigo de "MERGULHO" e reinsere íntegro
# ---------------------------------------------------------------------
novo_bloco_mergulho = r'''/* =========================================================
   MERGULHO
========================================================= */
let diving = false;
let finished = false;
let diveStart = 0;
let diveAnimation = null;

function clamp(v, min, max){ return Math.max(min, Math.min(max, v)); }

function startDive(){
    if(diving || finished) return;
    diving = true;
    diveStart = performance.now();
    intro.classList.add("diving");
    sceneCanvas.classList.add("active");
    diveAnimation = requestAnimationFrame(diveLoop);
}

// listeners de segurança (pointer + touch + click)
intro.addEventListener("pointerdown", startDive, { passive: true });
intro.addEventListener("touchstart",  startDive, { passive: true });
intro.addEventListener("click",       startDive, { passive: true });

function updateDive(now){
    const elapsed = now - diveStart;
    const duration = 6200;
    let t = clamp(elapsed / duration, 0, 1);

    const accel = Math.pow(t, 1.6);
    const camY = 6 - 124 * accel;
    const camZ = 12 - 9 * t;
    const camX = Math.sin(t * Math.PI * 3.2) * .7 * t;

    camera.position.set(camX, camY, camZ);
    const lookY = camY - 8 - 34 * t;
    camera.lookAt(0, lookY, -25);

    surfaceMaterial.uniforms.uTime.value = now * .001;

    const depth = clamp((-camera.position.y) / 120, 0, 1);
    const fogTop = new THREE.Color(0x0d6a95);
    const fogBot = new THREE.Color(0x021f38);
    scene.fog.color.copy(fogTop.clone().lerp(fogBot, depth));
    scene.fog.density = .004 + depth * .004;

    for(let i=0; i<rays.length; i++){
        rays[i].material.uniforms.uTime.value = now * .001;
        rays[i].material.uniforms.uOpacity.value =
            (0.30 + i * 0.01) * (1 - depth * 0.55);
    }

    if(t > 0.04){
        trailBubbleTimer += 1;
        if(trailBubbleTimer > 1){
            trailBubbleTimer = 0;
            spawnTrailBubble();
            spawnTrailBubble();
        }
    }

    if(t >= 1){
        diving = false;
        finished = true;
        if(diveAnimation){ cancelAnimationFrame(diveAnimation); diveAnimation = null; }
        sceneCanvas.classList.remove("active");
        intro.classList.add("hide");
        setTimeout(()=>{ invitation.classList.add("open"); }, 400);
    }
}

let diveLastTime = performance.now();

function diveLoop(now){
    if(!diving){ diveAnimation = null; return; }

    const dt = Math.min((now - diveLastTime) / 1000, 0.05);
    diveLastTime = now;

    updateDive(now);

    particles.rotation.y = now * .000009;
    particles.position.y = Math.sin(now * .00015) * .18;

    // bolhas de ambiente
    for(let i=0; i<ambientBubbles.length; i++){
        const bubble = ambientBubbles[i];
        const ud = bubble.userData;
        bubble.position.y += ud.speed;
        bubble.position.x += Math.sin(now * .0015 + ud.wobble) * .004;
        bubble.position.z += Math.cos(now * .0012 + ud.wobble) * .003;
        const sizePulse = 1.0 + Math.sin(now * .002 + ud.wobble) * 0.08;
        bubble.scale.setScalar(ud.baseSize * sizePulse);
        if(bubble.position.y > 8){
            bubble.position.y = -130 - Math.random() * 40;
            bubble.position.x = (Math.random() - .5) * 55;
            bubble.position.z = -5 + (Math.random() - .5) * 45;
        }
    }

    // bolhas da trilha
    for(let i=0; i<trailBubbles.length; i++){
        const b = trailBubbles[i];
        if(!b.visible) continue;
        const ud = b.userData;
        b.position.y += ud.velY;
        b.position.x += ud.velX;
        b.position.z += ud.velZ;
        ud.velY += 0.002;
        ud.life -= 0.008;
        const growFactor = 1.0 + (1.0 - ud.life) * 0.35;
        b.scale.setScalar(ud.baseScale * growFactor);
        b.material.uniforms.uOpacity.value = Math.max(0, ud.life);
        if(ud.life <= 0) b.visible = false;
    }

    /* =====================================================
       CONCHAS E ESTRELAS CAINDO
    ===================================================== */
    for(let i = 0; i < fallingShells.length; i++){
        const shell = fallingShells[i];
        const ud = shell.userData;

        shell.position.y += ud.velocityY * dt;

        shell.position.x = ud.baseX + Math.sin(now * ud.swayFreq + ud.swayPhase) * ud.swayAmp;
        shell.position.z = ud.baseZ + Math.cos(now * ud.swayFreq * 0.7 + ud.swayPhase) * ud.swayAmp * 0.6;

        shell.rotation.x += ud.rotSpeedX * dt;
        shell.rotation.y += ud.rotSpeedY * dt;
        shell.rotation.z += ud.rotSpeedZ * dt;

        if(shell.position.y < camera.position.y - 40){
            shell.position.y = camera.position.y + 40 + Math.random() * 40;
            shell.position.x = (Math.random() - 0.5) * 120;
            shell.position.z = -15 - Math.random() * 60;
            ud.baseX = shell.position.x;
            ud.baseZ = shell.position.z;
            ud.velocityY = -(8 + Math.random() * 10);
            ud.swayPhase = Math.random() * Math.PI * 2;
            if(shell.material && shell.material.color){
                const pal = ud.isStar ? starPalette : shellPalette;
                shell.material.color.setHex(pal[Math.floor(Math.random() * pal.length)]);
            }
        }
    }

    for(let i=0; i<rays.length; i++){
        rays[i].rotation.z = ((i - 5.5) * 0.035) +
            Math.sin(now * .0003 + i * 1.7) * 0.025;
    }

    renderer.render(scene, camera);
    diveAnimation = requestAnimationFrame(diveLoop);
}

window.addEventListener("resize", ()=>{
    const width = window.innerWidth;
    const height = window.innerHeight;
    renderer.setSize(width, height, false);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.25));
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
}, { passive: true });
'''

# Localiza o bloco MERGULHO inteiro (do comentário até antes do </script> ou do final conhecido)
padrao_mergulho = re.compile(
    r"/\* =+\s*\n\s*MERGULHO\s*\n\s*=+\s*\*/.*?(?=window\.addEventListener\(\"resize\")",
    re.DOTALL
)

if padrao_mergulho.search(html):
    html = padrao_mergulho.sub(novo_bloco_mergulho + "\n", html, count=1)
else:
    # fallback: apaga tudo de MERGULHO até o final do script e reinsere
    idx = html.find("/* =========================================================\n   MERGULHO")
    if idx == -1:
        print("ERRO: bloco MERGULHO não encontrado.")
        raise SystemExit(1)
    fim = html.rfind("</script>")
    html = html[:idx] + novo_bloco_mergulho + "\n" + html[fim:]

# ---------------------------------------------------------------------
# 2) Garante que o canvas #scene não bloqueie o toque no intro
# ---------------------------------------------------------------------
# (o #scene fica com pointer-events:none até ativar)
with open("index.html", "w", encoding="utf-8") as f:
    f.write(html)

print("PATCH de toque aplicado com sucesso!")
PYEOF

echo ""
echo "Pronto! Abra o index.html e toque em qualquer lugar da tela."
echo "Se ainda não funcionar, abra o Console (F12) e me diga se aparece algum erro vermelho."
