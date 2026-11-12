"""One lineup image of the Halloween animals next to the Horse, for review.

Run: python3 tools/halloween_lineup.py  ->  /mnt/project-files/halloween/animals/renders/HauntedHills_lineup.png
"""

import os

from PIL import Image

import garden_lineup as GL
import halloween_lib as H

ROWS = [[("Horse (for size)", None), ("Black Cat - Common", "halloween/BlackCat"), ("Bat - Uncommon", "halloween/Bat"),
         ("Pumpkin Pup - Uncommon", "halloween/PumpkinPup"), ("Purple Tarantula - Rare", "halloween/PurpleTarantula"),
         ("Werewolf - Epic", "halloween/Werewolf"), ("Soul Horse - Legendary", "godlands/SoulHorse")],
        [("Horse (for size)", None), ("Ghost - Common", "halloween/Ghost"), ("Skeleton Dog - Uncommon", "halloween/SkeletonDog"),
         ("Tombstone Crawler - Uncommon", "halloween/TombstoneCrawler"), ("Zombie Bear - Rare", "halloween/ZombieBear"),
         ("Wisp Wolf - Epic", "halloween/WispWolf"), ("Grim Reaper - Legendary", "halloween/GrimReaper")]]
NAMES = ["HauntedHills", "SoulValley"]


def main():
    for name, items in zip(NAMES, ROWS):
        r = GL.row(items, 340, 360, 52, 7)
        path = os.path.join(H.OUT, "renders", name + "_lineup.png")
        r.save(path)
        print(path, r.size)


if __name__ == "__main__":
    main()
