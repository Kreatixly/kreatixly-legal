# Baut die Favicons aus logo.png.
#
# Aufruf aus dem Repo-Wurzelverzeichnis:  python3 tools/build_favicon.py
# Braucht Pillow.
#
# logo.png hat dunkle, undurchsichtige Ecken. Fuer den Browser-Tab wird nur der
# runde Kreis ausgeschnitten (Rest transparent), damit auf hellen Tabs kein
# dunkles Quadrat erscheint. Das Apple-Touch-Icon bekommt dagegen einen vollen
# Hintergrund in der Website-Farbe, weil iOS Transparenz schwarz fuellt.
from PIL import Image, ImageDraw

SRC = "logo.png"
BOX = (3, 3, 353, 353)   # Kreis im Logo: x 3..352, y 4..351
BG = (26, 28, 32, 255)   # --bg der Website (#1a1c20)

logo = Image.open(SRC).convert("RGBA").crop(BOX)
n = logo.size[0]

# Kreismaske, 4-fach ueberabgetastet fuer glatte Kanten
ss = 4
mask = Image.new("L", (n * ss, n * ss), 0)
ImageDraw.Draw(mask).ellipse((0, 0, n * ss - 1, n * ss - 1), fill=255)
mask = mask.resize((n, n), Image.LANCZOS)
circle = logo.copy()
circle.putalpha(mask)

circle.save("favicon.ico", sizes=[(16, 16), (32, 32), (48, 48)])
circle.resize((192, 192), Image.LANCZOS).save("icon-192.png", optimize=True)

touch = Image.new("RGBA", (180, 180), BG)
inner = circle.resize((160, 160), Image.LANCZOS)
touch.alpha_composite(inner, (10, 10))
touch.convert("RGB").save("apple-touch-icon.png", optimize=True)

print("favicon.ico, icon-192.png, apple-touch-icon.png erstellt")
