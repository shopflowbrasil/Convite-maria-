#!/bin/bash
# =====================================================================
# PATCH — conchas aparecem durante TODO o mergulho (início, meio e fim)
# =====================================================================

FILE="index.html"

if [ ! -f "$FILE" ]; then
  echo "ERRO: $FILE não encontrado nesta pasta."
  exit 1
fi

cp "$FILE" "${FILE}.bak_meio"
echo "Backup criado: ${FILE}.bak_meio"

python3 - << 'PYEOF'
import re

with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

# ---------------------------------------------------------------------
# 1) Muda a posição inicial das conchas: agora seguem a câmera
# ---------------------------------------------------------------------
# Substitui o bloco de criação das posições (dentro do for de SHELL_COUNT)
bloco_pos_antigo = re.compile(
    r"// CENTRALIZADAS[^\n]*\n\s*mesh\.position\.set\(\s*\(Math\.random\(\) - 0\.5\) \* 44,\s*20 - Math\.random\(\) \* 180,\s*-22 - Math\.random\(\) \* 48\s*\);",
    re.DOTALL
)

bloco_pos_novo = r'''// Centralizadas e distribuídas por TODA a profundidade do mergulho
    // (a câmera vai de y=6 até y=-118, então espalha de +20 até -160)
    mesh.position.set(
        (Math.random() - 0.5) * 44,
        20 - Math.random() * 180,
        -22 - Math.random() * 48
    );'''

if bloco_pos_antigo.search(html):
    html = bloco_pos_antigo.sub(bloco_pos_novo, html, count=1)
    print("→ Posições iniciais ajustadas.")

# ---------------------------------------------------------------------
# 2) Muda o "range" de reciclagem para ser SEMPRE relativo à câmera
#     em TODO o trajeto (não só quando cai abaixo da câmera)
# ---------------------------------------------------------------------
# Substitui todo o bloco de atualização das conchas dentro do diveLoop
padrao_anim = re.compile(
    r"(for\(let i = 0; i < fallingShells\.length; i\+\+\)\{).*?(?=\n\s*for\(let i=0; i<rays\.length)",
    re.DOTALL
)

bloco_anim_novo = r'''for(let i = 0; i < fallingShells.length; i++){
        const shell = fallingShells[i];
        const ud = shell.userData;

        // queda vertical
        shell.position.y += ud.velocityY * dt;

        // oscilação lateral
        shell.position.x = ud.baseX + Math.sin(now * ud.swayFreq + ud.swayPhase) * ud.swayAmp;
        shell.position.z = ud.baseZ + Math.cos(now * ud.swayFreq * 0.7 + ud.swayPhase) * ud.swayAmp * 0.6;

        // rotação
        shell.rotation.x += ud.rotSpeedX * dt;
        shell.rotation.y += ud.rotSpeedY * dt;
        shell.rotation.z += ud.rotSpeedZ * dt;

        // Quando a concha fica abaixo da câmera OU muito longe no eixo Z,
        // reposiciona ela ACIMA da câmera atual (relativo à posição da câmera)
        const belowCamera = shell.position.y < camera.position.y - 30;
        const tooFar      = shell.position.z > camera.position.z + 10;
        if(belowCamera || tooFar){
            // reposiciona sempre ACIMA da câmera, em um raio ao redor
            shell.position.y = camera.position.y + 25 + Math.random() * 55;
            shell.position.x = camera.position.x + (Math.random() - 0.5) * 44;
            shell.position.z = camera.position.z - 22 - Math.random() * 48;
            ud.baseX = shell.position.x;
            ud.baseZ = shell.position.z;
            ud.velocityY = -(7 + Math.random() * 11);
            ud.swayPhase = Math.random() * Math.PI * 2;

            // regenera textura com nova cor (mesmo tipo)
            if(shell.material && shell.material.map){
                const t = ud.tipo || "spiral";
                const colPal = (t === "star") ? starPalette : shellPalette;
                const accPal = (t === "star") ? starAccentPalette : shellAccentPalette;
                const newCol = colPal[Math.floor(Math.random() * colPal.length)];
                const newAcc = accPal[Math.floor(Math.random() * accPal.length)];
                shell.material.map.dispose();
                shell.material.map = (t === "star")
                    ? makeStarTexture(newCol, newAcc)
                    : makeShellTexture(newCol, newAcc);
                shell.material.needsUpdate = true;
            }
        }
    }
'''

if padrao_anim.search(html):
    html = padrao_anim.sub(bloco_anim_novo + "\n\n    ", html, count=1)
    print("→ Animação das conchas reescrita (reciclagem dinâmica relativa à câmera).")
else:
    print("AVISO: bloco de animação das conchas não localizado pelo padrão. Tentando pelo for...")
    idx = html.find("for(let i = 0; i < fallingShells.length; i++){")
    end = html.find("for(let i=0; i<rays.length", idx)
    if idx != -1 and end != -1:
        html = html[:idx] + bloco_anim_novo + "\n\n    " + html[end:]
        print("→ Animação substituída (fallback).")
    else:
        print("ERRO: não consegui localizar a animação das conchas.")
        raise SystemExit(1)

with open("index.html", "w", encoding="utf-8") as f:
    f.write(html)

print("\n✓ Patch aplicado com sucesso!")
PYEOF

echo ""
echo "Pronto! Agora as conchas aparecem durante TODO o mergulho (início, meio e fim)."
echo "Para reverter: mv index.html.bak_meio index.html"
