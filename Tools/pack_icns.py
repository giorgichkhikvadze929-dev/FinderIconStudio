from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
ICONSET = ROOT / "Assets" / "FinderIconStudio.iconset"
OUTPUT = ROOT / "Finder Icon Studio.app" / "Contents" / "Resources" / "FinderIconStudio.icns"

entries = [
    ("icp4", ICONSET / "icon_16x16.png"),
    ("icp5", ICONSET / "icon_32x32.png"),
    ("icp6", ICONSET / "icon_32x32@2x.png"),
    ("ic07", ICONSET / "icon_128x128.png"),
    ("ic08", ICONSET / "icon_256x256.png"),
    ("ic09", ICONSET / "icon_512x512.png"),
    ("ic10", ICONSET / "icon_512x512@2x.png"),
]

chunks = []
for code, path in entries:
    data = path.read_bytes()
    chunks.append(code.encode("ascii") + struct.pack(">I", len(data) + 8) + data)

blob = b"icns" + struct.pack(">I", 8 + sum(len(chunk) for chunk in chunks)) + b"".join(chunks)
OUTPUT.write_bytes(blob)
print(OUTPUT)
