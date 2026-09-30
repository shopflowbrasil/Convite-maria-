#!/bin/bash
# =====================================================================
# PATCH — arruma o círculo da foto + posição do laço
# =====================================================================

FILE="index.html"

if [ ! -f "$FILE" ]; then
  echo "ERRO: $FILE não encontrado."
  exit 1
fi

cp "$FILE" "${FILE}.bak_foto"
echo "Backup criado: ${FILE}.bak_foto"

python3 - << 'PYEOF'
import re

with open("index.html", "r", encoding="utf-8") as f:
    html = f.read()

# ---------------------------------------------------------------------
# 1) SIMPLIFICA O CÍRCULO — remove o anel branco extra e suaviza a sombra
# ---------------------------------------------------------------------
html = html.replace(
""".photo-border{
    position:absolute; inset:0; border-radius:50%;
    border: 2px solid #c9a14a;
    box-shadow: 0 0 0 5px #fff, 0 0 0 7px rgba(201,161,74,.55), 0 12px 25px rgba(20,80,120,.15);
}
.photo{
    position:relative; z-index:2; width:178px; height:178px;
    object-fit:cover; border-radius:50%; border: 4px solid white;
}""",
""".photo-border{
    position:absolute; inset:0; border-radius:50%;
    border: 2px solid #c9a14a;
    box-shadow: 0 0 0 6px #ffffff, 0 8px 22px rgba(20,80,120,.18);
}
.photo{
    position:relative; z-index:2; width:186px; height:186px;
    object-fit:cover; border-radius:50%; border: 3px solid #ffffff;
    box-shadow: 0 4px 14px rgba(20,80,120,.12);
}"""
)

# ---------------------------------------------------------------------
# 2) REPOSICIONA O LAÇO — agora fica TOTALMENTE dentro do círculo,
#    encostado na borda superior direita, sem vazar
# ---------------------------------------------------------------------
html = html.replace(
""".bow{
    position:absolute;
    z-index:5;
    right:-38px;
    top:-16px;
    width:110px;
    height:96px;
    transform: rotate(14deg);
    transform-origin: 50% 40%;
    filter: drop-shadow(0 5px 7px rgba(20,60,100,.35));
    pointer-events:none;
}""",
""".bow{
    position:absolute;
    z-index:5;
    right:6px;
    top:4px;
    width:78px;
    height:68px;
    transform: rotate(18deg);
    transform-origin: 50% 55%;
    filter: drop-shadow(0 3px 5px rgba(20,60,100,.30));
    pointer-events:none;
}"""
)

# ---------------------------------------------------------------------
# 3) Ajusta também a versão mobile do laço
# ---------------------------------------------------------------------
html = html.replace(
"    .bow{ width:100px; height:88px; right:-34px; top:-14px; }",
"    .bow{ width:68px; height:60px; right:4px; top:2px; }"
)
html = html.replace(
"    .bow{ width:92px; height:82px; right:-30px; top:-12px; }",
"    .bow{ width:62px; height:54px; right:2px; top:0px; }"
)

# ---------------------------------------------------------------------
# 4) Ajusta o tamanho do círculo em mobile para caber bem
# ---------------------------------------------------------------------
html = html.replace(
"    .photo-wrap{ width:195px; height:195px; }\n    .photo{ width:165px; height:165px; }",
"    .photo-wrap{ width:190px; height:190px; }\n    .photo{ width:172px; height:172px; }"
)
html = html.replace(
"    .photo-wrap{ width:180px; height:180px; }\n    .photo{ width:151px; height:151px; }",
"    .photo-wrap{ width:176px; height:176px; }\n    .photo{ width:158px; height:158px; }"
)

with open("index.html", "w", encoding="utf-8") as f:
    f.write(html)

print("✓ Patch da foto/laço aplicado!")
PYEOF

echo ""
echo "Pronto! Recarregue o index.html (Ctrl+F5 ou Cmd+Shift+R)."
echo "Para reverter: mv index.html.bak_foto index.html"
