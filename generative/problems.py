"""Generative design problems for Strix's two yoke arms.

Frame of both arms (mm, N): X across the arm, Y up the arm from the turntable's top face, Z outward from the
arm's inner face. Z = 0 is the print bed and the face that looks at the head. The idle arm's X is the robot's x;
the servo arm's X is the robot's -x (the part is turned half a turn about Z so both share this frame).

What an arm has to do:
  - stand on the turntable on a foot held by two M3 screws (they run along Y, so they are cut afterwards by
    dress.py, together with the exact outline; the pipeline's primitives only run along Z);
  - keep a closed inner face (a thin skin): the wiring behind it must stay out of sight;
  - carry its cover (two bosses with M3 inserts), and leave room for the cover's posts and for the cables;
  - idle arm: a plain bearing for the hollow trunnion; servo arm: a window and two seats for the tilt servo.

Loads. Nobody has measured them; they are derived, and only their directions matter for the comparison:
  - weight: a 300 g head (the launcher head, heavier than today's 125 g) times 2, all of it on one arm: 6 N down;
  - fore-aft: a 10 N knock on the head along X (about 1 kg-force, a hand bumping it);
  - sideways: the same 10 N knock along the tilt axis, which bends the arm out of its plane;
  - servo torque (servo arm only): the MG90S's stall torque, 180 N mm, as a couple on its two seats.
"""
import numpy as np

from genpart import Problem, RemoteLoad, box, zcyl

H_TILT = 62.0          # tilt axis above the turntable
SKIN = 1.25            # the closed inner face
FOOT = (5.0, 17.0)     # the foot: height (Y) and how far it reaches outward (Z)
EDGE = 1.25            # above the skin the part stays this far inside the outline: the cover's wall sits there
DEPTH = 17.5           # how far outward the part may grow (the cover's cavity is 19.5 deep)
VOXEL = 1.25


def outline():
    """The arm's outline in robot x and height: the hull of the base and the rounded head (cad/strix-print.scad)."""
    a = np.radians(np.arange(0, 360, 5))
    pts = [(-27.0, 0.0), (27.0, 0.0), (-27.0, 2.0), (27.0, 2.0)]
    for cx, cy in ((-20, 56), (9, 56), (-20, 68), (9, 68)):
        pts += list(zip(cx + 6 * np.cos(a), cy + 6 * np.sin(a)))
    pts = sorted(set((round(float(x), 6), round(float(y), 6)) for x, y in pts))
    cross = lambda o, p, q: (p[0] - o[0]) * (q[1] - o[1]) - (p[1] - o[1]) * (q[0] - o[0])
    lower, upper = [], []                                    # Andrew's monotone chain: no scipy, so Blender's Python can load this file
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return np.array(lower[:-1] + upper[:-1])                 # counter-clockwise


def inside(poly, x, y, inset=0.0):
    """Points at least `inset` inside a convex counter-clockwise polygon."""
    ok = np.ones(np.shape(x), bool)
    for (x0, y0), (x1, y1) in zip(poly, np.roll(poly, -1, axis=0)):
        n = np.hypot(x1 - x0, y1 - y0)
        ok &= ((x1 - x0) * (y - y0) - (y1 - y0) * (x - x0)) / n >= inset
    return ok


def outside_columns(sx, inset, z0, z1, above=0.0):
    """Keep-outs for what lies outside the outline: one box per column of cells that is entirely outside above
    some height. Conservative on purpose (stairs just outside the true edge): dress.py trims to the exact outline."""
    poly, out = outline(), []
    ys = np.arange(0.125, 74, 0.25)
    for xa in np.arange(-27, 27, VOXEL):
        xs = np.linspace(xa, xa + VOXEL, 6)
        X, Y = np.meshgrid(xs * sx, ys)                      # sx turns the part's X into the robot's x
        column = inside(poly, X, Y, inset).any(axis=1)
        top = ys[column].max() + 0.125 if column.any() else above
        top = max(np.ceil(top / 0.25) * 0.25, above)
        if top < 74:
            out.append(box(xa, xa + VOXEL, top, 99, z0, z1))
    return out


def common(sx):
    """What both arms share. sx = +1 for the idle arm, -1 for the servo arm (its X is the robot's -x)."""
    preserve = [box(-27, 27, 0, 74, 0, SKIN),                                # closed inner face
                box(-27, 27, 0, FOOT[0], 0, FOOT[1]),                        # foot
                zcyl(sx * 14, 34, 4.25, 0, 9), zcyl(sx * -20, 34, 4.25, 0, 9)]   # bosses for the cover screws
    keepout = (outside_columns(sx, 0.0, -99, SKIN)                           # outside the outline
               + outside_columns(sx, EDGE, SKIN, 99, above=FOOT[0])          # above the skin: clear of the cover's wall
               + [box(-4, 4, -99, 4.5, -99, 99),                             # cable channel at turntable level
                  box(-99, 99, -99, 2.5, FOOT[1], 99),                       # the cover closes under here
                  zcyl(sx * 14, 34, 4.6, 9, 99), zcyl(sx * -20, 34, 4.6, 9, 99)])   # the cover's posts
    for x in (-16, 16):                                                      # foot screws: head and a hex key's reach
        keepout.append(box(x - 3.5, x + 3.5, FOOT[0], 35, 7.5, 14.5))
    holes = [zcyl(sx * 14, 34, 2.0, 2.8, 99), zcyl(sx * -20, 34, 2.0, 2.8, 99)]   # M3 inserts
    support = [box(-27, 27, -1, 1.25, 0, DEPTH)]                             # bolted down on the turntable
    return preserve, keepout, holes, support


def arm_idle():
    """The arm that carries the hollow trunnion. Frame above; X is the robot's x."""
    preserve, keepout, holes, support = common(1)
    boss = zcyl(0, H_TILT, 9.5, 0, 5)                                        # plain bearing for the trunnion
    preserve.append(boss)
    holes.append(zcyl(0, H_TILT, 6.15, -99, 99))
    keepout += [zcyl(0, H_TILT, 7.5, 5, 99),                                 # the harness leaves the trunnion here ...
                box(-5, 5, 4.5, H_TILT, 5, 11)]                              # ... and runs down to the channel, with its connector
    at = (0, H_TILT, 0)
    return Problem(
        name="arm_idle", bounds=(-27, 27, 0, 74, 0, DEPTH), keepout=keepout, preserve=preserve, holes=holes, support=support,
        cases={"weight": [RemoteLoad([boss], at, (0, -6, 0))],
               "fore-aft": [RemoteLoad([boss], at, (10, 0, 0))],
               "sideways": [RemoteLoad([boss], at, (0, 0, 10))]},
        round=1.0, voxel=VOXEL, volfrac=0.36, rmin=2.5, min_wall=1.2, baseline="baselines/arm_idle.stl")


def arm_servo():
    """The arm that carries the tilt servo. Frame above; X is the robot's -x."""
    preserve, keepout, holes, support = common(-1)
    seat_a, seat_b = (17.3, 21.8), (-10.9, -6.3)                             # where the servo's two ears rest (X)
    seats = [box(*seat_a, 56, 68, 0, 5), box(*seat_b, 56, 68, 0, 5)]
    preserve += seats
    keepout += [box(-6.3, 17.3, 55.5, 68.5, -99, 99),                        # the window the servo body goes through
                box(-11.1, 22.0, 55.2, 68.8, 5, 99),                         # ears and body, outward
                box(-4, 10, 4.5, 56, 5, 9)]                                  # the servo lead and its two zip ties
    holes += [zcyl(19.3, H_TILT, 0.85, -99, 99), zcyl(-8.5, H_TILT, 0.85, -99, 99)]          # the servo's own screws
    holes += [box(x - 1, x + 1, y - 2, y + 2, -99, 99) for x in (2, 10) for y in (22, 40)]  # zip-tie slots
    # each seat in two halves, above and below the line through both: together they can carry any moment
    halves = [box(*s, a, b, 0, 5) for s in (seat_a, seat_b) for a, b in ((56, 62), (62, 68))]
    shaft = (0, H_TILT, -3.5)                                                # where the head hangs on the servo
    couple = 180 / 27.8                                                      # stall torque over the ears' spacing
    return Problem(
        name="arm_servo", bounds=(-27, 27, 0, 74, 0, DEPTH), keepout=keepout, preserve=preserve, holes=holes, support=support,
        cases={"weight": [RemoteLoad(halves, shaft, (0, -6, 0))],
               "fore-aft": [RemoteLoad(halves, shaft, (10, 0, 0))],
               "sideways": [RemoteLoad(halves, shaft, (0, 0, 10))],
               "servo torque": [RemoteLoad([seats[0]], (19.55, H_TILT, 2.5), (0, couple, 0)),
                                RemoteLoad([seats[1]], (-8.6, H_TILT, 2.5), (0, -couple, 0))]},
        round=1.0, voxel=VOXEL, volfrac=0.40, rmin=2.5, min_wall=1.2, baseline="baselines/arm_servo.stl")


PROBLEMS = {"arm_idle": arm_idle, "arm_servo": arm_servo}
