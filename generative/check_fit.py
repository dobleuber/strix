"""Do the grown arms fit where the plate arms were, and how do they print?

    python check_fit.py            (from generative/; needs manifold3d and trimesh)

Places out/arm_idle.stl and out/arm_servo.stl in the robot's frame (see problems.py for the part frame) and
intersects each with its neighbours as built: turntable, retainer, turntable cover, its own arm cover (the
variant made for grown arms), the servo, and the head through its tilt range. Any shared volume is reported.
Then the printability figures: how much surface overhangs past 45 degrees when printed on the skin.

Neighbours come from ../out/asbuilt (python3 ../sim/dynamics.py writes them) and out/asbuilt_gen (the two covers
exported with arm_style="generative").
"""
import numpy as np
import manifold3d as m3
import trimesh

Z_TOP, ARM_Y, Z_TILT = 80.0, 42.0, 142.0


def solid(mesh):
    mesh.merge_vertices()
    out = m3.Manifold(m3.Mesh(vert_properties=np.asarray(mesh.vertices, np.float32), tri_verts=np.asarray(mesh.faces, np.uint32)))
    assert out.status() == m3.Error.NoError, out.status()
    return out


def placed(part):
    """A grown arm in the robot's frame."""
    mesh = trimesh.load(f"out/{part}.stl")
    X, Y, Z = mesh.vertices.T.copy()
    if part == "arm_idle":
        mesh.vertices = np.stack([X, -(Z + ARM_Y), Y + Z_TOP], axis=1)
    else:
        mesh.vertices = np.stack([-X, Z + ARM_Y, Y + Z_TOP], axis=1)
    return solid(mesh)


def built(name, folder="../out/asbuilt"):
    return solid(trimesh.load(f"{folder}/{name}.stl"))


def head(tilt):
    """The head's parts in the turntable's frame at a tilt angle (degrees, positive looks up)."""
    t = np.radians(tilt)
    turn = [[np.cos(t), 0, -np.sin(t), 0], [0, 1, 0, 0], [np.sin(t), 0, np.cos(t), Z_TILT]]
    whole = m3.Manifold()
    for name in ("head_rear", "head_front", "bezel", "trunnion", "spacer"):
        whole += built(name).transform(np.array(turn))
    return whole


servo = (m3.Manifold.cube([22.8, 23.0, 12.2]).translate([-16.8, 42.4, Z_TILT - 6.1])          # body, through the arm and outward
         + m3.Manifold.cube([32.3, 2.5, 12.2]).translate([-21.55, 47.0, Z_TILT - 6.1]))       # ears, on the arm's outer face
fixed = {"turntable": built("turntable"), "retainer": built("retainer"), "turntable cover": built("turntable_cover")}
worst = 0.0
for part, cover in (("arm_idle", "cover_idle"), ("arm_servo", "cover_servo")):
    arm = placed(part)
    others = dict(fixed, **{"its cover": built(cover, "out/asbuilt_gen")})
    if part == "arm_servo":
        others["servo"] = servo
    for tilt in (-15, 0, 20, 35):
        others[f"head at {tilt:+d}"] = head(tilt)
    line = []
    for name, other in others.items():
        shared = (arm ^ other).volume()
        worst = max(worst, shared)
        if shared > 0.5:
            line.append(f"{name} {shared:.1f} mm3")
    print(f"{part}: {arm.volume():.0f} mm3 placed; shares volume with: {', '.join(line) or 'nothing (under 0.5 mm3 everywhere)'}")

    mesh = trimesh.load(f"out/{part}.stl")                       # printed on its skin, as it is
    down = (mesh.face_normals[:, 2] < -np.cos(np.radians(45))) & (mesh.triangles_center[:, 2] > 0.3)
    area = mesh.area_faces[down].sum()
    print(f"  printing: {area:.0f} mm2 of surface overhangs past 45 degrees ({area / mesh.area:.1%} of the skin), "
          f"highest at z = {mesh.triangles_center[down][:, 2].max() if down.any() else 0:.1f} mm")
print(f"largest shared volume: {worst:.2f} mm3")
