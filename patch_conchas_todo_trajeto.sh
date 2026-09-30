#!/bin/bash
# =====================================================================
# PATCH — conchas distribuídas em CAMADAS por todo o trajeto do mergulho
# =====================================================================

FILE="index.html"

if [ ! -f "$FILE" ]; then
  echo "ERRO: $FILE não encontrado nesta pasta."
  exit 1
fi

cp "$FILE" "${FILE}.bak_camadas"
echo "Backup criado: ${FILE}.bak_camadas"

python3 - << 'PYEOF'
import re

with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

# =====================================================================
# 1) CRIAÇÃO — distribui as conchas em CAMADAS ao longo do trajeto
#     A câmera vai de y=+6 até y=-118. Cobre de +30 até -170.
# =====================================================================
bloco_criacao_novo = r'''// ---------------------------------------------------------
// Cria MUITAS conchas/estrelas em CAMADAS ao longo do trajeto
// (garante conchas visíveis do início ao fim do mergulho)
// ---------------------------------------------------------
const fallingShells = [];
const SHELL_COUNT = 140;   // <- muitas conchas

// A câmera vai de y = +6 até y = -118, então distribuímos as conchas
// em 8 camadas verticais que cobrem de y = +30 até y = -170.
// Assim, conforme a câmera desce, ela vai ATRAVESSANDO camadas de conchas.
const CAMADAS = 8;
const Y_TOPO = 30;       // acima do início da câmera
const Y_FUNDO = -170;    // abaixo do fim da câmera
const ALTURA_TOTAL = Y_TOPO - Y_FUNDO;

for(let i = 0; i < SHELL_COUNT; i++){
    // sorteio do tipo
    const roll = Math.random();
    let tipo;
    if(roll < 0.55) tipo = "spiral";
    else if(roll < 0.80) tipo = "cowrie";
    else if(roll < 0.90) tipo = "scallop";
    else tipo = "star";

    let geo, colorHex, accentHex, tex;

    if(tipo === "star"){
        geo = createStarfishGeometry(1);
        colorHex = starPalette[Math.floor(Math.random() * starPalette.length)];
        accentHex = starAccentPalette[Math.floor(Math.random() * starAccentPalette.length)];
        tex = makeStarTexture(colorHex, accentHex);
    } else if(tipo === "cowrie"){
        geo = createCowrieShell({
            radius: 0.7 + Math.random() * 0.4,
            length: 1.1 + Math.random() * 0.5
        });
        colorHex = shellPalette[Math.floor(Math.random() * shellPalette.length)];
        accentHex = shellAccentPalette[Math.floor(Math.random() * shellAccentPalette.length)];
        tex = makeShellTexture(colorHex, accentHex);
    } else if(tipo === "scallop"){
        geo = createScallopShell({
            radius: 0.9 + Math.random() * 0.5,
            depth: 0.20 + Math.random() * 0.15,
            ribs: 8 + Math.floor(Math.random() * 8)
        });
        colorHex = shellPalette[Math.floor(Math.random() * shellPalette.length)];
        accentHex = shellAccentPalette[Math.floor(Math.random() * shellAccentPalette.length)];
        tex = makeShellTexture(colorHex, accentHex);
    } else {
        const h = 1.2 + Math.random() * 0.9;
        const r = 0.55 + Math.random() * 0.35;
        const twist = 0.8 + Math.random() * 1.2;
        const ribs = 10 + Math.floor(Math.random() * 8);
        geo = createSpiralShell({
            height: h,
            radius: r,
            segments: 56 + Math.floor(Math.random() * 24),
            rings: 28 + Math.floor(Math.random() * 10),
            twist: twist,
            ribsCount: ribs
        });
        colorHex = shellPalette[Math.floor(Math.random() * shellPalette.length)];
        accentHex = shellAccentPalette[Math.floor(Math.random() * shellAccentPalette.length)];
        tex = makeShellTexture(colorHex, accentHex);
    }

    const mat = new THREE.MeshStandardMaterial({
        map: tex,
        color: 0xffffff,
        roughness: 0.55,
        metalness: 0.15,
        flatShading: false,
        side: THREE.DoubleSide
    });

    const mesh = new THREE.Mesh(geo, mat);

    const s = 1.2 + Math.random() * 1.8;
    mesh.scale.setScalar(s);

    // Distribui em camadas verticais — cada concha vai para uma faixa
    // dentro do range que a câmera vai atravessar
    const camadaIdx = i % CAMADAS;
    const alturaCamada = ALTURA_TOTAL / CAMADAS;
    const yBase = Y_TOPO - camadaIdx * alturaCamada - Math.random() * alturaCamada;

    mesh.position.set(
        (Math.random() - 0.5) * 44,
        yBase,
        -22 - Math.random() * 48
    );

    mesh.userData.velocityY = -(7 + Math.random() * 11);
    mesh.userData.rotSpeedX = (Math.random() - 0.5) * 1.0;
    mesh.userData.rotSpeedY = (Math.random() - 0.5) * 1.5;
    mesh.userData.rotSpeedZ = (Math.random() - 0.5) * 1.0;
    mesh.userData.swayAmp   = 0.2 + Math.random() * 1.0;
    mesh.userData.swayFreq  = 0.0006 + Math.random() * 0.0016;
    mesh.userData.swayPhase = Math.random() * Math.PI * 2;
    mesh.userData.baseX     = mesh.position.x;
    mesh.userData.baseZ     = mesh.position.z;
    mesh.userData.tipo      = tipo;

    shellGroup.add(mesh);
    fallingShells.push(mesh);
}
'''

# Substitui o bloco de criação
padrao_criacao = re.compile(
    r"// -+\s*\n\s*// Cria MUITAS conchas.*?fallingShells\.push\(mesh\);\s*\n\}",
    re.DOTALL
)
if padrao_criacao.search(html):
    html = padrao_criacao.sub(bloco_criacao_novo, html, count=1)
    print("→ Bloco de criação substituído (140 conchas em 8 camadas).")
else:
    # fallback
    idx = html.find("const fallingShells = [];")
    if idx == -1:
        print("ERRO: 'const fallingShells' não encontrado.")
        raise SystemExit(1)
    end = html.find("\n}\n", html.find("fallingShells.push(mesh);", idx))
    html = html[:idx] + bloco_criacao_novo + html[end+3:]
    print("→ Bloco de criação substituído (fallback).")

# =====================================================================
# 2) RECICLAGEM — quando a concha cai abaixo de Y_FUNDO, volta pro TOPO
#     (não depende da câmera! Isso garante camadas contínuas)
# =====================================================================
padrao_anim = re.compile(
    r"for\(let i = 0; i < fallingShells\.length; i\+\+\)\{.*?(?=\n\s*for\(let i=0; i<rays\.length)",
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

        // Recicla quando a concha passa do fundo: volta pro TOPO (y=30)
        // Isso mantém camadas contínuas caindo por todo o trajeto, sem
        // depender da posição da câmera.
        if(shell.position.y < -170){
            shell.position.y = 30 + Math.random() * 15;
            shell.position.x = (Math.random() - 0.5) * 44;
            shell.position.z = -22 - Math.random() * 48;
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
    print("→ Reciclagem reescrita (conchas voltam para y=+30 sempre).")
else:
    idx = html.find("for(let i = 0; i < fallingShells.length; i++){")
    end = html.find("for(let i=0; i<rays.length", idx)
    if idx != -1 and end != -1:
        html = html[:idx] + bloco_anim_novo + "\n\n    " + html[end:]
        print("→ Reciclagem reescrita (fallback).")
    else:
        print("ERRO: não consegui localizar a animação das conchas.")
        raise SystemExit(1)

with open("index.html", "w", encoding="utf-8") as f:
    f.write(html)

print("\n✓ Patch aplicado com sucesso!")
PYEOF

echo ""
echo "Pronto! Agora as conchas estão em 8 camadas verticais e caem durante TODO o mergulho."
echo "Para reverter: mv index.html.bak_camadas index.html"
