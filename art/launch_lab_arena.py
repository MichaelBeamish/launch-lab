"""Launch Lab arena (task 3): builds the level geometry in Blender and exports it as JMS.

Geometry as code: run headless (tools\\build.ps1 does this), or open Blender's Scripting tab and run it to inspect.
    blender --background --python art/launch_lab_arena.py -- <output .JMS path>   (needs the add-on enabled)

Halo rules this follows (c20 "My first box level"; H1 materials):
- The level is ONE sealed, inward-facing shell: every edge is shared by exactly two faces, no holes, no T-junctions.
  All faces are cut on one shared grid (X_CUTS, Y_CUTS) so neighbouring faces always share whole edges.
- Walls and ceiling use the special material "+sky": invisible but solid, so the room is sealed yet looks open.
- Material names are matched by Tool to stock shader tags (here the stock tutorial shaders).
- The geometry is parented to a node object named "frame".
- Units: 1 world unit (WU) = 100 Blender units, as in the c20 guide.
"""
import sys

import bmesh
import bpy

WU = 100.0  # Blender units per world unit

# Layout in world units. Origin at the arena centre, floor at z = 0.
HALF = 20.0            # arena is 40 x 40 WU
CEILING = 30.0         # invisible +sky ceiling, high enough for launches
RAMP = dict(x0=-3.0, x1=3.0, y0=-12.0, y1=0.0, top=3.0)        # rises towards +y
PLATFORM = dict(x0=-5.0, x1=5.0, y0=8.0, y1=16.0, top=4.0)     # landing target beyond the ramp

# Every face edge lies on these lines, so faces never meet mid-edge.
X_CUTS = [-HALF, PLATFORM["x0"], RAMP["x0"], RAMP["x1"], PLATFORM["x1"], HALF]
Y_CUTS = [-HALF, RAMP["y0"], RAMP["y1"], PLATFORM["y0"], PLATFORM["y1"], HALF]

MAT_FLOOR = "example_tutorial_ground"
MAT_RAMP = "example_tutorial_plate_floor"
MAT_PLATFORM = "example_tutorial_metal_floor"
MAT_SKY = "+sky"
UV_TILE = 2.0  # world units per texture repeat


def in_rect(x0, x1, y0, y1, r):
    return x0 >= r["x0"] and x1 <= r["x1"] and y0 >= r["y0"] and y1 <= r["y1"]


def build_faces():
    """Returns a list of (material, [(x, y, z) ...]) in world units. Winding is fixed up later."""
    faces = []
    xs, ys = X_CUTS, Y_CUTS
    for i in range(len(xs) - 1):
        for j in range(len(ys) - 1):
            x0, x1, y0, y1 = xs[i], xs[i + 1], ys[j], ys[j + 1]
            # Ceiling: every cell.
            faces.append((MAT_SKY, [(x0, y0, CEILING), (x1, y0, CEILING), (x1, y1, CEILING), (x0, y1, CEILING)]))
            if in_rect(x0, x1, y0, y1, RAMP):
                continue  # replaced by the ramp
            if in_rect(x0, x1, y0, y1, PLATFORM):
                h = PLATFORM["top"]
                faces.append((MAT_PLATFORM, [(x0, y0, h), (x1, y0, h), (x1, y1, h), (x0, y1, h)]))
                continue
            faces.append((MAT_FLOOR, [(x0, y0, 0.0), (x1, y0, 0.0), (x1, y1, 0.0), (x0, y1, 0.0)]))

    # Outer walls: one vertical strip per grid segment along each side.
    for i in range(len(xs) - 1):
        a, b = xs[i], xs[i + 1]
        for y in (-HALF, HALF):
            faces.append((MAT_SKY, [(a, y, 0.0), (b, y, 0.0), (b, y, CEILING), (a, y, CEILING)]))
    for j in range(len(ys) - 1):
        a, b = ys[j], ys[j + 1]
        for x in (-HALF, HALF):
            faces.append((MAT_SKY, [(x, a, 0.0), (x, b, 0.0), (x, b, CEILING), (x, a, CEILING)]))

    # Ramp: sloped top from the floor at y0 up to `top` at y1, two triangular sides, one back wall.
    r = RAMP
    faces.append((MAT_RAMP, [(r["x0"], r["y0"], 0.0), (r["x1"], r["y0"], 0.0),
                             (r["x1"], r["y1"], r["top"]), (r["x0"], r["y1"], r["top"])]))
    faces.append((MAT_RAMP, [(r["x0"], r["y0"], 0.0), (r["x0"], r["y1"], r["top"]), (r["x0"], r["y1"], 0.0)]))
    faces.append((MAT_RAMP, [(r["x1"], r["y0"], 0.0), (r["x1"], r["y1"], 0.0), (r["x1"], r["y1"], r["top"])]))
    faces.append((MAT_RAMP, [(r["x0"], r["y1"], 0.0), (r["x1"], r["y1"], 0.0),
                             (r["x1"], r["y1"], r["top"]), (r["x0"], r["y1"], r["top"])]))

    # Platform sides: split wherever a grid line meets the platform's edge.
    p, h = PLATFORM, PLATFORM["top"]
    px = [x for x in xs if p["x0"] <= x <= p["x1"]]
    py = [y for y in ys if p["y0"] <= y <= p["y1"]]
    for a, b in zip(px, px[1:]):
        for y in (p["y0"], p["y1"]):
            faces.append((MAT_PLATFORM, [(a, y, 0.0), (b, y, 0.0), (b, y, h), (a, y, h)]))
    for a, b in zip(py, py[1:]):
        for x in (p["x0"], p["x1"]):
            faces.append((MAT_PLATFORM, [(x, a, 0.0), (x, b, 0.0), (x, b, h), (x, a, h)]))
    return faces


def get_material(name):
    return bpy.data.materials.get(name) or bpy.data.materials.new(name)


def build_scene():
    # Start from an empty scene.
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)

    faces = build_faces()
    mat_names = []
    for name, _ in faces:
        if name not in mat_names:
            mat_names.append(name)

    mesh = bpy.data.meshes.new("launch_lab_level")
    for name in mat_names:
        mesh.materials.append(get_material(name))

    bm = bmesh.new()
    verts = {}

    def vert(p):
        key = tuple(round(c * WU, 4) for c in p)
        if key not in verts:
            verts[key] = bm.verts.new(key)
        return verts[key]

    for name, pts in faces:
        f = bm.faces.new([vert(p) for p in pts])
        f.material_index = mat_names.index(name)

    # Sealed-world checks before export: every edge must border exactly two faces.
    bad = [e for e in bm.edges if len(e.link_faces) != 2]
    if bad:
        raise RuntimeError("Level is not sealed: %d edges don't have exactly two faces" % len(bad))

    # The shell encloses the playable air. recalc points normals away from the enclosed volume,
    # so flip them all to face inwards, into the air (Halo wants inward-facing level geometry).
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    for f in bm.faces:
        f.normal_flip()

    # Mark creases (non-coplanar neighbours) sharp, so the exporter's edge split keeps flat shading.
    for e in bm.edges:
        f0, f1 = e.link_faces
        if f0.normal.angle(f1.normal) > 0.01:
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

    print("LAUNCHLAB built %d faces, %d materials: %s" % (len(faces), len(mat_names), ", ".join(mat_names)))


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
