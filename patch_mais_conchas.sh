#!/bin/bash
# =====================================================================
# PATCH — MUITO mais conchas + variedade de formatos
# =====================================================================

FILE="index.html"

if [ ! -f "$FILE" ]; then
  echo "ERRO: $FILE não encontrado nesta pasta."
  exit 1
fi

cp "$FILE" "${FILE}.bak_mais_conchas"
echo "Backup criado: ${FILE}.bak_mais_conchas"

python3 - << 'PYEOF'
import re

with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

# =====================================================================
# 1) NOVAS FUNÇÕES DE GEOMETRIA (3 tipos de concha + estrela)
# =====================================================================
# Adiciona as novas funções logo antes de "const shellGroup = new THREE.Group();"
novas_funcoes = r'''
// ---------------------------------------------------------
// TIPO 1 — Concha espiral alongada (caracol marinho)
// ---------------------------------------------------------
function createSpiralShell(opts){
    const {
        height      = 1.4,
        radius      = 0.7,
        segments    = 64,
        rings       = 32,
        twist       = 1.2,
        ribsCount   = 14
    } = opts || {};

    const profile = [];
    for(let i = 0; i <= rings; i++){
        const t = i / rings;
        const r = radius * Math.pow(1 - t, 0.85) * (0.35 + 0.65 * Math.sin(t * Math.PI * 0.9));
        const y = height * t - height * 0.5;
        profile.push(new THREE.Vector2(Math.max(r, 0.002), y));
    }

    const geo = new THREE.LatheGeometry(profile, segments);
    const pos = geo.attributes.position;
    const v = new THREE.Vector3();
    for(let i = 0; i < pos.count; i++){
        v.fromBufferAttribute(pos, i);
        const angle = Math.atan2(v.z, v.x);
        const radiusHere = Math.sqrt(v.x*v.x + v.z*v.z);
        const rib = Math.sin(angle * ribsCount) * 0.06 * radiusHere;
        const twistAngle = v.y * twist;
        const tx = Math.cos(twistAngle);
        const tz = Math.sin(twistAngle);
        const nx = v.x * tx - v.z * tz;
        const nz = v.x * tz + v.z * tx;
        v.x = nx;
        v.z = nz;
        const scaleR = 1 + rib;
        v.x *= scaleR;
        v.z *= scaleR;
        pos.setXYZ(i, v.x, v.y, v.z);
    }
    geo.computeVertexNormals();
    return geo;
}

// ---------------------------------------------------------
// TIPO 2 — Cauri (concha redonda e gordinha com abertura)
// ---------------------------------------------------------
function createCowrieShell(opts){
    const {
        radius = 0.9,
        length = 1.4
    } = opts || {};

    // Forma oval via Lathe com perfil que lembra um ovo
    const points = [];
    const N = 32;
    for(let i = 0; i <= N; i++){
        const t = i / N;
        // perfil de ovo alongado
        const r = radius * Math.sin(t * Math.PI) * (0.6 + 0.4 * Math.sin(t * Math.PI));
        const y = length * (t - 0.5);
        points.push(new THREE.Vector2(Math.max(r, 0.002), y));
    }

    const geo = new THREE.LatheGeometry(points, 48);
    // aplana no eixo X (cauri é achatado lateralmente)
    geo.scale(0.55, 1, 1);

    const pos = geo.attributes.position;
    const v = new THREE.Vector3();
    for(let i = 0; i < pos.count; i++){
        v.fromBufferAttribute(pos, i);
        const angle = Math.atan2(v.z, v.x);
        // pequenas ondulações (dentes da abertura)
        const ripple = Math.sin(angle * 18) * 0.02 * Math.abs(v.y);
        const rr = 1 + ripple;
        v.x *= rr;
        v.z *= rr;
        pos.setXYZ(i, v.x, v.y, v.z);
    }
    geo.computeVertexNormals();
    return geo;
}

// ---------------------------------------------------------
// TIPO 3 — Vieira (concha leque com costelas radiais)
// ---------------------------------------------------------
function createScallopShell(opts){
    const {
        radius = 1.2,
        depth  = 0.25,
        ribs   = 12
    } = opts || {};

    // Perfil em leque: semicírculo com ondulações na borda
    const shape = new THREE.Shape();
    const N = 64;
    const points = [];
    for(let i = 0; i <= N; i++){
        const t = i / N;
        const angle = Math.PI * t; // 0 a PI (semicírculo)
        const scallopEdge = 1 + Math.sin(angle * ribs) * 0.06;
        const r = radius * scallopEdge;
        const x = Math.cos(angle) * r - radius * 0.5;
        const y = Math.sin(angle) * r;
        points.push({ x, y });
    }
    // fecha pela base reta
    shape.moveTo(points[0].x, points[0].y);
    for(let i = 1; i < points.length; i++){
        shape.lineTo(points[i].x, points[i].y);
    }
    shape.lineTo(points[points.length-1].x, 0);
    shape.lineTo(points[0].x, 0);
    shape.closePath();

    const geo = new THREE.ExtrudeGeometry(shape, {
        depth: depth,
        bevelEnabled: true,
        bevelSegments: 2,
        bevelSize: 0.04,
        bevelThickness: 0.03,
        curveSegments: 12
    });
    geo.center();
    return geo;
}

'''

if "const shellGroup = new THREE.Group();" in html:
    html = html.replace(
        "const shellGroup = new THREE.Group();",
        novas_funcoes + "const shellGroup = new THREE.Group();",
        1
    )
    print("→ Funções de 3 tipos de concha adicionadas.")
else:
    print("AVISO: marcador 'const shellGroup' não encontrado.")

# =====================================================================
# 2) Substitui o bloco de CRIAÇÃO das conchas (aumenta quantidade e variedade)
# =====================================================================
bloco_criacao = r'''// ---------------------------------------------------------
// Cria MUITAS conchas/estrelas caindo — concentradas no centro
// ---------------------------------------------------------
const fallingShells = [];
const SHELL_COUNT = 120;   // <- muito mais conchas

for(let i = 0; i < SHELL_COUNT; i++){
    // sorteio do tipo: 55% espiral, 25% cauri, 10% vieira, 10% estrela
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

    // variação de escala
    const s = 1.2 + Math.random() * 1.8;
    mesh.scale.setScalar(s);

    // CENTRALIZADAS — X ±22, Z -22 a -70
    mesh.position.set(
        (Math.random() - 0.5) * 44,
        20 - Math.random() * 180,
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

# Localiza o bloco de criação (do comentário "Cria ... conchas" até o final do for)
padrao_criacao = re.compile(
    r"// -+\s*\n\s*// Cria.*?conchas.*?\n\s*// -+.*?const fallingShells = \[\];.*?fallingShells\.push\(mesh\);\s*\n\}",
    re.DOTALL
)

if padrao_criacao.search(html):
    html = padrao_criacao.sub(bloco_criacao, html, count=1)
    print("→ Bloco de criação das conchas substituído (120 conchas, 3 tipos).")
else:
    # fallback: procura por "const fallingShells = []" até o fechamento do for
    idx = html.find("const fallingShells = [];")
    if idx == -1:
        print("ERRO: 'const fallingShells' não encontrado.")
        raise SystemExit(1)
    # encontra o final do for (próximo "\n}\n" que fecha o for)
    end = html.find("\n}\n", html.find("fallingShells.push(mesh);", idx))
    if end == -1:
        print("ERRO: fim do for não encontrado.")
        raise SystemExit(1)
    html = html[:idx] + bloco_criacao + html[end+3:]

# =====================================================================
# 3) Atualiza o bloco de RECICLAGEM para usar o campo "tipo"
# =====================================================================
bloco_reciclagem_novo = r'''        if(shell.position.y < camera.position.y - 40){
            shell.position.y = camera.position.y + 40 + Math.random() * 40;
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
        }'''

padrao_rec = re.compile(
    r"if\(shell\.position\.y < camera\.position\.y - 40\)\{.*?\n        \}",
    re.DOTALL
)

if padrao_rec.search(html):
    html = padrao_rec.sub(bloco_reciclagem_novo, html, count=1)
    print("→ Bloco de reciclagem atualizado.")
else:
    print("AVISO: bloco de reciclagem não localizado.")

with open("index.html", "w", encoding="utf-8") as f:
    f.write(html)

print("\n✓ Patch aplicado com sucesso!")
PYEOF

echo ""
echo "Pronto! Abra o index.html — agora são 120 conchas de 3 tipos diferentes."
echo "Para reverter: mv index.html.bak_mais_conchas index.html"
