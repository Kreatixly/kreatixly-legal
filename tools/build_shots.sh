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

# Gemeinsames Ziel: 468 x 804 (Verhaeltnis 1 : 1,718) fuer jedes Bild beider Apps.
# Kein Bild wird verzerrt und keines verliert Inhalt: LernSnap ist schmaler als
# das Ziel und wird seitlich mit seiner eigenen Randfarbe aufgefuellt.

edge_color() {  # $1 = Datei, $2 = x, $3 = y  ->  0xRRGGBB
  ffmpeg -loglevel error -i "$1" -vf "crop=1:1:$2:$3" -f rawvideo -pix_fmt rgb24 - \
    | od -An -tx1 | tr -d ' \n' | sed 's/^/0x/'
}

# --- LernSnap: 1080x2340, oben 110 weg (Statusleiste), unten 46 weg (Gestenleiste) ---
i=1
for n in 04 09 12; do
  src="$LS/cap_$n.png"
  col=$(edge_color "$src" 4 1200)
  ffmpeg -y -loglevel error -i "$src" \
    -vf "crop=1080:2184:0:110,pad=1272:2184:(ow-iw)/2:0:$col,scale=468:804" \
    -quality 82 "$OUT/LernSnap/shot_$i.webp"
  echo "LernSnap $n -> shot_$i.webp (Randfarbe $col)"
  i=$((i+1))
done

# --- Outli: 1080x1920, nur oben 64 weg. Die Mockups haben unten keine
#     Gestenleiste - dort stehen die Werkzeug-Beschriftungen. ---
i=1
for n in 03_templates 02_camera 04_gallery; do
  ffmpeg -y -loglevel error -i "$OU/$n.png" \
    -vf "crop=1080:1856:0:64,scale=468:804" \
    -quality 82 "$OUT/Outli/shot_$i.webp"
  echo "Outli $n -> shot_$i.webp"
  i=$((i+1))
done

echo "--- Ergebnis:"
for f in $OUT/LernSnap/shot_*.webp $OUT/Outli/shot_*.webp; do
  printf '%s  ' "$f"
  ffmpeg -hide_banner -i "$f" 2>&1 | grep -o "[0-9]*x[0-9]*" | head -1
done
