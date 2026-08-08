#!/bin/sh
# Baut die Website-Screenshots: Statusleiste + Gestenleiste weg,
# alle Bilder auf ein gemeinsames Seitenverhaeltnis, ohne zu verzerren.
#
# Aufruf aus dem Repo-Wurzelverzeichnis:  sh tools/build_shots.sh
# Braucht ffmpeg und die Quell-Repos der Apps.
set -e
cd "$(dirname "$0")/.."
OUT=apps
LS=${LERNSNAP_REPO:-/d/3_Kreatixly/Apps/LernSnap}/demo_footage
OU=${OUTLI_REPO:-/d/2_Programmieren/Outli}/assets/screenshots/phone

# Gemeinsames Ziel: 468 x 946 fuer jedes Bild beider Apps. Das Verhaeltnis
# 1 : 2,02 ist das von LernSnap (echtes Geraet, 1080x2340). Outlis Mockups sind
# mit 1080x1920 deutlich breiter und werden oben/unten mit ihrer jeweiligen
# Randfarbe aufgefuellt - so wird kein Bild verzerrt und keines beschnitten.

edge_color() {  # $1 = Datei, $2 = x, $3 = y  ->  0xRRGGBB
  ffmpeg -loglevel error -i "$1" -vf "crop=1:1:$2:$3" -f rawvideo -pix_fmt rgb24 - \
    | od -An -tx1 | tr -d ' \n' | sed 's/^/0x/'
}

# --- LernSnap: 1080x2340, oben 110 weg (Statusleiste), unten 46 weg (Gestenleiste) ---
i=1
for n in 04 09 12; do
  ffmpeg -y -loglevel error -i "$LS/cap_$n.png" \
    -vf "crop=1080:2184:0:110,scale=468:946" \
    -quality 82 "$OUT/LernSnap/shot_$i.webp"
  echo "LernSnap $n -> shot_$i.webp"
  i=$((i+1))
done

# --- Outli: 1080x1920, nur oben 64 weg. Die Mockups haben unten keine
#     Gestenleiste - dort stehen die Werkzeug-Beschriftungen.
#     Danach 164 px oben und unten anfuellen, je in der Randfarbe der Seite. ---
i=1
for n in 03_templates 02_camera 04_gallery; do
  src="$OU/$n.png"
  top=$(edge_color "$src" 540 70)
  bot=$(edge_color "$src" 540 1915)
  ffmpeg -y -loglevel error -i "$src" \
    -vf "crop=1080:1856:0:64,pad=1080:2020:0:164:$top,pad=1080:2184:0:0:$bot,scale=468:946" \
    -quality 82 "$OUT/Outli/shot_$i.webp"
  echo "Outli $n -> shot_$i.webp (Rand oben $top, unten $bot)"
  i=$((i+1))
done

echo "--- Ergebnis:"
for f in $OUT/LernSnap/shot_*.webp $OUT/Outli/shot_*.webp; do
  printf '%s  ' "$f"
  ffmpeg -hide_banner -i "$f" 2>&1 | grep -o "[0-9]*x[0-9]*" | head -1
done
