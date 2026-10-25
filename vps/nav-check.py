# Read-only: lists which maps in mapcycle.txt have a bot navigation file (.nav),
# either loose in tf/maps or packed inside the game's *_dir.vpk files. Run on the VPS, prints one line per map.
import glob, os, struct

TF = "/home/tf2/server/tf"
packed = set()

def read_str(data, pos):
    end = data.index(b"\0", pos)
    return data[pos:end].decode("utf-8", "replace"), end + 1

for f in glob.glob(TF + "/*_dir.vpk") + glob.glob(TF + "/../hl2/*_dir.vpk"):
    try:
        data = open(f, "rb").read()
        sig, ver = struct.unpack_from("<II", data, 0)
        if sig != 0x55AA1234:
            continue
        pos = 12 if ver == 1 else 28
        while True:
            ext, pos = read_str(data, pos)
            if not ext:
                break
            while True:
                path, pos = read_str(data, pos)
                if not path:
                    break
                while True:
                    name, pos = read_str(data, pos)
                    if not name:
                        break
                    preload = struct.unpack_from("<H", data, pos + 4)[0]
                    pos += 18 + preload
                    if ext == "nav" and path == "maps":
                        packed.add(name)
    except Exception as e:
        print("could not read %s: %s" % (f, e))

for line in open(TF + "/cfg/mapcycle.txt"):
    m = line.strip()
    if not m or m.startswith("//"):
        continue
    if os.path.exists("%s/maps/%s.nav" % (TF, m)):
        print("%s  nav: yes (loose file)" % m)
    elif m in packed:
        print("%s  nav: yes (in game files)" % m)
    else:
        print("%s  nav: NO" % m)
print("packed navs found: %d" % len(packed))
