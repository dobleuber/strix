"""Thin a grown arm's mesh for the repository and the slicer.

    blender -b -P decimate.py -- parts/arm_idle.stl ../stl/generative/arm_idle.stl 60000

The pipeline's meshes have 350 000 triangles (17 MB). This collapses edges down to the triangle count given.
At 60 000 triangles the surface of both arms moved by at most 0.008 mm and the volume did not change.
"""
import sys

import bpy

src, dst, count = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.stl_import(filepath=src)
part = bpy.context.selected_objects[0]
bpy.context.view_layer.objects.active = part
m = part.modifiers.new("decimate", "DECIMATE")
m.ratio = min(1.0, int(count) / len(part.data.polygons))
m.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier=m.name)
bpy.ops.wm.stl_export(filepath=dst, export_selected_objects=True)
print("wrote", dst, len(part.data.polygons), "triangles")
