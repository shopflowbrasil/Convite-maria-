#!/bin/bash
# =====================================================================
# PATCH FINAL — troca APENAS os peixes por conchas 3D caindo
# Não mexe em CSS, luzes, névoa, layout, nada.
# =====================================================================

FILE="index.html"

if [ ! -f "$FILE" ]; then
  echo "ERRO: $FILE não encontrado."
  exit 1
fi

cp "$FILE" "${FILE}.pre_conchas"
echo "Backup: ${FILE}.pre_conchas"

python3 - << 'PYEOF'
import re

with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

# ---------------------------------------------------------------------
# 1) Remove a CLASSE Fish inteira (bloco "CLASSE FISH" até "ELEMENTOS")
# ---------------------------------------------------------------------
padrao_fish_class = re.compile(
    r"/\* =+\s*\n\s*CLASSE FISH\s*\n\s*=+\s*\*/.*?(?=/\* =+\s*\n\s*ELEMENTOS)",
    re.DOTALL
)
if padrao_fish_class.search(html):
    html = padrao_fish_class.sub("", html)
else:
    print("AVISO: bloco CLASSE FISH não localizado.")

# ---------------------------------------------------------------------
# 2) Remove o bloco dos PEIXES (splines + criação dos fishes)
# ---------------------------------------------------------------------
padrao_peixes = re.compile(
    r"/\* Peixes \*/.*?(?=/\* Mergulho \*/)",
    re.DOTALL
)
if padrao_peixes.search(html):
    html = padrao_peixes.sub("", html)
else:
    print("AVISO: bloco '/* Peixes */' não localizado.")

# Também remove possíveis restos das configurações de peixe
padrao_configs = re.compile(
    r"function makeSpline\(points\)\{.*?const fishes = \[\];.*?\n\}\n",
    re.DOTALL
)
html = padrao_configs.sub("", html)

# ---------------------------------------------------------------------
# 3) Insere o bloco das CONCHAS 3D no lugar (antes de /* Mergulho */)
# ---------------------------------------------------------------------
bloco_conchas = r'''/* =========================================================
   CONCHAS E ESTRELAS 3D CAINDO
========================================================= */
const shellGroup = new THREE.Group();
scene.add(shellGroup);

// Concha 3D real (LatheGeometry + nervuras + espiral)
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

// Estrela do mar 3D
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

// Paleta natural de concha/areia (tons quentes, sem estourar)
const shellPalette = [
    0xe8c9a0, 0xdcb98a, 0xd9b48a, 0xe6c9a8, 0xcfae7a,
    0xe0c098, 0xd4b080, 0xe2c4a0, 0xcaa878, 0xdcc0a0
];
const starPalette = [
    0xd99a6a, 0xcc8858, 0xdbaa78, 0xc98860, 0xdba274
];

// Cria 40 conchas/estrelas caindo
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
        roughness: 0.65,
        metalness: 0.10,
        flatShading: false,
        side: THREE.DoubleSide
    });

    const mesh = new THREE.Mesh(geo, mat);

    const s = 1.8 + Math.random() * 1.6;
    mesh.scale.setScalar(s);

    mesh.position.set(
        (Math.random() - 0.5) * 120,
        20 - Math.random() * 160,
        -15 - Math.random() * 60
    );

    mesh.userData.velocityY = -(8 + Math.random() * 10);
    mesh.userData.rotSpeedX = (Math.random() - 0.5) * 0.9;
    mesh.userData.rotSpeedY = (Math.random() - 0.5) * 1.2;
    mesh.userData.rotSpeedZ = (Math.random() - 0.5) * 0.9;
    mesh.userData.swayAmp   = 0.3 + Math.random() * 1.2;
    mesh.userData.swayFreq  = 0.0006 + Math.random() * 0.0016;
    mesh.userData.swayPhase = Math.random() * Math.PI * 2;
    mesh.userData.baseX     = mesh.position.x;
    mesh.userData.baseZ     = mesh.position.z;
    mesh.userData.isStar    = isStar;

    shellGroup.add(mesh);
    fallingShells.push(mesh);
}

'''

# Insere antes de /* Mergulho */
if "/* Mergulho */" in html:
    html = html.replace("/* Mergulho */", bloco_conchas + "/* Mergulho */", 1)
else:
    print("AVISO: marcador '/* Mergulho */' não encontrado.")

# ---------------------------------------------------------------------
# 4) Substitui a ANIMAÇÃO dos peixes dentro do diveLoop por conchas
# ---------------------------------------------------------------------
padrao_anim_fishes = re.compile(
    r"for\(let i=0; i<fishes\.length; i\+\+\)\{.*?\n    \}\n",
    re.DOTALL
)

nova_anim = r'''for(let i = 0; i < fallingShells.length; i++){
        const shell = fallingShells[i];
        const ud = shell.userData;

        // queda vertical rápida
        shell.position.y += ud.velocityY * dt;

        // leve oscilação lateral (correnteza)
        shell.position.x = ud.baseX + Math.sin(now * ud.swayFreq + ud.swayPhase) * ud.swayAmp;
        shell.position.z = ud.baseZ + Math.cos(now * ud.swayFreq * 0.7 + ud.swayPhase) * ud.swayAmp * 0.6;

        // rotação visível
        shell.rotation.x += ud.rotSpeedX * dt;
        shell.rotation.y += ud.rotSpeedY * dt;
        shell.rotation.z += ud.rotSpeedZ * dt;

        // recicla quando sai por baixo da câmera
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
'''

if padrao_anim_fishes.search(html):
    html = padrao_anim_fishes.sub(nova_anim, html, count=1)
else:
    print("AVISO: bloco de animação dos fishes não localizado por regex.")
    # fallback: procura literalmente
    marker = "for(let i=0; i<fishes.length; i++){"
    idx = html.find(marker)
    if idx != -1:
        # encontra o final do bloco (próximo "\n    }\n")
        end = html.find("\n    }\n", idx)
        if end != -1:
            html = html[:idx] + nova_anim + html[end+len("\n    }\n"):]

with open("index.html", "w", encoding="utf-8") as f:
    f.write(html)

print("PATCH FINAL aplicado — somente as conchas foram adicionadas.")
PYEOF

echo ""
echo "Pronto! Abra o index.html e toque na tela."
echo "Para reverter:  mv index.html.pre_conchas index.html"
