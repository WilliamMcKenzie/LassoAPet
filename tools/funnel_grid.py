"""Floor patches laid out as they'll show in game, after tools/funnel.luau has widened
the course (QM, Oct 11: quasicrystal patterns would come out stretched sideways if they
were drawn on the straight course and then widened).

The funnel maps a floor part's x edges with mapX at the part's middle z and snaps them
to the 8-stud cells. So a grid of 8-stud columns in game is written with each edge at
unmap(edge) on the straight course, and comes back out exactly on its cell edges. The
width changes along the course, so the floor is cut into bands (each its own columns,
from the width at its middle); no part crosses a band.
"""
import numpy as np

START, RATE, MAX = 56, 0.005, 137  # tools/funnel.luau (Config.CourseHalfWidth, CourseWidening, CourseMaxHalfWidth)
CELL = 8


def half_width(z):
    return min(START + RATE * max(-z, 0), MAX)


def map_x(x, z):
    h = half_width(z)
    return x * h / START if abs(x) <= START else x + np.sign(x) * (h - START)


def unmap_x(x, z):
    h = half_width(z)
    return x * START / h if abs(x) <= h else x - np.sign(x) * (h - START)


def snap(x):
    return int(np.floor(x / CELL + 0.5)) * CELL


class Band:
    """z0 > z1, rows of CELL studs from z0; columns of CELL studs across the game width."""

    def __init__(self, z0, z1):
        self.z0, self.z1 = z0, z1
        self.h = half_width((z0 + z1) / 2)
        self.edge = int(self.h // CELL) * CELL  # the floor's game edge, inside the wall (the funnel's floor fills any gap)
        self.nx, self.nz = 2 * self.edge // CELL, int(round((z0 - z1) / CELL))
        self.kind = np.zeros((self.nx, self.nz), int)

    def centres(self):
        """Game (x, z) of every cell's middle, as (nx, nz) arrays."""
        xs = -self.edge + CELL * np.arange(self.nx) + CELL / 2
        zs = self.z0 - CELL * np.arange(self.nz) - CELL / 2
        return np.meshgrid(xs, zs, indexing="ij")

    def pre(self, i):
        """Column edge i (0..nx) on the straight course."""
        e = -self.edge + CELL * i
        if abs(e) >= self.edge:
            return float(np.sign(e) * START)
        return round(e * START / self.h, 4)


class Grid:
    def __init__(self, z0, z1, band):
        """Bands of `band` studs from z0 down to z1."""
        self.z0, self.z1, self.band = z0, z1, band
        zs = list(range(z0, z1, -band)) + [z1]
        self.bands = [Band(a, b) for a, b in zip(zs, zs[1:]) if a > b]

    def at(self, x, z):
        """The kind under a point on the straight course (x before the funnel)."""
        if not (self.z1 < z <= self.z0):
            return 0
        b = self.bands[min(int((self.z0 - z) // self.band), len(self.bands) - 1)]
        X = map_x(x, z)
        i = min(max(int((X + b.edge) // CELL), 0), b.nx - 1)
        j = min(max(int((b.z0 - z) // CELL), 0), b.nz - 1)
        return int(b.kind[i, j])

    def boxes(self, names, tops, rects):
        """(name, centre, size) per part, on the straight course."""
        out = []
        for b in self.bands:
            for k, i0, j0, i1, j1 in rects(b.kind):
                top = tops[k]
                x0, x1 = b.pre(i0), b.pre(i1)
                z0, z1 = b.z0 - j0 * CELL, b.z0 - j1 * CELL
                out.append((names[k], (round((x0 + x1) / 2, 4), (top - 2) / 2, (z0 + z1) / 2),
                            (round(x1 - x0, 4), top + 2, z0 - z1)))
        return out
