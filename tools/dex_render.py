"""Pets book animations straight from each animal's .bbmodel (QM, Oct 4: the Godlands
animals had none): its run loop from the action headshot's camera
(pet_headshots.loop), at 192 px, 5 x 5 frames to a sheet like tools/dex_sheets.py.
Rendering the frames directly keeps their soft edges, where a GIF would cut them.

Run: python3 tools/dex_render.py <Kind> [<Kind> ...]
Prints each kind's AnimalDex SHEETS line (frames, frame time) to fill in once the
sheets are uploaded.
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import pet_headshots as P  # noqa: E402

FRAME, COLS, ROWS = 192, 5, 5
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "ui", "dex")


def main(kinds):
    os.makedirs(OUT, exist_ok=True)
    for kind in kinds:
        frames, ms = P.loop(kind)
        frames = [f.resize((FRAME, FRAME), Image.LANCZOS) for f in frames]
        per = COLS * ROWS
        names = []
        for s in range(0, len(frames), per):
            sheet = Image.new("RGBA", (COLS * FRAME, ROWS * FRAME), (0, 0, 0, 0))
            for k, frame in enumerate(frames[s:s + per]):
                sheet.paste(frame, ((k % COLS) * FRAME, (k // COLS) * FRAME))
            name = f"Dex{kind}_{s // per + 1}.png"
            sheet.save(os.path.join(OUT, name))
            names.append(name)
        print(kind, len(frames), "frames,", ms, "ms:", ", ".join(names))


if __name__ == "__main__":
    main(sys.argv[1:])
