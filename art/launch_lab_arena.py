"""Launch Lab arena: builds the level geometry in Blender and exports it as JMS.

Geometry as code: run headless (tools\\build.ps1 does this), or open Blender's Scripting tab and run it to inspect.
    blender --background --python art/launch_lab_arena.py -- <output .JMS path>   (needs the add-on enabled)

Halo rules this follows (c20 "My first box level", BSP troubleshooting, H1 materials):
- The level is a sealed world. Three kinds of geometry:
  * SHELL: one closed, inward-facing surface around the playable air (floor, walls, ceiling, ramp, platform, pool).
    Every edge borders exactly two shell faces, so all shell faces are cut on one shared grid (no T-junctions).
  * ISLANDS (task 10): separate closed solids floating in the air. c20: a BSP may be "one or multiple completely
    sealed volumes". Their faces must face OUTWARDS (into the air, the playable side), the opposite of the shell.
  * WATER: render-only surfaces ("!" symbol), which may have open edges (c20). Not part of the sealed check.
- Walls and ceiling use the special material "+sky": invisible but solid, so the world is sealed yet looks open.
- Material names are matched by Tool to stock shader tags by name (each name used here is unique in the stock tags).
- The geometry is parented to a node object named "frame". Units: 1 world unit (WU) = 100 Blender units.
- c20 limits: every vertex within +-1500 WU; precision artefacts from about 1000 WU from the origin.
"""
import sys

import bmesh
import bpy

WU = 100.0  # Blender units per world unit

# ---- Layout in world units. Origin at the arena centre, floor at z = 0 ----------------------------------
HALF = 500.0           # task 10: 1000 x 1000 WU (about 3 km); precision-safe size (c20: artefacts from ~1000 WU)
CEILING = 1000.0       # task 10: height test, as high as precision allows
GRID_STEP = 50.0       # floor/ceiling/wall grid, so no face is huge (lightmap pages, precision)

RAMP = dict(x0=-3.0, x1=3.0, y0=-12.0, y1=0.0, top=3.0)          # rises towards +y
PLATFORM = dict(x0=-5.0, x1=5.0, y0=8.0, y1=16.0, top=4.0)       # landing target beyond the ramp
POOL = dict(x0=10.0, x1=20.0, y0=-30.0, y1=-20.0, depth=2.0, water=-0.3)   # sunken pool (task 10)

# Floating islands (task 10): a frustum of rock with a grass top; top half-size a, bottom half-size b.
ISLANDS = [
    dict(name="island_low", cx=0.0, cy=40.0, top=40.0, a=10.0, b=4.0, thick=12.0),   # reachable by a big launch
    dict(name="island_top", cx=0.0, cy=70.0, top=900.0, a=8.0, b=3.0, thick=10.0),   # height test, near the ceiling
]

MAT_FLOOR = "example_tutorial_ground"
MAT_RAMP = "example_tutorial_plate_floor"
MAT_PLATFORM = "example_tutorial_metal_floor"
MAT_SKY = "+sky"
MAT_GRASS = "cell01_ground"     # levels\a30\shaders\cell01_ground (unique name)
MAT_ROCK = "cliff rock"         # levels\a30\shaders\cliff rock (unique name)
MAT_WATER = "water!"            # levels\b30\shaders\water (unique name); "!" = render-only
UV_TILE = 2.0  # world units per texture repeat


def grid(lo, hi, extra):
    """Grid lines every GRID_STEP between lo and hi, plus the feature lines in `extra`."""
    lines = set(extra)
    v = lo
    while v <= hi + 1e-9:
        lines.add(round(v, 6))
        v += GRID_STEP
    return sorted(lines)


X_CUTS = grid(-HALF, HALF, [PLATFORM["x0"], RAMP["x0"], RAMP["x1"], PLATFORM["x1"], POOL["x0"], POOL["x1"]])
Y_CUTS = grid(-HALF, HALF, [RAMP["y0"], RAMP["y1"], PLATFORM["y0"], PLATFORM["y1"], POOL["y0"], POOL["y1"]])


def in_rect(x0, x1, y0, y1, r):
    return x0 >= r["x0"] and x1 <= r["x1"] and y0 >= r["y0"] and y1 <= r["y1"]


def quad(x0, y0, x1, y1, z):
    return [(x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z)]


def sides(r, xs, ys, z_lo, z_hi, mat, faces):
    """Vertical walls around rectangle r from z_lo to z_hi, split wherever a grid line meets its edge."""
    px = [x for x in xs if r["x0"] <= x <= r["x1"]]
    py = [y for y in ys if r["y0"] <= y <= r["y1"]]
    for a, b in zip(px, px[1:]):
        for y in (r["y0"], r["y1"]):
            faces.append(("shell", mat, [(a, y, z_lo), (b, y, z_lo), (b, y, z_hi), (a, y, z_hi)]))
    for a, b in zip(py, py[1:]):
        for x in (r["x0"], r["x1"]):
            faces.append(("shell", mat, [(x, a, z_lo), (x, b, z_lo), (x, b, z_hi), (x, a, z_hi)]))


def build_faces():
    """Returns a list of (group, material, [(x, y, z) ...]) in world units. Winding is fixed up later."""
    faces = []
    xs, ys = X_CUTS, Y_CUTS
    for i in range(len(xs) - 1):
        for j in range(len(ys) - 1):
            x0, x1, y0, y1 = xs[i], xs[i + 1], ys[j], ys[j + 1]
            faces.append(("shell", MAT_SKY, quad(x0, y0, x1, y1, CEILING)))
            if in_rect(x0, x1, y0, y1, RAMP):
                continue  # replaced by the ramp
            if in_rect(x0, x1, y0, y1, PLATFORM):
                faces.append(("shell", MAT_PLATFORM, quad(x0, y0, x1, y1, PLATFORM["top"])))
                continue
            if in_rect(x0, x1, y0, y1, POOL):
                faces.append(("shell", MAT_FLOOR, quad(x0, y0, x1, y1, -POOL["depth"])))   # pool bottom
                continue
            faces.append(("shell", MAT_FLOOR, quad(x0, y0, x1, y1, 0.0)))

    # Outer walls: one vertical strip per grid segment along each side.
    for i in range(len(xs) - 1):
        a, b = xs[i], xs[i + 1]
        for y in (-HALF, HALF):
            faces.append(("shell", MAT_SKY, [(a, y, 0.0), (b, y, 0.0), (b, y, CEILING), (a, y, CEILING)]))
    for j in range(len(ys) - 1):
        a, b = ys[j], ys[j + 1]
        for x in (-HALF, HALF):
            faces.append(("shell", MAT_SKY, [(x, a, 0.0), (x, b, 0.0), (x, b, CEILING), (x, a, CEILING)]))

    # Ramp: sloped top from the floor at y0 up to `top` at y1, two triangular sides, one back wall.
    # The top and back are split at every grid line crossing the ramp (e.g. x = 0), so they share whole edges
    # with the floor cells around them (found in task 10: 6 open edges until this split).
    r = RAMP
    rx = [x for x in xs if r["x0"] <= x <= r["x1"]]
    for a, b in zip(rx, rx[1:]):
        faces.append(("shell", MAT_RAMP, [(a, r["y0"], 0.0), (b, r["y0"], 0.0), (b, r["y1"], r["top"]), (a, r["y1"], r["top"])]))
        faces.append(("shell", MAT_RAMP, [(a, r["y1"], 0.0), (b, r["y1"], 0.0), (b, r["y1"], r["top"]), (a, r["y1"], r["top"])]))
    faces.append(("shell", MAT_RAMP, [(r["x0"], r["y0"], 0.0), (r["x0"], r["y1"], r["top"]), (r["x0"], r["y1"], 0.0)]))
    faces.append(("shell", MAT_RAMP, [(r["x1"], r["y0"], 0.0), (r["x1"], r["y1"], 0.0), (r["x1"], r["y1"], r["top"])]))

    sides(PLATFORM, xs, ys, 0.0, PLATFORM["top"], MAT_PLATFORM, faces)   # platform rises from the floor
    sides(POOL, xs, ys, -POOL["depth"], 0.0, MAT_FLOOR, faces)           # pool walls go down from the floor

    # Water: one render-only surface over the pool, below the floor edge. Its own vertices; open edges allowed.
    faces.append(("water", MAT_WATER, quad(POOL["x0"], POOL["y0"], POOL["x1"], POOL["y1"], POOL["water"])))

    # Floating islands: closed frustums (grass top, rock sides and bottom).
    for n, isl in enumerate(ISLANDS):
        g = "island%d" % n
        cx, cy, top, a, b = isl["cx"], isl["cy"], isl["top"], isl["a"], isl["b"]
        bot = top - isl["thick"]
        t = [(cx - a, cy - a, top), (cx + a, cy - a, top), (cx + a, cy + a, top), (cx - a, cy + a, top)]
        u = [(cx - b, cy - b, bot), (cx + b, cy - b, bot), (cx + b, cy + b, bot), (cx - b, cy + b, bot)]
        faces.append((g, MAT_GRASS, t))
        faces.append((g, MAT_ROCK, [u[3], u[2], u[1], u[0]]))
        for k in range(4):
            faces.append((g, MAT_ROCK, [u[k], u[(k + 1) % 4], t[(k + 1) % 4], t[k]]))
    return faces


def get_material(name):
    return bpy.data.materials.get(name) or bpy.data.materials.new(name)


def build_scene():
    # Start from an empty scene.
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)

    faces = build_faces()
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
        # Vertices are shared only within a group: islands and water never weld onto the shell.
        key = (group,) + tuple(round(c * WU, 4) for c in p)
        if key not in verts:
            verts[key] = bm.verts.new(tuple(round(c * WU, 4) for c in p))
        return verts[key]

    groups = {}
    for group, name, pts in faces:
        f = bm.faces.new([vert(group, p) for p in pts])
        f.material_index = mat_names.index(name)
        groups.setdefault(group, []).append(f)

    # Sealed-world check before export: every edge of the shell and of each island borders exactly two faces.
    # (Water is render-only and may have open edges.)
    for group, gfaces in groups.items():
        if group == "water":
            continue
        edges = {e for f in gfaces for e in f.edges}
        bad = [e for e in edges if len(e.link_faces) != 2]
        if bad:
            raise RuntimeError("%s is not sealed: %d edges don't have exactly two faces" % (group, len(bad)))

    # Orientation. recalc points each closed surface's normals away from the volume it encloses.
    # - The shell encloses the playable AIR, so its normals must be flipped to face inwards, into the air.
    # - An island encloses ROCK, so recalc already points its normals outwards, into the air: keep them.
    # - Water faces up, towards the player.
    for group, gfaces in groups.items():
        if group == "water":
            for f in gfaces:
                if f.normal.z < 0:
                    f.normal_flip()
            continue
        bmesh.ops.recalc_face_normals(bm, faces=gfaces)
        if group == "shell":
            for f in gfaces:
                f.normal_flip()

    # Mark creases (non-coplanar neighbours) sharp, so the exporter's edge split keeps flat shading.
    for e in bm.edges:
        lf = e.link_faces
        if len(lf) == 2 and lf[0].normal.angle(lf[1].normal) > 0.01:
            e.smooth = False

    # Texture coordinates (UVs). Lightmapping fails on triangles whose corners share one UV ("degenerate
    # triangle [or triangle with bad uvs]", seen in task 3), so every face gets a box projection in world
    # units: floors/ramp/ceiling from above, walls from the side. 1 texture repeat per UV_TILE world units.
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

    # Node object: the exporter needs a "frame" object, and exports its children.
    frame_mesh = bpy.data.meshes.new("frame")
    frame = bpy.data.objects.new("frame", frame_mesh)
    bpy.context.scene.collection.objects.link(frame)
    level.parent = frame

    print("LAUNCHLAB built %d faces (%s), %d materials: %s" % (
        len(faces), ", ".join("%s %d" % (g, len(fs)) for g, fs in groups.items()), len(mat_names), ", ".join(mat_names)))


def export(path):
    bpy.ops.export_scene.jms(
        filepath=path,
        check_existing=False,
        game_title="halo1",
        folder_structure=False,   # c20: "Generate Asset Subdirectories" disabled
        apply_modifiers=True,
        triangulate_faces=True,
        edge_split=True,
        use_edge_sharp=True,
        use_edge_angle=False,
        write_textures=False,     # keeps local file paths out of the JMS
    )
    print("LAUNCHLAB exported %s" % path)


if __name__ == "__main__":
    build_scene()
    if "--" in sys.argv and len(sys.argv) > sys.argv.index("--") + 1:
        export(sys.argv[sys.argv.index("--") + 1])
