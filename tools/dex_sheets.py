"""Animal dictionary art (QM, Oct 3): each pet's run GIF (tools/pet_headshots.py, the
transparent PetX.gif) cut into sprite sheets Roblox can play, since an ImageLabel
can't play a GIF. 24 frames of 512 px become two 4 x 3 sheets of 256 px frames
(1024 x 768 each, under Roblox's 1024 px limit): DexX_1.png holds frames 1-12,
DexX_2.png frames 13-24. AnimalDex.luau steps through them.

Run: python3 tools/dex_sheets.py <gif_dir> <Kind> [<Kind> ...]
"""

import os
import sys

from PIL import Image

FRAME, COLS, ROWS = 256, 4, 3
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "ui", "dex")


def sheets(gif_dir, kind):
    gif = Image.open(os.path.join(gif_dir, f"Pet{kind}.gif"))
    frames = []
    for i in range(gif.n_frames):
        gif.seek(i)
        frames.append(gif.convert("RGBA").resize((FRAME, FRAME), Image.LANCZOS))
    per = COLS * ROWS
    for s in range(0, len(frames), per):
        sheet = Image.new("RGBA", (COLS * FRAME, ROWS * FRAME), (0, 0, 0, 0))
        for k, frame in enumerate(frames[s:s + per]):
            sheet.paste(frame, ((k % COLS) * FRAME, (k // COLS) * FRAME))
        sheet.save(os.path.join(OUT, f"Dex{kind}_{s // per + 1}.png"))
    return len(frames), gif.info.get("duration")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for kind in sys.argv[2:]:
        print(kind, sheets(sys.argv[1], kind))
