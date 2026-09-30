#!/bin/bash
# =====================================================================
# PATCH — adiciona conchas 3D visíveis no mergulho
# Aplica 3 substituições no index.html
# =====================================================================

FILE="index.html"

if [ ! -f "$FILE" ]; then
  echo "ERRO: $FILE não encontrado nesta pasta."
  exit 1
fi

cp "$FILE" "${FILE}.bak"
echo "Backup criado: ${FILE}.bak"

# ---------------------------------------------------------------------
# 1) Substitui TODO o bloco de conchas (do comentário CONCHAS até antes de MERGULHO)
# ---------------------------------------------------------------------
python3 - << 'PYEOF'
import re

with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

# --- 1. Substitui o bloco das conchas ---
novo_bloco_conchas = r'''/* =========================================================
   CONCHAS 3D CAINDO (formato real de concha de praia)
========================================================= */
const shellGroup = new THREE.Group();
scene.add(shellGroup);

// ---------------------------------------------------------
// Cria uma concha 3D real (LatheGeometry + nervuras + espiral)
// ---------------------------------------------------------
function createSeashellGeometry(opts){
    const {
        height      = 1.0,
        radius      = 1.0,
        segments    = 56,
        rings       = 18,
        twist       = 0.5,
        ribsCount   = 12
    } = opts || {};

    const profile = [];
    for(let i = 0; i <= rings; i++){
        const t = i / rings;
        const r = radius * Math.pow(Math.sin(t * Math.PI * 0.85), 0.7) * (1 - t * 0.15);
        const y = height * t - height * 0.5;
        profile.push(new THREE.Vector2(Math.max(r, 0.001), y));
    }

    const geo = new THREE.LatheGeometry(profile, segments);

    const pos = geo.attributes.position;
    const v = new THREE.Vector3();
    for(let i = 0; i < pos.count; i++){
        v.fromBufferAttribute(pos, i);
        const angle = Math.atan2(v.z, v.x);
        const radiusHere = Math.sqrt(v.x*v.x + v.z*v.z);

        const rib = Math.sin(angle * ribsCount) * 0.10 * radiusHere;

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

function createStarfishGeometry(scale){
    const shape = new THREE.Shape();
    const points = 5;
    const outer = 1.2;
    const inner = 0.5;
    for(let i = 0; i < points * 2; i++){
        const r = (i % 2 === 0) ? outer : inner;
        const a = (i / (points * 2)) * Math.PI * 2 - Math.PI / 2;
        const x = Math.cos(a) * r;
        const y = Math.sin(a) * r;
        if(i === 0) shape.moveTo(x, y);
        else shape.lineTo(x, y);
    }
    shape.closePath();

    const geo = new THREE.ExtrudeGeometry(shape, {
        depth: 0.35,
        bevelEnabled: true,
        bevelSegments: 4,
        bevelSize: 0.15,
        bevelThickness: 0.10,
        curveSegments: 8
    });
    geo.center();
    geo.scale(scale, scale, scale);
    return geo;
}

// ---------------------------------------------------------
// Cores naturais de concha (bem claras para brilhar no fundo escuro)
// ---------------------------------------------------------
const shellPalette = [
    0xfff2d9, 0xffe9c4, 0xffe0b5, 0xfff5e0, 0xfde8c8,
    0xffefd6, 0xfce0b8, 0xffe8cc, 0xfff8e6, 0xf9dfba
];
const starPalette = [
    0xffc896, 0xffb886, 0xffcfa0, 0xffbe94, 0xffd4a4
];

// ---------------------------------------------------------
// Cria as conchas — espalhadas por TODO o trajeto do mergulho
// ---------------------------------------------------------
const fallingShells = [];
const SHELL_COUNT = 40;

for(let i = 0; i < SHELL_COUNT; i++){
    const isStar = Math.random() < 0.20;

    let geo, colorHex;

    if(isStar){
        geo = createStarfishGeometry(1);
        colorHex = starPalette[Math.floor(Math.random() * starPalette.length)];
    } else {
        const h = 1.0 + Math.random() * 1.0;
        const r = 0.9 + Math.random() * 0.8;
        const twist = 0.3 + Math.random() * 0.7;
        const ribs = 8 + Math.floor(Math.random() * 8);
        geo = createSeashellGeometry({
            height: h,
            radius: r,
            segments: 48 + Math.floor(Math.random() * 24),
            rings: 14 + Math.floor(Math.random() * 8),
            twist: twist,
            ribsCount: ribs
        });
        colorHex = shellPalette[Math.floor(Math.random() * shellPalette.length)];
    }

    const mat = new THREE.MeshStandardMaterial({
        color: colorHex,
        roughness: 0.45,
        metalness: 0.15,
        emissive: new THREE.Color(colorHex).multiplyScalar(0.35),
        flatShading: false,
        side: THREE.DoubleSide
    });

    const mesh = new THREE.Mesh(geo, mat);

    const s = 2.2 + Math.random() * 2.2;
    mesh.scale.setScalar(s);

    // distribui por TODO o volume do mergulho
    mesh.position.set(
        (Math.random() - 0.5) * 120,
        20 - Math.random() * 160,
        -15 - Math.random() * 60
    );

    mesh.userData.velocityY       = -(0.05 + Math.random() * 0.15);
    mesh.userData.targetVelocityY = -(0.10 + Math.random() * 0.20);
    mesh.userData.rotSpeedX       = (Math.random() - 0.5) * 0.012;
    mesh.userData.rotSpeedY       = (Math.random() - 0.5) * 0.018;
    mesh.userData.rotSpeedZ       = (Math.random() - 0.5) * 0.012;
    mesh.userData.swayAmp         = 0.4 + Math.random() * 1.6;
    mesh.userData.swayFreq        = 0.0006 + Math.random() * 0.0016;
    mesh.userData.swayPhase       = Math.random() * Math.PI * 2;
    mesh.userData.baseX           = mesh.position.x;
    mesh.userData.baseZ           = mesh.position.z;
    mesh.userData.isStar          = isStar;

    shellGroup.add(mesh);
    fallingShells.push(mesh);
}

// ---------------------------------------------------------
// Luzes extras para iluminar as conchas no fundo escuro
// ---------------------------------------------------------
const shellLight = new THREE.PointLight(0xffe8c0, 2.5, 400, 1.2);
shellLight.position.set(0, 0, 20);
scene.add(shellLight);

const shellLight2 = new THREE.PointLight(0xcfeaff, 1.8, 400, 1.2);
shellLight2.position.set(-40, -60, 20);
scene.add(shellLight2);

const shellLight3 = new THREE.PointLight(0xffd9a8, 1.8, 400, 1.2);
shellLight3.position.set(40, -110, 20);
scene.add(shellLight3);
'''

# Localiza o bloco antigo de conchas
padrao_conchas = re.compile(
    r"/\* =+\s*\n\s*CONCHAS.*?\n\s*=+\s*\*/.*?(?=/\* =+\s*\n\s*MERGULHO)",
    re.DOTALL
)

if not padrao_conchas.search(html):
    print("AVISO: bloco antigo de conchas não localizado pelo padrão. Tentando outro método...")
    # fallback: procura por "const shellGroup" até antes de "MERGULHO"
    idx_start = html.find("/* =========================================================\n   CONCHAS")
    idx_end = html.find("/* =========================================================\n   MERGULHO")
    if idx_start == -1 or idx_end == -1 or idx_end <= idx_start:
        print("ERRO: não consegui localizar os blocos CONCHAS/MERGULHO.")
        raise SystemExit(1)
    html = html[:idx_start] + novo_bloco_conchas + "\n\n" + html[idx_end:]
else:
    html = padrao_conchas.sub(novo_bloco_conchas + "\n\n", html, count=1)

# --- 2. Suaviza a névoa no updateDive ---
html = html.replace(
    """    const depth = clamp((-camera.position.y) / 120, 0, 1);
    const fogTop = new THREE.Color(0x0d6a95);
    const fogBot = new THREE.Color(0x021f38);
    scene.fog.color.copy(fogTop.clone().lerp(fogBot, depth));
    scene.fog.density = .018 + depth * .012;""",
    """    const depth = clamp((-camera.position.y) / 120, 0, 1);
    const fogTop = new THREE.Color(0x0d6a95);
    const fogBot = new THREE.Color(0x021f38);
    scene.fog.color.copy(fogTop.clone().lerp(fogBot, depth));
    // névoa MUITO mais leve para as conchas ficarem visíveis
    scene.fog.density = .004 + depth * .004;"""
)

# --- 3. Substitui o bloco de animação das conchas dentro do diveLoop ---
novo_bloco_anim = r'''    /* =====================================================
       CONCHAS 3D CAINDO — animação principal
    ===================================================== */
    for(let i = 0; i < fallingShells.length; i++){
        const shell = fallingShells[i];
        const ud = shell.userData;

        ud.velocityY += (ud.targetVelocityY - ud.velocityY) * 0.02;
        shell.position.y += ud.velocityY * 60 * dt;

        shell.position.x = ud.baseX + Math.sin(now * ud.swayFreq + ud.swayPhase) * ud.swayAmp;
        shell.position.z = ud.baseZ + Math.cos(now * ud.swayFreq * 0.7 + ud.swayPhase) * ud.swayAmp * 0.6;

        shell.rotation.x += ud.rotSpeedX;
        shell.rotation.y += ud.rotSpeedY;
        shell.rotation.z += ud.rotSpeedZ;

        // recicla quando passa por baixo da câmera
        if(shell.position.y < -150){
            shell.position.y = camera.position.y + 20 + Math.random() * 40;
            shell.position.x = (Math.random() - 0.5) * 120;
            shell.position.z = -15 - Math.random() * 60;
            ud.baseX = shell.position.x;
            ud.baseZ = shell.position.z;
            ud.velocityY = -(0.05 + Math.random() * 0.15);
            ud.targetVelocityY = -(0.10 + Math.random() * 0.20);
            ud.swayPhase = Math.random() * Math.PI * 2;
            if(shell.material && shell.material.color){
                const pal = ud.isStar ? starPalette : shellPalette;
                const newColor = new THREE.Color(pal[Math.floor(Math.random() * pal.length)]);
                shell.material.color.copy(newColor);
                shell.material.emissive.copy(newColor).multiplyScalar(0.35);
            }
        }
    }
'''

padrao_anim = re.compile(
    r"/\* =+\s*\n\s*CONCHAS 3D CAINDO — animação principal\s*\n\s*=+\s*\*/.*?(?=\n\s*for\(let i=0; i<rays\.length)",
    re.DOTALL
)

if padrao_anim.search(html):
    html = padrao_anim.sub(novo_bloco_anim, html, count=1)
else:
    print("AVISO: bloco de animação das conchas não localizado pelo padrão exato.")
    # fallback: substitui a versão anterior conhecida
    antigo_fallback = re.compile(
        r"/\* =+\s*\n\s*CONCHAS 3D CAINDO.*?\n\s*=+\s*\*/.*?(?=\n\s*for\(let i=0; i<rays\.length)",
        re.DOTALL
    )
    if antigo_fallback.search(html):
        html = antigo_fallback.sub(novo_bloco_anim, html, count=1)
    else:
        print("ERRO: não consegui substituir a animação das conchas.")
        raise SystemExit(1)

with open("index.html", "w", encoding="utf-8") as f:
    f.write(html)

print("PATCH aplicado com sucesso!")
PYEOF

echo ""
echo "Pronto! Abra o index.html no navegador."
echo "Se algo der errado, restaure com:  mv index.html.bak index.html"
