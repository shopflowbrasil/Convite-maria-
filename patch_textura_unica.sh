#!/bin/bash
# =====================================================================
# PATCH — texturas ÚNICAS e ricas para cada tipo (espiral/cauri/vieira/estrela)
# =====================================================================

FILE="index.html"

if [ ! -f "$FILE" ]; then
  echo "ERRO: $FILE não encontrado nesta pasta."
  exit 1
fi

cp "$FILE" "${FILE}.bak_textura_unica"
echo "Backup criado: ${FILE}.bak_textura_unica"

python3 - << 'PYEOF'
import re

with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

# =====================================================================
# SUBSTITUI AS 2 FUNÇÕES DE TEXTURA POR 4 FUNÇÕES ESPECÍFICAS
# =====================================================================

novas_texturas = r'''// ---------------------------------------------------------
// TEXTURA — ESPIRAL (caracol marinho)
// Listras radiais que acompanham a espiral + gradiente + manchas
// ---------------------------------------------------------
function makeSpiralShellTexture(baseColorHex, accentColorHex){
    const size = 512;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');

    const base = new THREE.Color(baseColorHex);
    const accent = new THREE.Color(accentColorHex);
    const B = `rgb(${Math.round(base.r*255)},${Math.round(base.g*255)},${Math.round(base.b*255)})`;
    const A = `rgb(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)})`;

    // fundo: gradiente vertical (topo claro, base escura)
    const gradV = ctx.createLinearGradient(0, 0, 0, size);
    gradV.addColorStop(0, A);
    gradV.addColorStop(0.35, B);
    gradV.addColorStop(1, A);
    ctx.fillStyle = gradV;
    ctx.fillRect(0, 0, size, size);

    // faixas horizontais (as "voltas" da espiral)
    const voltas = 12;
    for(let i = 0; i < voltas; i++){
        const y = (i / voltas) * size;
        const h = size / voltas;
        ctx.fillStyle = `rgba(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)},${0.15 + Math.random()*0.15})`;
        ctx.fillRect(0, y, size, h * 0.55);

        // linha escura na base da volta
        ctx.fillStyle = `rgba(${Math.round(accent.r*200)},${Math.round(accent.g*180)},${Math.round(accent.b*150)},0.55)`;
        ctx.fillRect(0, y + h * 0.55, size, 2);

        // linha clara no topo
        ctx.fillStyle = `rgba(255,255,255,0.35)`;
        ctx.fillRect(0, y, size, 1.2);
    }

    // linhas verticais (nervuras)
    const nervuras = 28;
    for(let i = 0; i < nervuras; i++){
        const x = (i / nervuras) * size;
        ctx.strokeStyle = `rgba(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)},0.30)`;
        ctx.lineWidth = 1.2;
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x + 4, size);
        ctx.stroke();
    }

    // manchas orgânicas
    ctx.globalAlpha = 0.25;
    for(let i = 0; i < 300; i++){
        const x = Math.random() * size;
        const y = Math.random() * size;
        const rad = 1 + Math.random() * 3.5;
        ctx.fillStyle = Math.random() > 0.5 ? A : 'rgba(255,255,255,0.6)';
        ctx.beginPath();
        ctx.arc(x, y, rad, 0, Math.PI * 2);
        ctx.fill();
    }
    ctx.globalAlpha = 1;

    // vinheta
    const vg = ctx.createRadialGradient(size/2, size/2, size*0.25, size/2, size/2, size*0.6);
    vg.addColorStop(0, 'rgba(0,0,0,0)');
    vg.addColorStop(1, 'rgba(0,0,0,0.30)');
    ctx.fillStyle = vg;
    ctx.fillRect(0, 0, size, size);

    const tex = new THREE.CanvasTexture(canvas);
    tex.anisotropy = 8;
    return tex;
}

// ---------------------------------------------------------
// TEXTURA — CAURI (concha redonda com dentes)
// Padrão de "dentes" no centro + brilho perolado nas laterais
// ---------------------------------------------------------
function makeCowrieShellTexture(baseColorHex, accentColorHex){
    const size = 512;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');

    const base = new THREE.Color(baseColorHex);
    const accent = new THREE.Color(accentColorHex);

    // fundo perolado
    const grad = ctx.createRadialGradient(size/2, size/2, 30, size/2, size/2, size/2);
    grad.addColorStop(0, `rgb(${Math.round(255*(base.r*0.5+0.5))},${Math.round(255*(base.g*0.5+0.5))},${Math.round(255*(base.b*0.5+0.5))})`);
    grad.addColorStop(0.5, `rgb(${Math.round(base.r*255)},${Math.round(base.g*255)},${Math.round(base.b*255)})`);
    grad.addColorStop(1, `rgb(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)})`);
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, size, size);

    // centro alongado (a "boca" do cauri) — faixa vertical
    ctx.save();
    ctx.translate(size/2, size/2);

    // faixa da abertura (mais escura)
    const gradBoca = ctx.createLinearGradient(-25, 0, 25, 0);
    gradBoca.addColorStop(0, `rgba(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)},0)`);
    gradBoca.addColorStop(0.5, `rgba(${Math.round(accent.r*220)},${Math.round(accent.g*180)},${Math.round(accent.b*140)},0.65)`);
    gradBoca.addColorStop(1, `rgba(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)},0)`);
    ctx.fillStyle = gradBoca;
    ctx.fillRect(-30, -size*0.4, 60, size*0.8);

    // dentes (pequenas linhas horizontais curtas dentro da boca)
    for(let i = 0; i < 22; i++){
        const y = -size*0.35 + (i / 22) * size * 0.7;
        const w = 12 + Math.sin(i * 0.7) * 6;
        ctx.strokeStyle = `rgba(${Math.round(accent.r*180)},${Math.round(accent.g*140)},${Math.round(accent.b*110)},0.85)`;
        ctx.lineWidth = 2.2;
        ctx.beginPath();
        ctx.moveTo(-w, y);
        ctx.lineTo(w, y);
        ctx.stroke();

        // highlight branco entre os dentes
        ctx.strokeStyle = 'rgba(255,255,255,0.35)';
        ctx.lineWidth = 0.8;
        ctx.beginPath();
        ctx.moveTo(-w, y - 2.5);
        ctx.lineTo(w, y - 2.5);
        ctx.stroke();
    }
    ctx.restore();

    // brilho perolado nas laterais (dois highlights ovais)
    const hl1 = ctx.createRadialGradient(size*0.28, size*0.5, 5, size*0.28, size*0.5, 90);
    hl1.addColorStop(0, 'rgba(255,255,255,0.55)');
    hl1.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = hl1;
    ctx.fillRect(0, 0, size, size);

    const hl2 = ctx.createRadialGradient(size*0.72, size*0.5, 5, size*0.72, size*0.5, 90);
    hl2.addColorStop(0, 'rgba(255,255,255,0.45)');
    hl2.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = hl2;
    ctx.fillRect(0, 0, size, size);

    // manchinhas leves
    ctx.globalAlpha = 0.15;
    for(let i = 0; i < 180; i++){
        const x = Math.random() * size;
        const y = Math.random() * size;
        ctx.fillStyle = accent;
        ctx.beginPath();
        ctx.arc(x, y, 1 + Math.random() * 2, 0, Math.PI * 2);
        ctx.fill();
    }
    ctx.globalAlpha = 1;

    // vinheta
    const vg = ctx.createRadialGradient(size/2, size/2, size*0.3, size/2, size/2, size*0.6);
    vg.addColorStop(0, 'rgba(0,0,0,0)');
    vg.addColorStop(1, 'rgba(0,0,0,0.28)');
    ctx.fillStyle = vg;
    ctx.fillRect(0, 0, size, size);

    const tex = new THREE.CanvasTexture(canvas);
    tex.anisotropy = 8;
    return tex;
}

// ---------------------------------------------------------
// TEXTURA — VIEIRA (leque com costelas radiais)
// Raios partindo do centro (dobradiça) + linhas concêntricas
// ---------------------------------------------------------
function makeScallopShellTexture(baseColorHex, accentColorHex){
    const size = 512;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');

    const base = new THREE.Color(baseColorHex);
    const accent = new THREE.Color(accentColorHex);

    // fundo gradiente
    const grad = ctx.createRadialGradient(size/2, size*0.85, 10, size/2, size*0.85, size*0.9);
    grad.addColorStop(0, `rgb(${Math.round(255*(base.r*0.6+0.4))},${Math.round(255*(base.g*0.6+0.4))},${Math.round(255*(base.b*0.6+0.4))})`);
    grad.addColorStop(0.6, `rgb(${Math.round(base.r*255)},${Math.round(base.g*255)},${Math.round(base.b*255)})`);
    grad.addColorStop(1, `rgb(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)})`);
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, size, size);

    // costelas radiais partindo de baixo (dobradiça)
    const costelas = 22;
    ctx.save();
    ctx.translate(size/2, size*0.85);
    for(let i = 0; i < costelas; i++){
        const angle = -Math.PI/2 + (i / (costelas - 1) - 0.5) * Math.PI * 1.05;
        const ex = Math.cos(angle) * size * 0.85;
        const ey = Math.sin(angle) * size * 0.85;

        // linha escura (vale entre costelas)
        ctx.strokeStyle = `rgba(${Math.round(accent.r*180)},${Math.round(accent.g*160)},${Math.round(accent.b*130)},0.55)`;
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(ex, ey);
        ctx.stroke();

        // highlight ao lado
        ctx.strokeStyle = `rgba(255,255,255,0.45)`;
        ctx.lineWidth = 1.4;
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(ex * 1.0 + Math.cos(angle + 0.02) * 3,
                   ey * 1.0 + Math.sin(angle + 0.02) * 3);
        ctx.stroke();
    }
    ctx.restore();

    // linhas concêntricas (arcos)
    ctx.save();
    ctx.translate(size/2, size*0.85);
    for(let i = 1; i <= 7; i++){
        const rad = (i / 7) * size * 0.9;
        ctx.strokeStyle = `rgba(${Math.round(accent.r*200)},${Math.round(accent.g*180)},${Math.round(accent.b*150)},0.20)`;
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.arc(0, 0, rad, -Math.PI * 1.02, -Math.PI * 0.02);
        ctx.stroke();
    }
    ctx.restore();

    // manchas orgânicas
    ctx.globalAlpha = 0.22;
    for(let i = 0; i < 250; i++){
        const x = Math.random() * size;
        const y = Math.random() * size;
        const rad = 1.5 + Math.random() * 3;
        ctx.fillStyle = Math.random() > 0.5 ? accent : 'rgba(255,255,255,0.5)';
        ctx.beginPath();
        ctx.arc(x, y, rad, 0, Math.PI * 2);
        ctx.fill();
    }
    ctx.globalAlpha = 1;

    // vinheta
    const vg = ctx.createRadialGradient(size/2, size/2, size*0.35, size/2, size/2, size*0.75);
    vg.addColorStop(0, 'rgba(0,0,0,0)');
    vg.addColorStop(1, 'rgba(0,0,0,0.30)');
    ctx.fillStyle = vg;
    ctx.fillRect(0, 0, size, size);

    const tex = new THREE.CanvasTexture(canvas);
    tex.anisotropy = 8;
    return tex;
}

// ---------------------------------------------------------
// TEXTURA — ESTRELA DO MAR
// Padrão de pontinhos + tons em manchas + tubérculos
// ---------------------------------------------------------
function makeStarfishTexture(baseColorHex, accentColorHex){
    const size = 512;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');

    const base = new THREE.Color(baseColorHex);
    const accent = new THREE.Color(accentColorHex);

    // fundo gradiente
    const grad = ctx.createRadialGradient(size/2, size/2, 20, size/2, size/2, size/2);
    grad.addColorStop(0, `rgb(${Math.round(255*(base.r*0.6+0.4))},${Math.round(255*(base.g*0.6+0.4))},${Math.round(255*(base.b*0.6+0.4))})`);
    grad.addColorStop(1, `rgb(${Math.round(base.r*255)},${Math.round(base.g*255)},${Math.round(base.b*255)})`);
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, size, size);

    // pontinhos escuros em grade irregular
    ctx.fillStyle = `rgba(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)},0.60)`;
    for(let y = 0; y < size; y += 20){
        for(let x = 0; x < size; x += 20){
            const px = x + (Math.random() - 0.5) * 6;
            const py = y + (Math.random() - 0.5) * 6;
            const rad = 1.8 + Math.random() * 2.2;
            ctx.beginPath();
            ctx.arc(px, py, rad, 0, Math.PI * 2);
            ctx.fill();
        }
    }

    // pontinhos claros sobrepostos
    ctx.fillStyle = 'rgba(255,255,255,0.45)';
    for(let y = 10; y < size; y += 26){
        for(let x = 10; x < size; x += 26){
            const px = x + (Math.random() - 0.5) * 5;
            const py = y + (Math.random() - 0.5) * 5;
            ctx.beginPath();
            ctx.arc(px, py, 1.2, 0, Math.PI * 2);
            ctx.fill();
        }
    }

    // "tubérculos" maiores (as protuberâncias da estrela)
    for(let i = 0; i < 40; i++){
        const x = Math.random() * size;
        const y = Math.random() * size;
        const rad = 3 + Math.random() * 4;
        // sombra
        ctx.fillStyle = `rgba(${Math.round(accent.r*180)},${Math.round(accent.g*140)},${Math.round(accent.b*110)},0.55)`;
        ctx.beginPath();
        ctx.arc(x, y, rad, 0, Math.PI * 2);
        ctx.fill();
        // highlight
        ctx.fillStyle = 'rgba(255,255,255,0.55)';
        ctx.beginPath();
        ctx.arc(x - rad*0.3, y - rad*0.3, rad*0.55, 0, Math.PI * 2);
        ctx.fill();
    }

    // manchas suaves
    ctx.globalAlpha = 0.15;
    for(let i = 0; i < 120; i++){
        const x = Math.random() * size;
        const y = Math.random() * size;
        ctx.fillStyle = Math.random() > 0.5 ? accent : 'white';
        ctx.beginPath();
        ctx.arc(x, y, 4 + Math.random() * 8, 0, Math.PI * 2);
        ctx.fill();
    }
    ctx.globalAlpha = 1;

    // vinheta
    const vg = ctx.createRadialGradient(size/2, size/2, size*0.3, size/2, size/2, size*0.65);
    vg.addColorStop(0, 'rgba(0,0,0,0)');
    vg.addColorStop(1, 'rgba(0,0,0,0.25)');
    ctx.fillStyle = vg;
    ctx.fillRect(0, 0, size, size);

    const tex = new THREE.CanvasTexture(canvas);
    tex.anisotropy = 8;
    return tex;
}
'''

# Substitui as duas funções antigas (makeShellTexture e makeStarTexture)
padrao_texturas = re.compile(
    r"// -+\s*\n\s*// Textura procedural de concha \(canvas\).*?function makeStarTexture.*?\n\}\s*\n",
    re.DOTALL
)

if padrao_texturas.search(html):
    html = padrao_texturas.sub(novas_texturas + "\n", html, count=1)
    print("→ Funções de textura substituídas (4 funções específicas).")
else:
    print("AVISO: bloco de texturas antigo não localizado. Tentando fallback...")
    # fallback: substitui cada uma individualmente
    # makeShellTexture
    pat1 = re.compile(r"function makeShellTexture\(.*?\n\}\s*\n", re.DOTALL)
    html = pat1.sub("", html, count=1)
    # makeStarTexture
    pat2 = re.compile(r"function makeStarTexture\(.*?\n\}\s*\n", re.DOTALL)
    html = pat2.sub("", html, count=1)
    # insere as novas antes de "// Concha 3D elegante"
    marker = "// ---------------------------------------------------------\n// Concha 3D elegante"
    html = html.replace(marker, novas_texturas + "\n" + marker, 1)
    print("→ Fallback aplicado.")

# =====================================================================
# Atualiza as CHAMADAS para usar a textura correta de cada tipo
# =====================================================================
html = html.replace("tex = makeStarTexture(colorHex, accentHex);",
                    "tex = makeStarfishTexture(colorHex, accentHex);")
html = html.replace("tex = makeShellTexture(colorHex, accentHex);",
                    "tex = makeSpiralShellTexture(colorHex, accentHex);")

# Na criação — chama a textura certa por tipo
html = html.replace(
    """    } else if(tipo === "cowrie"){
        geo = createCowrieShell({
            radius: 0.7 + Math.random() * 0.4,
            length: 1.1 + Math.random() * 0.5
        });
        colorHex = shellPalette[Math.floor(Math.random() * shellPalette.length)];
        accentHex = shellAccentPalette[Math.floor(Math.random() * shellAccentPalette.length)];
        tex = makeSpiralShellTexture(colorHex, accentHex);""",
    """    } else if(tipo === "cowrie"){
        geo = createCowrieShell({
            radius: 0.7 + Math.random() * 0.4,
            length: 1.1 + Math.random() * 0.5
        });
        colorHex = shellPalette[Math.floor(Math.random() * shellPalette.length)];
        accentHex = shellAccentPalette[Math.floor(Math.random() * shellAccentPalette.length)];
        tex = makeCowrieShellTexture(colorHex, accentHex);"""
)

html = html.replace(
    """    } else if(tipo === "scallop"){
        geo = createScallopShell({
            radius: 0.9 + Math.random() * 0.5,
            depth: 0.20 + Math.random() * 0.15,
            ribs: 8 + Math.floor(Math.random() * 8)
        });
        colorHex = shellPalette[Math.floor(Math.random() * shellPalette.length)];
        accentHex = shellAccentPalette[Math.floor(Math.random() * shellAccentPalette.length)];
        tex = makeSpiralShellTexture(colorHex, accentHex);""",
    """    } else if(tipo === "scallop"){
        geo = createScallopShell({
            radius: 0.9 + Math.random() * 0.5,
            depth: 0.20 + Math.random() * 0.15,
            ribs: 8 + Math.floor(Math.random() * 8)
        });
        colorHex = shellPalette[Math.floor(Math.random() * shellPalette.length)];
        accentHex = shellAccentPalette[Math.floor(Math.random() * shellAccentPalette.length)];
        tex = makeScallopShellTexture(colorHex, accentHex);"""
)

# =====================================================================
# Atualiza a RECICLAGEM para regenerar a textura do tipo certo
# =====================================================================
bloco_reciclagem_novo = r'''            // regenera textura com nova cor (mesmo tipo)
            if(shell.material && shell.material.map){
                const t = ud.tipo || "spiral";
                let newTex;
                if(t === "star"){
                    const colPal = starPalette;
                    const accPal = starAccentPalette;
                    const nc = colPal[Math.floor(Math.random() * colPal.length)];
                    const na = accPal[Math.floor(Math.random() * accPal.length)];
                    newTex = makeStarfishTexture(nc, na);
                } else if(t === "cowrie"){
                    const nc = shellPalette[Math.floor(Math.random() * shellPalette.length)];
                    const na = shellAccentPalette[Math.floor(Math.random() * shellAccentPalette.length)];
                    newTex = makeCowrieShellTexture(nc, na);
                } else if(t === "scallop"){
                    const nc = shellPalette[Math.floor(Math.random() * shellPalette.length)];
                    const na = shellAccentPalette[Math.floor(Math.random() * shellAccentPalette.length)];
                    newTex = makeScallopShellTexture(nc, na);
                } else {
                    const nc = shellPalette[Math.floor(Math.random() * shellPalette.length)];
                    const na = shellAccentPalette[Math.floor(Math.random() * shellAccentPalette.length)];
                    newTex = makeSpiralShellTexture(nc, na);
                }
                shell.material.map.dispose();
                shell.material.map = newTex;
                shell.material.needsUpdate = true;
            }'''

padrao_rec = re.compile(
    r"// regenera textura com nova cor \(mesmo tipo\).*?shell\.material\.needsUpdate = true;\s*\n\s*\}",
    re.DOTALL
)

if padrao_rec.search(html):
    html = padrao_rec.sub(bloco_reciclagem_novo, html, count=1)
    print("→ Reciclagem atualizada para regenerar textura por tipo.")
else:
    print("AVISO: bloco de reciclagem de textura não localizado.")

with open("index.html", "w", encoding="utf-8") as f:
    f.write(html)

print("\n✓ Patch aplicado com sucesso!")
PYEOF

echo ""
echo "Pronto! Cada tipo agora tem textura única e detalhada."
echo "Para reverter: mv index.html.bak_textura_unica index.html"
