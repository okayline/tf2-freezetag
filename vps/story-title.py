#!/usr/bin/env python3
# Story titles: turns a player's Steam ID into a stable title like "the Quiet Wanderer",
# so the public stories can follow one player across rounds without ever naming them.
# The same Steam ID always gives the same title. The secret key makes it impossible to
# work backwards from a title to a Steam ID; it lives only on the server and is never printed.
#
# Use:  story-title.py STEAM_0:x:y   -> prints the title only
import hashlib, hmac, os, secrets, sys

KEY_FILE = "/etc/l4d-story/title.key"

ADJ = ["Quiet", "Restless", "Steady", "Lucky", "Iron", "Silent", "Wild", "Patient",
       "Last", "Lonely", "Brave", "Grim", "Swift", "Stubborn", "Gentle", "Hollow",
       "Burning", "Faithful", "Weary", "Sharp", "Wandering", "Careful", "Reckless", "Calm",
       "Midnight", "Rusty", "Bright", "Broken", "Golden", "Distant", "Fearless", "Lost"]
NOUN = ["Wanderer", "Watcher", "Drifter", "Stranger", "Hunter", "Medic", "Sentinel", "Runner",
        "Survivor", "Pilgrim", "Ghost", "Guardian", "Outlaw", "Scout", "Keeper", "Rider",
        "Mechanic", "Preacher", "Gambler", "Saint", "Traveler", "Sniper", "Shepherd", "Nomad",
        "Lantern", "Falcon", "Sparrow", "Wolf", "Raven", "Fox", "Anchor", "Ember"]


def key():
    if not os.path.exists(KEY_FILE):
        os.makedirs(os.path.dirname(KEY_FILE), mode=0o700, exist_ok=True)
        fd = os.open(KEY_FILE, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        os.write(fd, secrets.token_hex(32).encode())
        os.close(fd)
    return open(KEY_FILE, "rb").read().strip()


def title(steam_id):
    h = hmac.new(key(), steam_id.strip().encode(), hashlib.sha256).digest()
    return "the %s %s" % (ADJ[h[0] % len(ADJ)], NOUN[h[1] % len(NOUN)])


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("use: story-title.py STEAM_ID")
    print(title(sys.argv[1]))
