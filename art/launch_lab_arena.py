"""Launch Lab world generator (Sky Islands): builds the level geometry in Blender and exports it as JMS, plus the layout
data the placements and level scripts are generated from.

Run headless (tools\\build.ps1 does this), or open Blender's Scripting tab and run it to inspect:
    blender --background --python art/launch_lab_arena.py -- <output .JMS path>   (needs the add-on enabled)
Outputs, next to the JMS's level folder (all generated, git-ignored; this script is their source):
    models\\launch_lab.JMS      the geometry
    world_layout.json          levels, islands, vehicles, scatter (trees/rocks), landing zones, flags (read by tools\\scenario.ps1)
    scripts\\world.hsc          generated level scripts: fall guard, checkpoints, per-level debug teleports

Halo rules this follows (c20 "My first box level", BSP troubleshooting, H1 materials):
- The level is a sealed world. Three kinds of geometry:
  * SHELL: one closed, inward-facing surface around the playable air (terrain, walls, ceiling, ramp, platform).
    Every edge borders exactly two shell faces, so all shell faces are cut on one shared grid (no T-junctions).
  * SOLIDS: separate closed shapes floating in the air (islands, bridges). Faces face OUTWARDS, into the air.
    c20: a BSP may be "one or multiple completely sealed volumes" (proven in task 10). Solids must not touch.
  * WATER: render-only surfaces ("!" symbol), which may have open edges (c20). Not part of the sealed check.
- Walls and ceiling use the special material "+sky": invisible but solid, so the world is sealed yet looks open.
- Material names are matched by Tool to stock shader tags by name (each name used here is unique in the stock tags).
- The geometry is parented to a node object named "frame". Units: 1 world unit (WU) = 100 Blender units.
- c20 limits: every vertex within +-1500 WU; precision artefacts from about 1000 WU from the origin; <=16k rendered
  triangles per cluster ("Couldn't allocate subcluster"), so the triangle budget is kept modest.
"""
import json
import math
import os
import random
import sys

import bmesh
import bpy

WU = 100.0  # Blender units per world unit

# ---- World frame ----------------------------------------------------------------------------------------------
HALF = 500.0           # 1000 x 1000 WU (about 3 km); precision-safe size (c20: artefacts from ~1000 WU)
CEILING = 1000.0       # as high as precision allows (no jitter at z 900 in task 10)
GRID_STEP = 25.0       # terrain / ceiling / wall grid (hills need resolution; keep render triangles modest)

# (The task 3 ramp and platform were removed in task 11: owner.)

# ---- Terrain (task 11: "hills, cliffs ... give it some character") ------------------------------------------------
FLAT_R = (50.0, 90.0)  # flat around the spawn out to 50 WU, blending to full terrain by 90 WU
EDGE_FLAT = 60.0       # terrain falls back to z 0 within this distance of the walls (so the walls stay simple)
HILLS = [  # (x, y, height, spread): smooth rounded hills
    (-180.0, 120.0, 28.0, 55.0), (-260.0, -160.0, 40.0, 70.0), (150.0, 260.0, 22.0, 45.0),
    (320.0, 60.0, 34.0, 60.0), (-60.0, -300.0, 18.0, 50.0), (60.0, -170.0, 12.0, 35.0),
]
MESAS = [  # (x, y, height, radius, edge width): flat-topped plateaus with steep cliff sides
    (260.0, -260.0, 32.0, 70.0, 8.0), (-300.0, 300.0, 45.0, 60.0, 10.0),
]

# ---- Sky Islands (task 11) --------------------------------------------------------------------------------------
# One entry per level: (level, height of the island tops, layout). Gaps between levels vary on purpose
# (owner: "the gap between levels should vary"). Layouts: solo, cluster2/cluster3 (islands linked by bridges),
# summit (the top, with a pool). Level 1 is lower than the old lowest island (owner).
LEVELS = [
    (1, 22.0, "solo"), (2, 48.0, "cluster2"), (3, 70.0, "solo"), (4, 110.0, "cluster3"), (5, 150.0, "solo"),
    (6, 215.0, "cluster2"), (7, 285.0, "pool"), (8, 360.0, "cluster3"), (9, 455.0, "solo"),
    (10, 565.0, "cluster2"), (11, 690.0, "solo"), (12, 820.0, "cluster2"), (13, 930.0, "summit"),
]
SUMMIT_R = 40.0        # the summit island's radius (the castle stands on its flat middle)
CASTLE_S = 13.0        # half the castle's width (square), centred on the summit
ISLAND_POINTS = 24     # points around an island's outline (smooth-shaded, so 24 reads as round)
WORLD_SEED = 2026

MAT_GROUND = "cell01_ground"        # levels\a30\shaders\cell01_ground (grass)
MAT_RAMP = "example_tutorial_plate_floor"
MAT_PLATFORM = "example_tutorial_metal_floor"
MAT_SKY = "+sky"
MAT_GRASS = "cell01_ground"
MAT_ROCK = "cliff rock"             # levels\a30\shaders\cliff rock
# The band under the grass edge used "c10 moss", but that shader is alpha_tested (see-through cut-outs): it showed as
# see-through patches around every island (task 11). Solid rock instead.
MAT_MOSS = MAT_ROCK
MAT_BRIDGE = "example_tutorial_metal_floor"
MAT_CASTLE_WALL = "example_tutorial_panels"      # levels\test\tutorial\shaders\ (Forerunner-style panels)
MAT_CASTLE_TOWER = "example_tutorial_metal"
MAT_CASTLE_FLOOR = "example_tutorial_metal_floor"
MAT_WATER = "water!"                # levels\b30\shaders\water; "!" = render-only
UV_TILE = 2.0  # world units per texture repeat


# ---- Terrain ----------------------------------------------------------------------------------------------------
def smoothstep(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)


def terrain_height(x, y):
    """Ground height at (x, y): hills and mesas, flat around the spawn and near the walls."""
    h = 0.0
    for hx, hy, hh, s in HILLS:
        h += hh * math.exp(-((x - hx) ** 2 + (y - hy) ** 2) / (2 * s * s))
    for mx, my, mh, mr, w in MESAS:
        d = math.hypot(x - mx, y - my)
        h = max(h, mh * smoothstep(mr + w, mr - w, d))
    h *= smoothstep(FLAT_R[0], FLAT_R[1], math.hypot(x, y))
    h *= smoothstep(0.0, EDGE_FLAT, HALF - max(abs(x), abs(y)))
    return h


def grid(lo, hi, extra):
    lines = set(extra)
    v = lo
    while v <= hi + 1e-9:
        lines.add(round(v, 6))
        v += GRID_STEP
    return sorted(lines)


X_CUTS = grid(-HALF, HALF, [])
Y_CUTS = grid(-HALF, HALF, [])


def in_rect(x0, x1, y0, y1, r):
    return x0 >= r["x0"] and x1 <= r["x1"] and y0 >= r["y0"] and y1 <= r["y1"]


def quad(x0, y0, x1, y1, z):
    return [(x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z)]


def sides(r, xs, ys, z_lo, z_hi, mat, faces):
    px = [x for x in xs if r["x0"] <= x <= r["x1"]]
    py = [y for y in ys if r["y0"] <= y <= r["y1"]]
    for a, b in zip(px, px[1:]):
        for y in (r["y0"], r["y1"]):
            faces.append(("shell", mat, [(a, y, z_lo), (b, y, z_lo), (b, y, z_hi), (a, y, z_hi)]))
    for a, b in zip(py, py[1:]):
        for x in (r["x0"], r["x1"]):
            faces.append(("shell", mat, [(x, a, z_lo), (x, b, z_lo), (x, b, z_hi), (x, a, z_hi)]))


def tri_material(pts):
    """Grass on gentle slopes, rock on steep ones (cliffs)."""
    (x0, y0, z0), (x1, y1, z1), (x2, y2, z2) = pts
    ux, uy, uz = x1 - x0, y1 - y0, z1 - z0
    vx, vy, vz = x2 - x0, y2 - y0, z2 - z0
    nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
    ln = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
    return MAT_ROCK if abs(nz) / ln < 0.75 else MAT_GROUND


def build_shell(faces, zones):
    xs, ys = X_CUTS, Y_CUTS
    for i in range(len(xs) - 1):
        for j in range(len(ys) - 1):
            x0, x1, y0, y1 = xs[i], xs[i + 1], ys[j], ys[j + 1]
            faces.append(("shell", MAT_SKY, quad(x0, y0, x1, y1, CEILING)))
            c = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
            p = [(x, y, terrain_height(x, y)) for x, y in c]
            if max(z for _, _, z in p) < 0.01:
                faces.append(("shell", MAT_GROUND, p))           # flat cell: one quad
                continue
            for tri in ([p[0], p[1], p[2]], [p[0], p[2], p[3]]):  # hilly cell: two triangles, one diagonal
                faces.append(("shell", tri_material(tri), tri))
            zones.add((i, j))     # hilly cell: covered by a tilted landing zone (see hill_zones)

    for i in range(len(xs) - 1):
        a, b = xs[i], xs[i + 1]
        for y in (-HALF, HALF):
            faces.append(("shell", MAT_SKY, [(a, y, 0.0), (b, y, 0.0), (b, y, CEILING), (a, y, CEILING)]))
    for j in range(len(ys) - 1):
        a, b = ys[j], ys[j + 1]
        for x in (-HALF, HALF):
            faces.append(("shell", MAT_SKY, [(x, a, 0.0), (x, b, 0.0), (x, b, CEILING), (x, a, CEILING)]))



HILL_BLOCK = 3          # hilly cells per side of one landing zone (3 x 25 = 75 WU)


def fit_plane(pts):
    """Least-squares plane z = a*x + b*y + c through pts (solves the 3 x 3 normal equations)."""
    sxx = sum(x * x for x, _, _ in pts); sxy = sum(x * y for x, y, _ in pts); sx = sum(x for x, _, _ in pts)
    syy = sum(y * y for _, y, _ in pts); sy = sum(y for _, y, _ in pts); n = float(len(pts))
    sxz = sum(x * z for x, _, z in pts); syz = sum(y * z for _, y, z in pts); sz = sum(z for _, _, z in pts)
    m = [[sxx, sxy, sx, sxz], [sxy, syy, sy, syz], [sx, sy, n, sz]]
    for c in range(3):                                         # Gauss-Jordan elimination with partial pivoting
        piv = max(range(c, 3), key=lambda r: abs(m[r][c]))
        m[c], m[piv] = m[piv], m[c]
        for r in range(3):
            if r != c:
                f = m[r][c] / m[c][c]
                m[r] = [a - f * b for a, b in zip(m[r], m[c])]
    return m[0][3] / m[0][0], m[1][3] / m[1][1], m[2][3] / m[2][2]


def hill_zones(hilly):
    """Landing zones over hilly ground, within the scenario's limit of 256 trigger volumes (Tool: "invalid element
    count: #397 not in [0,#256]", task 11). One zone per block of HILL_BLOCK x HILL_BLOCK cells, TILTED to the
    best-fit plane of the ground in that block (type 'rotational' volumes have their own forward/up axes), so it stays
    a thin slab just above the slope. Its thickness covers how far the ground departs from that plane, plus 1.5 WU
    above it. Axes: forward runs along x in the plane, up is the plane's normal, side = up x forward (+y, as the
    untilted zones use)."""
    blocks = {}
    for i, j in hilly:
        blocks.setdefault((i // HILL_BLOCK, j // HILL_BLOCK), set()).add((i, j))
    zones = []
    for (bi, bj) in sorted(blocks):
        i0, j0 = bi * HILL_BLOCK, bj * HILL_BLOCK
        i1, j1 = min(i0 + HILL_BLOCK, len(X_CUTS) - 1), min(j0 + HILL_BLOCK, len(Y_CUTS) - 1)
        x0, x1, y0, y1 = X_CUTS[i0], X_CUTS[i1], Y_CUTS[j0], Y_CUTS[j1]
        pts = [(x, y, terrain_height(x, y)) for x in X_CUTS[i0:i1 + 1] for y in Y_CUTS[j0:j1 + 1]]
        a, b, c = fit_plane(pts)
        dev = [z - (a * x + b * y + c) for x, y, z in pts]
        lo, hi = min(dev), max(dev)
        f = (1.0, 0.0, a)
        u = (-a, -b, 1.0)
        nf, nu = math.sqrt(sum(v * v for v in f)), math.sqrt(sum(v * v for v in u))
        f, u = tuple(v / nf for v in f), tuple(v / nu for v in u)
        sd = (u[1] * f[2] - u[2] * f[1], u[2] * f[0] - u[0] * f[2], u[0] * f[1] - u[1] * f[0])
        # Lengths along forward and side that span the block's x and y extents (with 1 WU of margin each way),
        # and a thickness from 1 WU below the lowest ground to 1.5 WU above the highest (measured along up).
        lf = (x1 - x0 + 2.0) / f[0]
        ls = (y1 - y0 + 2.0) / sd[1]
        thick = (hi - lo) * u[2] + 2.5
        ox, oy = x0 - 1.0, y0 - 1.0
        oz = a * ox + b * oy + c + lo * u[2] - 1.0
        zones.append(dict(name="hill_%d_%d" % (bi, bj), corner=[ox, oy, oz], size=[lf, ls, thick],
                          forward=list(f), up=list(u)))
    return zones


# ---- Islands --------------------------------------------------------------------------------------------------------
def natural_island(group, isl, faces, notches=()):
    """A floating rock: a bumpy grass top, a mossy overhang, and a blobby underside that rounds off at the bottom.

    Rings of points around the centre (same count per ring) joined by triangles: closed by construction. Shapes come
    from smooth noise (overlapping sine waves around the ring), so lobes and bulges are rounded. Returns metadata:
    the top-surface points (exact heights, for placing things), the grass edge ring and the highest top point.
    """
    rng = random.Random(isl["seed"])
    cx, cy, top, r, thick, pool = isl["cx"], isl["cy"], isl["top"], isl["r"], isl["thick"], isl["pool"]
    n = ISLAND_POINTS
    ang = [2 * math.pi * k / n for k in range(n)]

    def wave(amp, lobes=(2, 3, 5)):
        terms = [(f, rng.uniform(0, 2 * math.pi), rng.uniform(0.3, 1.0)) for f in lobes]
        total = sum(w for _, _, w in terms)
        return [amp * sum(w * math.sin(f * a + ph) for f, ph, w in terms) / total for a in ang]

    outline = wave(0.18)
    mound_dir = rng.uniform(0, 2 * math.pi)
    mound_h = rng.uniform(0.4, 0.9)       # kept low: a landing zone must reach 1.5 WU above the highest point

    def mound(k, s):
        d = abs((ang[k] - mound_dir + math.pi) % (2 * math.pi) - math.pi)
        return mound_h * math.exp(-(d / 0.8) ** 2) * math.sin(math.pi * min(s, 1.0))

    def ring(scale, heights, extra=None):
        pts = []
        for k, a in enumerate(ang):
            rr = r * (1 + outline[k]) * scale * (1 + (extra[k] if extra else 0.0))
            pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr, heights[k]))
        return pts

    bumps = [wave(0.2, (3, 4, 7)) for _ in range(3)]
    lip = wave(0.3, (3, 5, 8))

    # Landing notches where bridges arrive (task 11: bridge ends intersected the lumpy edge and the overhang, "z buffered
    # triangles"). Within ~25 degrees of a notch the grass edge is level with the top and the overhang tucks UNDER the
    # edge instead of sticking out, so a deck at top height can meet the island flush.
    def near_notch(k):
        return any(abs((ang[k] - a + math.pi) % (2 * math.pi) - math.pi) < math.radians(25) for a in notches)

    lip = [0.0 if near_notch(k) else l for k, l in enumerate(lip)]
    if pool:
        centre = (cx, cy, top - pool)
        top_rings = [ring(0.35, [top - pool * 0.7] * n),
                     ring(0.62, [top + 0.1 * b for b in bumps[0]]),
                     ring(0.82, [top + mound(k, 0.82) + bumps[1][k] for k in range(n)]),
                     ring(1.0, [top + l for l in lip])]
    elif isl.get("flat"):
        # Summit: a flat plaza out to 0.7 x the radius for the castle, then gentle rolls to the edge.
        centre = (cx, cy, top)
        top_rings = [ring(0.3, [top] * n), ring(0.7, [top] * n),
                     ring(0.85, [top + 0.5 * b for b in bumps[2]]),
                     ring(1.0, [top + l for l in lip])]
    else:
        centre = (cx, cy, top + 0.1)
        top_rings = [ring(0.3, [top + mound(k, 0.3) + 0.5 * bumps[0][k] for k in range(n)]),
                     ring(0.6, [top + mound(k, 0.6) + bumps[1][k] for k in range(n)]),
                     ring(0.82, [top + mound(k, 0.82) + bumps[2][k] for k in range(n)]),
                     ring(1.0, [top + l for l in lip])]

    oh_z = [top - thick * 0.08 + 0.3 * x for x in wave(1.0, (2, 4, 6))]
    oh_r = wave(0.05, (3, 5, 7))
    oh_z = [top - thick * 0.16 if near_notch(k) else z for k, z in enumerate(oh_z)]
    oh_r = [-0.07 if near_notch(k) else x for k, x in enumerate(oh_r)]      # 1.04 x (1 - 0.07) ~ 0.97: under the edge
    overhang = ring(1.04, oh_z, oh_r)
    under_shape = [(0.22, 1.0, 0.10), (0.40, 0.86, 0.14), (0.58, 0.68, 0.16), (0.74, 0.48, 0.16), (0.88, 0.28, 0.14)]
    under_rings = []
    for depth, scale, bulge in under_shape:
        dz = wave(thick * 0.04, (2, 3, 5))
        under_rings.append(ring(scale, [top - thick * depth + z for z in dz], wave(bulge, (2, 3, 4))))
    cap = (cx + rng.uniform(-0.08, 0.08) * r, cy + rng.uniform(-0.08, 0.08) * r, top - thick * 0.95)

    def fan(c, rg, mat):
        for k in range(n):
            faces.append((group, mat, [c, rg[k], rg[(k + 1) % n]]))

    def band(a, b, mat):
        for k in range(n):
            k2 = (k + 1) % n
            faces.append((group, mat, [a[k], b[k], b[k2]]))
            faces.append((group, mat, [a[k], b[k2], a[k2]]))

    fan(centre, top_rings[0], MAT_GRASS)
    for a, b in zip(top_rings, top_rings[1:]):
        band(a, b, MAT_GRASS)
    band(top_rings[-1], overhang, MAT_MOSS)
    band(overhang, under_rings[0], MAT_MOSS)
    for a, b in zip(under_rings, under_rings[1:]):
        band(a, b, MAT_ROCK)
    fan(cap, under_rings[-1], MAT_ROCK)

    if pool:
        # Water across the basin at 40% depth. Its edge must stay where the slope is still below the water line
        # (else "a surface clipped to no leaves", task 11): it meets the slope at scale 0.466, so use 0.45.
        wz = top - pool * 0.4
        faces.append(("water_%s" % group, MAT_WATER, ring(0.45, [wz] * n)))

    # Places to put things: points of the inner top rings (exact surface heights). Skip the basin if there's a pool.
    usable = top_rings[1:3] if pool else top_rings[0:2]
    spots = [p for rg in usable for p in rg]
    top_max = max(p[2] for rg in top_rings for p in rg)
    return dict(spots=spots, edge=top_rings[-1], top_max=top_max, centre_top=centre)


def bridge(group, a, b, faces):
    """A straight bridge deck between island edge points a and b: a closed box, 3 WU wide, 0.35 WU thick.
    It stops 0.15 WU short of each island so the solids never touch (they must not intersect)."""
    ax, ay, az = a
    bx, by, bz = b
    dx, dy = bx - ax, by - ay
    ln = math.hypot(dx, dy)
    ux, uy = dx / ln, dy / ln
    px, py = -uy * 1.5, ux * 1.5                       # half width, sideways
    ax, ay, bx, by = ax + ux * 0.1, ay + uy * 0.1, bx - ux * 0.1, by - uy * 0.1
    t = 0.3
    top = [(ax + px, ay + py, az), (ax - px, ay - py, az), (bx - px, by - py, bz), (bx + px, by + py, bz)]
    bot = [(x, y, z - t) for x, y, z in top]
    faces.append((group, MAT_BRIDGE, top))
    faces.append((group, MAT_BRIDGE, [bot[3], bot[2], bot[1], bot[0]]))
    for k in range(4):
        faces.append((group, MAT_BRIDGE, [bot[k], bot[(k + 1) % 4], top[(k + 1) % 4], top[k]]))
    return dict(a=[ax, ay, az], b=[bx, by, bz])


def box_solid(group, mat, x0, y0, z0, x1, y1, z1, faces, top_mat=None):
    """A closed axis-aligned box."""
    b = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]
    t = [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    faces.append((group, top_mat or mat, t))
    faces.append((group, mat, [b[3], b[2], b[1], b[0]]))
    for k in range(4):
        faces.append((group, mat, [b[k], b[(k + 1) % 4], t[(k + 1) % 4], t[k]]))


def prism_solid(group, mat, cx, cy, r, sides_n, z0, z1, faces, top_mat=None):
    """A closed upright prism (an octagonal tower for sides_n = 8)."""
    ring = [(cx + r * math.cos(2 * math.pi * k / sides_n + math.pi / sides_n),
             cy + r * math.sin(2 * math.pi * k / sides_n + math.pi / sides_n)) for k in range(sides_n)]
    faces.append((group, top_mat or mat, [(x, y, z1) for x, y in ring]))
    faces.append((group, mat, [(x, y, z0) for x, y in reversed(ring)]))
    for k in range(sides_n):
        (ax, ay), (bx, by) = ring[k], ring[(k + 1) % sides_n]
        faces.append((group, mat, [(ax, ay, z0), (bx, by, z0), (bx, by, z1), (ax, ay, z1)]))


def build_castle(cx, cy, top, faces):
    """A Forerunner-style castle on the summit's flat plaza (owner: "maybe a castle"): four curtain walls with a gate
    wide enough for a Warthog (south side), octagonal corner towers, a tall central keep, and a ramp up to the
    wall-walk. Every part is its own closed solid with small gaps between parts (solids must not touch), standing
    0.02 WU above the plaza. Returns the walkable tops (for landing zones) and the tower tops (for turrets)."""
    S, z0 = CASTLE_S, top + 0.02
    wall_h, wall_t, tower_r, tower_h, keep_h, gate = 8.0, 2.0, 3.0, 13.0, 26.0, 7.0
    tops = []
    e = S - tower_r - 0.2                                   # walls stop 0.2 short of the towers
    walls = [  # (x0, y0, x1, y1)
        (cx - e, cy + S - wall_t / 2, cx + e, cy + S + wall_t / 2),                  # north
        (cx + S - wall_t / 2, cy - e, cx + S + wall_t / 2, cy + e),                  # east
        (cx - S - wall_t / 2, cy - e, cx - S + wall_t / 2, cy + e),                  # west
        (cx - e, cy - S - wall_t / 2, cx - gate / 2, cy - S + wall_t / 2),           # south, left of the gate
        (cx + gate / 2, cy - S - wall_t / 2, cx + e, cy - S + wall_t / 2),           # south, right of the gate
    ]
    for k, (x0, y0, x1, y1) in enumerate(walls):
        box_solid("castle_wall_%d" % k, MAT_CASTLE_WALL, x0, y0, z0, x1, y1, z0 + wall_h, faces, MAT_CASTLE_FLOOR)
        tops.append((x0, y0, x1, y1, z0 + wall_h))
    towers = []
    for k, (sx, sy) in enumerate([(1, 1), (1, -1), (-1, 1), (-1, -1)]):
        tx, ty = cx + sx * S, cy + sy * S
        prism_solid("castle_tower_%d" % k, MAT_CASTLE_TOWER, tx, ty, tower_r, 8, z0, z0 + tower_h, faces, MAT_CASTLE_FLOOR)
        tops.append((tx - tower_r, ty - tower_r, tx + tower_r, ty + tower_r, z0 + tower_h))
        towers.append((tx, ty, z0 + tower_h))
    kh = 4.0                                                # the keep: 8 x 8, tall, in the middle of the courtyard
    box_solid("castle_keep", MAT_CASTLE_TOWER, cx - kh, cy - kh, z0, cx + kh, cy + kh, z0 + keep_h, faces, MAT_CASTLE_FLOOR)
    tops.append((cx - kh, cy - kh, cx + kh, cy + kh, z0 + keep_h))
    # Ramp up to the north wall-walk: a wedge along the inside of the north wall, 0.2 WU clear of it.
    ry1 = cy + S - wall_t / 2 - 0.2
    ry0 = ry1 - 3.0
    rx0, rx1 = cx - e + 0.5, cx - e + 0.5 + 18.0
    zt = z0 + wall_h
    low = [(rx0, ry0, z0), (rx1, ry0, z0), (rx1, ry1, z0), (rx0, ry1, z0)]
    faces.append(("castle_ramp", MAT_CASTLE_FLOOR, [low[3], low[2], low[1], low[0]]))                    # bottom
    faces.append(("castle_ramp", MAT_CASTLE_FLOOR, [(rx0, ry0, z0), (rx1, ry0, zt), (rx1, ry1, zt), (rx0, ry1, z0)]))  # slope
    faces.append(("castle_ramp", MAT_CASTLE_WALL, [(rx1, ry0, z0), (rx1, ry1, z0), (rx1, ry1, zt), (rx1, ry0, zt)]))  # high end
    faces.append(("castle_ramp", MAT_CASTLE_WALL, [(rx0, ry0, z0), (rx1, ry0, z0), (rx1, ry0, zt)]))      # side
    faces.append(("castle_ramp", MAT_CASTLE_WALL, [(rx0, ry1, z0), (rx1, ry1, zt), (rx1, ry1, z0)]))      # side
    tops.append((rx0, ry0, rx1, ry1, zt))
    return tops, towers, (cx, cy - S - 6.0, z0)            # walkable tops, tower tops, the gate approach


def edge_point_towards(meta, tx, ty, top):
    """Where a bridge leaves an island towards (tx, ty): past the furthest edge point within the notch (measured
    along the bridge direction, so no part of the outline sticks out beyond the deck's end), at the island's top
    height (the notch makes the edge level there)."""
    cx, cy = meta["centre_top"][0], meta["centre_top"][1]
    want = math.atan2(ty - cy, tx - cx)
    ux, uy = math.cos(want), math.sin(want)
    reach = 0.0
    for x, y, _ in meta["edge"]:
        a = math.atan2(y - cy, x - cx)
        if abs((a - want + math.pi) % (2 * math.pi) - math.pi) < math.radians(30):
            reach = max(reach, (x - cx) * ux + (y - cy) * uy)
    return (cx + ux * reach, cy + uy * reach, top)


def build_islands(faces, layout):
    rng = random.Random(WORLD_SEED)
    angle = rng.uniform(0, 2 * math.pi)
    for level, z, kind in LEVELS:
        # The climb spirals around the world, moving outwards as it rises.
        angle += rng.uniform(0.7, 1.3)
        dist = 70.0 + 220.0 * (level / len(LEVELS)) + rng.uniform(-20, 20)
        lx, ly = math.cos(angle) * dist, math.sin(angle) * dist
        count = {"solo": 1, "pool": 1, "cluster2": 2, "cluster3": 3, "summit": 1}[kind]
        plans = []
        for m in range(count):
            if m == 0:
                cx, cy, tz = lx, ly, z
            else:
                a2 = angle + rng.uniform(1.2, 2.2) * (1 if m == 1 else -1)
                gap = rng.uniform(32, 42)
                cx, cy, tz = lx + math.cos(a2) * gap, ly + math.sin(a2) * gap, z + rng.uniform(-4, 4)
            # Summit: much bigger, for the castle (owner: "much bigger and have some really cool stuff on it").
            r = SUMMIT_R if kind == "summit" else 16.0 if kind == "pool" else (rng.uniform(12, 15) if m == 0 else rng.uniform(8, 11))
            # The underside must stay clear of the ground below it (solids must not touch): sample the terrain under
            # the island's footprint and keep the tip at least 3 WU above the highest point.
            ground = max(terrain_height(cx + math.cos(t) * rr, cy + math.sin(t) * rr)
                         for rr in (0.0, r * 0.5, r * 1.2) for t in [i * math.pi / 6 for i in range(12)])
            thick = min(r * (0.9 if kind == "summit" else rng.uniform(1.2, 1.6)), tz - ground - 3.0)
            if thick < 5.0:
                raise RuntimeError("level %d island %d is too close to the ground (top %.1f, ground %.1f)" % (level, m, tz, ground))
            plans.append(dict(cx=cx, cy=cy, top=tz, r=r, thick=thick, seed=level * 10 + m,
                              pool=1.6 if kind == "pool" else 0.0, flat=kind == "summit"))
        # Bridges run from the main island (0) to each other island: notch both ends.
        notches = [[] for _ in plans]
        for m in range(1, count):
            a = math.atan2(plans[m]["cy"] - plans[0]["cy"], plans[m]["cx"] - plans[0]["cx"])
            notches[0].append(a)
            notches[m].append(a + math.pi)
        islands = []
        for m, isl in enumerate(plans):
            group = "island_%d_%d" % (level, m)
            meta = natural_island(group, isl, faces, notches[m])
            islands.append(dict(group=group, isl=isl, meta=meta))
        bridges = []
        for m in range(1, count):
            i0, i1 = islands[0], islands[m]
            a = edge_point_towards(i0["meta"], i1["isl"]["cx"], i1["isl"]["cy"], i0["isl"]["top"])
            b = edge_point_towards(i1["meta"], i0["isl"]["cx"], i0["isl"]["cy"], i1["isl"]["top"])
            bridges.append(bridge("bridge_%d_%d" % (level, m), a, b, faces))

        castle = None
        if kind == "summit":
            c = plans[0]
            tops, towers, gate = build_castle(c["cx"], c["cy"], c["top"], faces)
            castle = dict(tops=tops, towers=towers, gate=gate, centre=[c["cx"], c["cy"], c["top"]], half=CASTLE_S)

        # Layout for placements and scripts.
        lv = dict(level=level, kind=kind, islands=[], bridges=bridges, castle=castle)
        for k, it in enumerate(islands):
            isl, meta = it["isl"], it["meta"]
            pad = isl["r"] * 1.3
            lo = isl["top"] - 1.5
            zone = dict(name="level_%d_zone_%d" % (level, k), corner=[isl["cx"] - pad, isl["cy"] - pad, lo],
                        size=[2 * pad, 2 * pad, meta["top_max"] + 1.5 - lo])
            lv["islands"].append(dict(centre=[isl["cx"], isl["cy"], isl["top"]], r=isl["r"], zone=zone,
                                      spots=[list(p) for p in meta["spots"]]))
        for k, br in enumerate(bridges):
            xs_ = [br["a"][0], br["b"][0]]
            ys_ = [br["a"][1], br["b"][1]]
            zs_ = [br["a"][2], br["b"][2]]
            lv.setdefault("bridge_zones", []).append(dict(
                name="level_%d_bridge_zone_%d" % (level, k + 1),
                corner=[min(xs_) - 2.0, min(ys_) - 2.0, min(zs_) - 1.0],
                size=[max(xs_) - min(xs_) + 4.0, max(ys_) - min(ys_) + 4.0, max(zs_) - min(zs_) + 2.5]))
        if castle:
            for k, (x0, y0, x1, y1, zt) in enumerate(castle["tops"]):
                lv.setdefault("bridge_zones", []).append(dict(name="level_%d_castle_zone_%d" % (level, k),
                                                              corner=[x0 - 0.5, y0 - 0.5, zt - 1.0], size=[x1 - x0 + 1.0, y1 - y0 + 1.0, 2.5]))
        layout["levels"].append(lv)


# ---- Layout, placements and scripts --------------------------------------------------------------------------------
SCATTER_ISLAND = ["tree_leafy", "tree_gnarled", "tree_dense", "pine", "boulder_moss", "boulder_moss", "fern",
                  "broadleaf", "yellowbig", "trunk"]
SCATTER_GROUND = ["tree_leafy", "tree_gnarled", "tree_dense", "pine", "pine", "boulder_moss_large", "boulder_granite",
                  "boulder", "fern", "broadleaf"]


def plan_placements(layout):
    """A vehicle on every island (owner), trees and rocks on islands and the ground. Nothing is placed within
    CLEAR of a vehicle or within SPACING of another item (task 11: a turret appeared inside a tree)."""
    CLEAR, SPACING = 5.0, 3.0
    rng = random.Random(WORLD_SEED + 1)
    scatter, vehicles, taken = [], [], []

    def free(p, d):
        return all(math.hypot(p[0] - q[0], p[1] - q[1]) >= d or abs(p[2] - q[2]) > 6 for q in taken)

    for lv in layout["levels"]:
        castle = lv.get("castle")
        for k, isl in enumerate(lv["islands"]):
            cx, cy = isl["centre"][0], isl["centre"][1]
            spots = list(isl["spots"])
            if castle:   # keep the castle's footprint clear
                spots = [p for p in spots if max(abs(p[0] - cx), abs(p[1] - cy)) > castle["half"] + 4.0]
            rng.shuffle(spots)
            # Warthogs on the bigger islands (alternating), Covenant gun turrets ("Shades") on the rest.
            kind = "warthog" if (isl["r"] >= 12 and (lv["level"] + k) % 2 == 1) else "turret"
            if castle:
                kind = "warthog"
                vx, vy, vz = castle["gate"]
            else:
                vx, vy, vz = spots.pop()
            vehicles.append(dict(level=lv["level"], kind=kind,
                                 position=[vx, vy, vz + (0.5 if kind == "warthog" else 0.1)],
                                 yaw=math.degrees(math.atan2(vy - cy, vx - cx)) + 90.0))
            taken.append((vx, vy, vz, CLEAR))
            want = max(4, int(isl["r"] * 0.7))
            for p in spots:
                if want == 0:
                    break
                if all(math.hypot(p[0] - q[0], p[1] - q[1]) >= max(q[3], SPACING) or abs(p[2] - q[2]) > 6 for q in taken):
                    scatter.append(dict(kind=rng.choice(SCATTER_ISLAND), position=list(p)))
                    taken.append((p[0], p[1], p[2], SPACING))
                    want -= 1
        if castle:   # turrets on two tower tops
            for tx, ty, tz in castle["towers"][:2]:
                vehicles.append(dict(level=lv["level"], kind="turret", position=[tx, ty, tz + 0.1], yaw=0.0))
    # The ground: trees in groves and rocks, away from the spawn area.
    placed = 0
    while placed < 140:
        x, y = rng.uniform(-440, 440), rng.uniform(-440, 440)
        if math.hypot(x, y) < 70:
            continue
        p = (x, y, terrain_height(x, y))
        if all(math.hypot(p[0] - q[0], p[1] - q[1]) >= max(q[3], SPACING) or abs(p[2] - q[2]) > 6 for q in taken):
            scatter.append(dict(kind=rng.choice(SCATTER_GROUND), position=list(p)))
            taken.append((p[0], p[1], p[2], SPACING))
            placed += 1
    layout["vehicles"] = vehicles
    layout["scatter"] = scatter


def write_scripts(layout, path):
    """Generated HaloScript (compiled by Tool with launch_lab.hsc): fall guard over every landing surface,
    checkpoints per level, and per-level debug teleports. Functions confirmed with `tool script-doc`:
    volume_test_objects, players, object_can_take_damage, object_cannot_take_damage, game_save, object_teleport, print.
    (player0) is defined in the stock data\\global_scripts.hsc."""
    zones = [z["name"] for z in layout["landing_zones"]]

    def any_in(names):
        # (or ...) over many volume tests, nested in groups of 8 to keep each form short.
        tests = ["(volume_test_objects %s (players))" % n for n in names]
        while len(tests) > 1:
            tests = ["(or %s)" % " ".join(tests[i:i + 8]) for i in range(0, len(tests), 8)]
        return tests[0]

    out = ["; GENERATED by art/launch_lab_arena.py from world_layout.json. Do not edit: edit the generator.", ""]
    out += ["; ---- Fall guard (task 11): no mid-air fall death, impact deaths stay ------------------------------------",
            "; The engine 'remembers' a fall death while damage is blocked and applies it as soon as damage is back on;",
            "; landing zones (a slab ending ~1.5 WU above every surface) are where damage comes back, so you die at the",
            "; ground. The stock globals tag (maximum_falling_distance 16.5 WU) is not edited (ADR 0002).",
            "(script continuous fall_guard",
            "\t(if %s" % any_in(zones),
            "\t\t(object_can_take_damage (players))",
            "\t\t(object_cannot_take_damage (players))",
            "\t)", ")", ""]
    out += ["; ---- Checkpoints (task 11): reaching a new level saves the game; dying returns you there ---------------",
            "(global short highest_level 0)", "", "(script continuous checkpoints"]
    for lv in layout["levels"]:
        names = [isl["zone"]["name"] for isl in lv["islands"]]
        out += ["\t(if (and (< highest_level %d) %s)" % (lv["level"], any_in(names)),
                "\t\t(begin (set highest_level %d) (game_save) (print \"checkpoint: level %d\")))" % (lv["level"], lv["level"])]
    out += [")", ""]
    out += ["; ---- Checkpoint on demand (task 11, owner): switching the flashlight ON saves the game ------------------",
            "; There is no flashlight button test, but unit_get_current_flashlight_state exists (tool script-doc): save on",
            "; the off -> on change. game_save only saves when it is safe (e.g. not mid-fall), so it waits until you land.",
            "(global boolean flashlight_was_on false)", "",
            "(script continuous manual_checkpoint",
            "\t(if (and (unit_get_current_flashlight_state (player0)) (not flashlight_was_on))",
            "\t\t(begin (game_save) (print \"checkpoint saved\")))",
            "\t(set flashlight_was_on (unit_get_current_flashlight_state (player0)))",
            ")", ""]
    out += ["; ---- Debug teleports (dbg_, remove before release): (dbg_tp_level_5) puts you on level 5 -----------"]
    for lv in layout["levels"]:
        out += ["(script static void dbg_tp_level_%d" % lv["level"],
                "\t(object_teleport (player0) level_%d_flag)" % lv["level"], ")"]
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\r\n") as f:
        f.write("\n".join(out) + "\n")
    print("LAUNCHLAB wrote %s" % path)


# ---- Mesh assembly --------------------------------------------------------------------------------------------------
def get_material(name):
    return bpy.data.materials.get(name) or bpy.data.materials.new(name)


def build_scene(level_dir):
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)

    faces, hilly = [], set()
    layout = dict(levels=[])
    build_shell(faces, hilly)
    hill_zone_list = hill_zones(hilly)
    build_islands(faces, layout)
    plan_placements(layout)

    # Landing zones for the fall guard: flat ground, ramp, platform, hilly cells, every island and bridge.
    layout["landing_zones"] = [
        dict(name="ground_zone", corner=[-HALF, -HALF, -3.0], size=[2 * HALF, 2 * HALF, 4.5]),
    ] + hill_zone_list
    for lv in layout["levels"]:
        layout["landing_zones"] += [isl["zone"] for isl in lv["islands"]] + lv.get("bridge_zones", [])
    if len(layout["landing_zones"]) > 240:   # Tool's limit is 256 trigger volumes; keep room for portals
        raise RuntimeError("%d landing zones: over the budget of 240 (scenario limit 256)" % len(layout["landing_zones"]))
    layout["flags"] = [dict(name="level_%d_flag" % lv["level"],
                            position=[lv["islands"][0]["centre"][0], lv["islands"][0]["centre"][1],
                                      lv["islands"][0]["centre"][2] + 1.5]) for lv in layout["levels"]]

    mat_names = []
    for _, name, _ in faces:
        if name not in mat_names:
            mat_names.append(name)
    mesh = bpy.data.meshes.new("launch_lab_level")
    for name in mat_names:
        mesh.materials.append(get_material(name))

    bm = bmesh.new()
    verts = {}

    def vert(group, p):
        key = (group,) + tuple(round(c * WU, 4) for c in p)
        if key not in verts:
            verts[key] = bm.verts.new(tuple(round(c * WU, 4) for c in p))
        return verts[key]

    groups = {}
    for group, name, pts in faces:
        f = bm.faces.new([vert(group, p) for p in pts])
        f.material_index = mat_names.index(name)
        groups.setdefault(group, []).append(f)

    for group, gfaces in groups.items():
        if group.startswith("water"):
            continue
        edges = {e for f in gfaces for e in f.edges}
        bad = [e for e in edges if len(e.link_faces) != 2]
        if bad:
            raise RuntimeError("%s is not sealed: %d edges don't have exactly two faces" % (group, len(bad)))

    # Orientation: the shell encloses the air (flip to face inwards); solids enclose rock or metal (recalc already
    # points them outwards, into the air); water faces up.
    for group, gfaces in groups.items():
        if group.startswith("water"):
            for f in gfaces:
                if f.normal.z < 0:
                    f.normal_flip()
            continue
        bmesh.ops.recalc_face_normals(bm, faces=gfaces)
        if group == "shell":
            for f in gfaces:
                f.normal_flip()

    # Shading: the built parts (walls, ramp, platform, bridges) keep crisp creases; terrain and islands are smooth.
    crisp = set()
    for group, gfaces in groups.items():
        if group.startswith("bridge") or group.startswith("castle"):
            crisp.update(gfaces)
    crisp.update(f for f in groups.get("shell", []) if mat_names[f.material_index] in (MAT_SKY, MAT_RAMP, MAT_PLATFORM))
    for f in bm.faces:
        f.smooth = f not in crisp
    for e in bm.edges:
        lf = e.link_faces
        if len(lf) == 2 and (lf[0] in crisp or lf[1] in crisp) and lf[0].normal.angle(lf[1].normal) > 0.01:
            e.smooth = False

    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        n = f.normal
        ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
        for loop in f.loops:
            x, y, z = (c / WU / UV_TILE for c in loop.vert.co)
            if az >= ax and az >= ay:
                loop[uv].uv = (x, y)
            elif ax >= ay:
                loop[uv].uv = (y, z)
            else:
                loop[uv].uv = (x, z)

    bm.to_mesh(mesh)
    bm.free()
    level = bpy.data.objects.new("launch_lab_level", mesh)
    bpy.context.scene.collection.objects.link(level)
    frame = bpy.data.objects.new("frame", bpy.data.meshes.new("frame"))
    bpy.context.scene.collection.objects.link(frame)
    level.parent = frame

    print("LAUNCHLAB built %d faces in %d groups, %d levels, %d landing zones, %d scatter, %d vehicles; materials: %s" % (
        len(faces), len(groups), len(layout["levels"]), len(layout["landing_zones"]), len(layout["scatter"]),
        len(layout["vehicles"]), ", ".join(mat_names)))

    with open(os.path.join(level_dir, "world_layout.json"), "w", encoding="utf-8") as f:
        json.dump(layout, f, indent=1)
    write_scripts(layout, os.path.join(level_dir, "scripts", "world.hsc"))


def export(path):
    bpy.ops.export_scene.jms(
        filepath=path, check_existing=False, game_title="halo1",
        folder_structure=False,   # c20: "Generate Asset Subdirectories" disabled
        apply_modifiers=True, triangulate_faces=True, edge_split=True, use_edge_sharp=True, use_edge_angle=False,
        write_textures=False,     # keeps local file paths out of the JMS
    )
    print("LAUNCHLAB exported %s" % path)


if __name__ == "__main__":
    jms = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv and len(sys.argv) > sys.argv.index("--") + 1 else None
    level_dir = os.path.dirname(os.path.dirname(jms)) if jms else os.path.join(os.getcwd(), "out")
    build_scene(level_dir)
    if jms:
        export(jms)
