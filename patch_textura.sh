#!/bin/bash
# =====================================================================
# PATCH — textura + cor nas conchas/estrelas + centralizar na tela
# =====================================================================

FILE="index.html"

if [ ! -f "$FILE" ]; then
  echo "ERRO: $FILE não encontrado nesta pasta."
  exit 1
fi

cp "$FILE" "${FILE}.bak_textura"
echo "Backup criado: ${FILE}.bak_textura"

python3 - << 'PYEOF'
import re

with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

# =====================================================================
# 1) BLOCO NOVO DAS CONCHAS (criação + texturas)
# =====================================================================
novo_bloco = r'''/* =========================================================
   CONCHAS E ESTRELAS 3D — com textura e centralizadas
========================================================= */
const shellGroup = new THREE.Group();
scene.add(shellGroup);

// ---------------------------------------------------------
// Textura procedural de concha (canvas)
// ---------------------------------------------------------
function makeShellTexture(baseColorHex, accentColorHex){
    const size = 256;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');

    const base = new THREE.Color(baseColorHex);
    const accent = new THREE.Color(accentColorHex);

    // fundo gradiente
    const grad = ctx.createRadialGradient(size/2, size/2, 10, size/2, size/2, size/2);
    grad.addColorStop(0, `rgb(${Math.round(255*(base.r*0.4+0.6))},${Math.round(255*(base.g*0.4+0.6))},${Math.round(255*(base.b*0.4+0.6))})`);
    grad.addColorStop(0.6, `rgb(${Math.round(base.r*255)},${Math.round(base.g*255)},${Math.round(base.b*255)})`);
    grad.addColorStop(1, `rgb(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)})`);
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, size, size);

    // linhas radiais (nervuras)
    ctx.save();
    ctx.translate(size/2, size/2);
    const ribCount = 20;
    for(let i = 0; i < ribCount; i++){
        const angle = (i / ribCount) * Math.PI * 2;
        ctx.rotate(angle);
        const grad2 = ctx.createLinearGradient(0, 0, size/2, 0);
        grad2.addColorStop(0, `rgba(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)},0.55)`);
        grad2.addColorStop(0.5, `rgba(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)},0.15)`);
        grad2.addColorStop(1, `rgba(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)},0.65)`);
        ctx.fillStyle = grad2;
        ctx.fillRect(0, -1.2, size/2, 2.4);
        ctx.fillStyle = `rgba(255,255,255,0.20)`;
        ctx.fillRect(0, 1.2, size/2, 1.0);
        ctx.rotate(-angle);
    }
    ctx.restore();

    // manchinhas
    ctx.globalAlpha = 0.18;
    for(let i = 0; i < 220; i++){
        const x = Math.random() * size;
        const y = Math.random() * size;
        const rad = 0.6 + Math.random() * 1.8;
        ctx.fillStyle = `rgb(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)})`;
        ctx.beginPath();
        ctx.arc(x, y, rad, 0, Math.PI * 2);
        ctx.fill();
    }
    ctx.globalAlpha = 1;

    // vinheta
    const vg = ctx.createRadialGradient(size/2, size/2, size*0.3, size/2, size/2, size*0.55);
    vg.addColorStop(0, 'rgba(0,0,0,0)');
    vg.addColorStop(1, 'rgba(0,0,0,0.18)');
    ctx.fillStyle = vg;
    ctx.fillRect(0, 0, size, size);

    const tex = new THREE.CanvasTexture(canvas);
    tex.anisotropy = 4;
    return tex;
}

// ---------------------------------------------------------
// Textura de estrela do mar
// ---------------------------------------------------------
function makeStarTexture(baseColorHex, accentColorHex){
    const size = 256;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');

    const base = new THREE.Color(baseColorHex);
    const accent = new THREE.Color(accentColorHex);

    ctx.fillStyle = `rgb(${Math.round(base.r*255)},${Math.round(base.g*255)},${Math.round(base.b*255)})`;
    ctx.fillRect(0, 0, size, size);

    ctx.fillStyle = `rgba(${Math.round(accent.r*255)},${Math.round(accent.g*255)},${Math.round(accent.b*255)},0.55)`;
    for(let y = 0; y < size; y += 14){
        for(let x = 0; x < size; x += 14){
            const px = x + (Math.random() - 0.5) * 4;
            const py = y + (Math.random() - 0.5) * 4;
            ctx.beginPath();
            ctx.arc(px, py, 1.3 + Math.random() * 1.2, 0, Math.PI * 2);
            ctx.fill();
        }
    }
    ctx.fillStyle = 'rgba(255,255,255,0.35)';
    for(let y = 7; y < size; y += 18){
        for(let x = 7; x < size; x += 18){
            ctx.beginPath();
            ctx.arc(x + (Math.random()-0.5)*3, y + (Math.random()-0.5)*3, 0.9, 0, Math.PI*2);
            ctx.fill();
        }
    }
    const vg = ctx.createRadialGradient(size/2, size/2, size*0.2, size/2, size/2, size*0.6);
    vg.addColorStop(0, 'rgba(255,255,255,0.10)');
    vg.addColorStop(1, 'rgba(0,0,0,0.20)');
    ctx.fillStyle = vg;
    ctx.fillRect(0, 0, size, size);

    const tex = new THREE.CanvasTexture(canvas);
    tex.anisotropy = 4;
    return tex;
}

// ---------------------------------------------------------
// Concha 3D elegante
// ---------------------------------------------------------
function createSeashellGeometry(opts){
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
// Estrela do mar 3D delicada
// ---------------------------------------------------------
function createStarfishGeometry(scale){
    const shape = new THREE.Shape();
    const points = 5;
    const outer = 1.3;
    const inner = 0.35;
    const midOuter = 0.55;

    const path = [];
    for(let i = 0; i < points; i++){
        const baseAngle = (i / points) * Math.PI * 2 - Math.PI / 2;
        const nextAngle = ((i + 1) / points) * Math.PI * 2 - Math.PI / 2;

        const aInner1 = baseAngle - 0.42;
        path.push({ x: Math.cos(aInner1) * midOuter, y: Math.sin(aInner1) * midOuter });
        path.push({ x: Math.cos(baseAngle) * outer,  y: Math.sin(baseAngle) * outer  });
        const aInner2 = baseAngle + 0.42;
        path.push({ x: Math.cos(aInner2) * midOuter, y: Math.sin(aInner2) * midOuter });
        const aValley = (baseAngle + nextAngle) / 2;
        path.push({ x: Math.cos(aValley) * inner,    y: Math.sin(aValley) * inner    });
    }

    shape.moveTo(path[0].x, path[0].y);
    for(let i = 1; i < path.length; i++){
        shape.quadraticCurveTo(
            path[i-1].x * 1.05,
            path[i-1].y * 1.05,
            path[i].x,
            path[i].y
        );
    }
    shape.closePath();

    const geo = new THREE.ExtrudeGeometry(shape, {
        depth: 0.10,
        bevelEnabled: true,
        bevelSegments: 3,
        bevelSize: 0.06,
        bevelThickness: 0.04,
        curveSegments: 12
    });

    geo.center();
    geo.scale(scale, scale, scale);

    const pos = geo.attributes.position;
    const v = new THREE.Vector3();
    for(let i = 0; i < pos.count; i++){
        v.fromBufferAttribute(pos, i);
        const distFromCenter = Math.sqrt(v.x*v.x + v.y*v.y);
        const lift = Math.max(0, 0.18 - distFromCenter * 0.15);
        v.z += lift;
        pos.setXYZ(i, v.x, v.y, v.z);
    }
    geo.computeVertexNormals();
    return geo;
}

// ---------------------------------------------------------
// Paletas
// ---------------------------------------------------------
const shellPalette = [
    0xf5e0c3, 0xecd2b0, 0xe8c9a0, 0xf2dabb, 0xdfc19a,
    0xe6cea8, 0xd9b88f, 0xecd6b8, 0xd4b088, 0xe3c8a3
];
const shellAccentPalette = [
    0xa87c52, 0x9c6f45, 0xb08858, 0x8f6440, 0xa07850,
    0x96703f, 0x855c38, 0xa8804c, 0x7a5230, 0x9c7448
];
const starPalette = [
    0xf0b88a, 0xe8a878, 0xeab392, 0xdfa070, 0xeec2a0
];
const starAccentPalette = [
    0xb87648, 0xa86840, 0xcc8a58, 0x985c34, 0xc08858
];

// ---------------------------------------------------------
// Cria 40 conchas/estrelas caindo — concentradas no centro
// ---------------------------------------------------------
const fallingShells = [];
const SHELL_COUNT = 40;

for(let i = 0; i < SHELL_COUNT; i++){
    const isStar = Math.random() < 0.20;

    let geo, colorHex, accentHex, tex;

    if(isStar){
        geo = createStarfishGeometry(1);
        colorHex = starPalette[Math.floor(Math.random() * starPalette.length)];
        accentHex = starAccentPalette[Math.floor(Math.random() * starAccentPalette.length)];
        tex = makeStarTexture(colorHex, accentHex);
    } else {
        const h = 1.2 + Math.random() * 0.9;
        const r = 0.55 + Math.random() * 0.35;
        const twist = 0.8 + Math.random() * 1.2;
        const ribs = 10 + Math.floor(Math.random() * 8);
        geo = createSeashellGeometry({
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

    const s = 1.6 + Math.random() * 1.4;
    mesh.scale.setScalar(s);

    // CONCENTRADAS NO CENTRO
    mesh.position.set(
        (Math.random() - 0.5) * 36,
        20 - Math.random() * 160,
        -25 - Math.random() * 40
    );

    mesh.userData.velocityY = -(8 + Math.random() * 10);
    mesh.userData.rotSpeedX = (Math.random() - 0.5) * 0.9;
    mesh.userData.rotSpeedY = (Math.random() - 0.5) * 1.4;
    mesh.userData.rotSpeedZ = (Math.random() - 0.5) * 0.9;
    mesh.userData.swayAmp   = 0.2 + Math.random() * 0.8;
    mesh.userData.swayFreq  = 0.0006 + Math.random() * 0.0016;
    mesh.userData.swayPhase = Math.random() * Math.PI * 2;
    mesh.userData.baseX     = mesh.position.x;
    mesh.userData.baseZ     = mesh.position.z;
    mesh.userData.isStar    = isStar;

    shellGroup.add(mesh);
    fallingShells.push(mesh);
}

'''

# Localiza o bloco antigo das conchas e substitui
padrao = re.compile(
    r"/\* =+\s*\n\s*CONCHAS E ESTRELAS.*?\n\s*=+\s*\*/.*?(?=/\* =+\s*\n\s*MERGULHO)",
    re.DOTALL
)

if padrao.search(html):
    html = padrao.sub(novo_bloco + "\n", html, count=1)
    print("→ Bloco de conchas substituído com sucesso.")
else:
    print("ERRO: bloco de CONCHAS E ESTRELAS não encontrado.")
    raise SystemExit(1)

# =====================================================================
# 2) SUBSTITUI O BLOCO DE RECICLAGEM DENTRO DO diveLoop
# =====================================================================
bloco_reciclagem_novo = r'''        if(shell.position.y < camera.position.y - 40){
            shell.position.y = camera.position.y + 40 + Math.random() * 40;
            shell.position.x = (Math.random() - 0.5) * 36;
            shell.position.z = -25 - Math.random() * 40;
            ud.baseX = shell.position.x;
            ud.baseZ = shell.position.z;
            ud.velocityY = -(8 + Math.random() * 10);
            ud.swayPhase = Math.random() * Math.PI * 2;
            // regenera textura com nova cor
            if(shell.material && shell.material.map){
                const isStar = ud.isStar;
                const colPal = isStar ? starPalette : shellPalette;
                const accPal = isStar ? starAccentPalette : shellAccentPalette;
                const newCol = colPal[Math.floor(Math.random() * colPal.length)];
                const newAcc = accPal[Math.floor(Math.random() * accPal.length)];
                shell.material.map.dispose();
                shell.material.map = isStar
                    ? makeStarTexture(newCol, newAcc)
                    : makeShellTexture(newCol, newAcc);
                shell.material.needsUpdate = true;
            }
        }'''

# Localiza o bloco antigo de reciclagem (dentro do for das fallingShells)
padrao_rec = re.compile(
    r"if\(shell\.position\.y < camera\.position\.y - 40\)\{.*?\n        \}",
    re.DOTALL
)

if padrao_rec.search(html):
    html = padrao_rec.sub(bloco_reciclagem_novo, html, count=1)
    print("→ Bloco de reciclagem atualizado com sucesso.")
else:
    print("AVISO: bloco de reciclagem não encontrado. Pode já estar no formato novo.")

with open("index.html", "w", encoding="utf-8") as f:
    f.write(html)

print("\n✓ Patch aplicado! Abra o index.html no navegador.")
PYEOF

echo ""
echo "Pronto! Abra o index.html e toque na tela."
echo "Para reverter: mv index.html.bak_textura index.html"
