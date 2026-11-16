"""Finish a grown arm with what the pipeline's Z-only primitives cannot express.

    PYTHONPATH=<skill>/scripts python dress.py <part>            (arm_idle or arm_servo; the path is for genpart)

The pipeline trims to stairs just outside the arm's slanted outline and cannot drill along Y. This step:
  1. trims the mesh to the exact outline (the full outline for the skin, 1.5 mm inside it above the skin: the
     cover's wall sits there, 1 mm thick on this side, and wants half a millimetre of clearance), keeping the foot whole;
  2. drills the two foot screws, which run along Y;
  3. trims the foot's outer corners to the turntable's edge.
Reads out/<part>.stl (kept as out/<part>_raw.stl) and writes the dressed mesh back to out/<part>.stl, so the
pipeline's check and evaluate steps judge the part that would be printed.
"""
import shutil
import sys

import manifold3d as m3
import numpy as np
import trimesh

from problems import DEPTH, FOOT, SKIN, outline

CLEAR = 1.5                                                   # above the skin: the cover's wall plus clearance

part = sys.argv[1]
sx = 1 if part == "arm_idle" else -1
raw = f"out/{part}_raw.stl"
shutil.copyfile(f"out/{part}.stl", raw)

mesh = trimesh.load(raw)
mesh.merge_vertices()
body = m3.Manifold(m3.Mesh(vert_properties=np.asarray(mesh.vertices, np.float32), tri_verts=np.asarray(mesh.faces, np.uint32)))
assert body.status() == m3.Error.NoError, f"the pipeline's mesh is not a clean solid: {body.status()}"

poly = outline() * [sx, 1]
if sx < 0:
    poly = poly[::-1]                                         # mirrored: keep it counter-clockwise
shape = m3.CrossSection([poly.astype(np.float64)])
allowed = (shape.extrude(SKIN)
           + shape.offset(-CLEAR, m3.JoinType.Round).extrude(DEPTH - SKIN + 1).translate([0, 0, SKIN])
           + m3.Manifold.cube([54, FOOT[0], FOOT[1]]).translate([-27, 0, 0]))
body = body ^ allowed                                         # intersection

along_y = lambda r, length: m3.Manifold.cylinder(length, r, r, 64).rotate([-90, 0, 0])   # from y = 0 towards +y
for x in (-16, 16):                                           # M3 foot screws, 6 mm out from the arm's outer face
    body -= along_y(1.7, FOOT[0] + 2).translate([x, -1, 11])
body = body ^ along_y(62, 120).translate([0, -20, -42])       # the turntable is 124 mm across; its axis is 42 mm behind the bed

out = body.to_mesh()
result = trimesh.Trimesh(np.asarray(out.vert_properties)[:, :3], np.asarray(out.tri_verts))
result.export(f"out/{part}.stl")
print(f"{part}: dressed {abs(mesh.volume):.0f} -> {abs(result.volume):.0f} mm3, watertight {result.is_watertight}, "
      f"{len(result.faces)} triangles, bounds {result.bounds.round(2).tolist()}")
