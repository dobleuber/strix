#!/usr/bin/env python3
"""Mass properties and first-order dynamics of Strix, taken from the printable parts.

Exports every part of cad/strix-print.scad where it sits in the assembly, integrates
volume, centre of mass and inertia over the meshes, adds the bought components as
point masses, and prints the margins that decide how the robot can move.

    python3 sim/dynamics.py            # human-readable report
    python3 sim/dynamics.py --json     # the same numbers as JSON

Everything here is a model. The motor torque, fill factors and component masses are
assumptions listed below; nothing has been measured on a built robot.
"""
import json, math, os, struct, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, "out", "asbuilt")
SCAD = os.path.join(ROOT, "cad", "strix-print.scad")

DENSITY = 1.24e-6          # kg/mm3, PLA (PETG is about 2 % more)
# share of each part's solid volume that is actually plastic (walls + infill)
FILL = dict(plate=0.9, shell=0.95, deck=0.7, cap=1.0, ring=0.95, port_plug=1.0,
            turntable=0.6, retainer=0.9, arm_servo=0.7, arm_idle=0.7,
            head_rear=0.95, head_front=0.95, iris=1.0, bezel=1.0, sled=1.0, spacer=1.0)
BASE = ["plate", "shell", "deck", "cap", "ring", "port_plug"]
PAN = ["turntable", "retainer", "arm_servo", "arm_idle"]       # turntable frame = world at pan 0
HEAD = ["head_rear", "head_front", "iris", "bezel", "sled", "spacer"]   # head frame, origin on the tilt axis

Z_TILT = 142.0             # tilt axis above the underside of the plate (mm)
# bought parts as point masses: (kg, x, y, z) in the frame of their group
HEAD_POINTS = {"Pi Zero 2": (0.011, 3, 0, 21), "camera": (0.003, 42, 0, 6),
               "LEDs and wiring": (0.006, 38, 0, 6), "inserts and screws": (0.008, 5, 0, -12),
               "antenna rod": (0.0035, -14, 0, 65)}
PAN_POINTS = {"tilt servo": (0.0134, -5, 56, Z_TILT), "bearing (rotating half)": (0.013, 0, 0, 64.5),
              "screws and inserts": (0.010, 0, 0, 80)}
MOTOR_MASS = 0.28          # NEMA17 42-34
ROTOR_INERTIA = 5.4e-6     # kg m2, typical for a 34 mm NEMA17
MOTOR_TORQUE = 0.20        # N m usable at low speed (well under the ~0.4 N m holding torque)
RATIO = 4.0
SERVO_STALL = 0.18         # N m, MG90S at 4.8 V (1.8 kg cm)
SERVO_SPEED = 600.0        # deg/s unloaded (0.10 s / 60 deg)
BELT_TENSION = 35.0        # N, comfortable working tension for 6 mm GT2
PULLEY_PITCH_R = 80 * 2 / math.pi / 2 / 1000   # m
G = 9.81


def export(part):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, part + ".stl")
    if not os.path.exists(path) or os.path.getmtime(path) < os.path.getmtime(SCAD):
        subprocess.run(["openscad", SCAD, "-o", path, "--export-format", "binstl",
                        "-D", f'part="{part}"', "-D", "as_built=true"],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return path


def mesh_props(path):
    """volume (mm3), first moments and second moments about the origin, for a closed mesh"""
    d = open(path, "rb").read()
    n = struct.unpack("<I", d[80:84])[0]
    vol = 0.0
    m1 = [0.0] * 3
    m2 = [[0.0] * 3 for _ in range(3)]
    for i in range(n):
        v = struct.unpack("<9f", d[84 + i * 50 + 12: 84 + i * 50 + 48])
        a, b, c = v[0:3], v[3:6], v[6:9]
        det = (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
               + a[2] * (b[0] * c[1] - b[1] * c[0]))
        vol += det / 6
        s = [a[k] + b[k] + c[k] for k in range(3)]
        for k in range(3):
            m1[k] += det / 24 * s[k]
            for j in range(3):
                m2[k][j] += det / 120 * (s[k] * s[j] + a[k] * a[j] + b[k] * b[j] + c[k] * c[j])
    return vol, m1, m2


class Body:
    def __init__(self):
        self.m = 0.0; self.m1 = [0.0] * 3; self.m2 = [[0.0] * 3 for _ in range(3)]
    def add_mesh(self, part):
        vol, m1, m2 = mesh_props(export(part))
        k = DENSITY * FILL[part]
        self.m += k * vol
        for a in range(3):
            self.m1[a] += k * m1[a]
            for b in range(3):
                self.m2[a][b] += k * m2[a][b]
    def add_point(self, m, x, y, z):
        p = (x, y, z)
        self.m += m
        for a in range(3):
            self.m1[a] += m * p[a]
            for b in range(3):
                self.m2[a][b] += m * p[a] * p[b]
    def com(self):
        return [v / self.m for v in self.m1]
    def inertia_about_axis(self, axis):          # kg m2, axis through the origin
        a, b = [k for k in range(3) if k != axis]
        return (self.m2[a][a] + self.m2[b][b]) * 1e-6


def main():
    head = Body()
    for p in HEAD: head.add_mesh(p)
    for m, x, y, z in HEAD_POINTS.values(): head.add_point(m, x, y, z)
    pan = Body()
    for p in PAN: pan.add_mesh(p)
    for m, x, y, z in PAN_POINTS.values(): pan.add_point(m, x, y, z)
    base = Body()
    for p in BASE: base.add_mesh(p)

    hc = head.com()
    i_tilt = head.inertia_about_axis(1)
    i_pan_head = head.inertia_about_axis(2)       # head frame origin lies on the pan axis
    i_pan_load = pan.inertia_about_axis(2) + i_pan_head
    i_reflected = ROTOR_INERTIA * RATIO ** 2
    i_pan = i_pan_load + i_reflected

    torque_head = MOTOR_TORQUE * RATIO
    belt_limit = BELT_TENSION * PULLEY_PITCH_R
    torque_pan = min(torque_head, belt_limit)
    alpha_max = torque_pan / i_pan                                   # rad/s2

    # tilt: worst gravity torque over the travel
    lever = lambda deg: abs(hc[0] * math.cos(math.radians(deg)) - hc[2] * math.sin(math.radians(deg)))
    worst = max(range(-15, 36), key=lever)
    t_gravity = head.m * G * lever(worst) / 1000
    alpha_tilt = (SERVO_STALL * 0.5 - t_gravity) / i_tilt            # half stall torque as working torque

    # base: does a pan start twist the robot on the desk?
    total = head.m + pan.m + base.m + MOTOR_MASS + 0.06              # + electronics and wiring
    friction_torque = 0.6 * total * G * 0.0707                      # rubber feet at 70.7 mm, mu 0.6
    alpha_slip = friction_torque / i_pan_load

    def move_time(deg, vmax, acc):                                   # trapezoidal profile
        d_acc = vmax ** 2 / acc
        return 2 * math.sqrt(deg / acc) if deg < d_acc else deg / vmax + vmax / acc

    out = {
        "head_mass_g": head.m * 1000, "head_com_mm": hc,
        "head_inertia_tilt_kgm2": i_tilt, "pan_stage_mass_g": pan.m * 1000,
        "rotating_mass_g": (head.m + pan.m) * 1000, "base_mass_g": (base.m + MOTOR_MASS + 0.06) * 1000,
        "total_mass_g": total * 1000,
        "pan_inertia_load_kgm2": i_pan_load, "pan_inertia_reflected_rotor_kgm2": i_reflected,
        "pan_torque_available_Nm": torque_pan, "pan_torque_motor_side_Nm": torque_head, "belt_torque_limit_Nm": belt_limit,
        "pan_accel_max_deg_s2": math.degrees(alpha_max),
        "pan_accel_base_slips_deg_s2": math.degrees(alpha_slip),
        "pan_step_deg": 360 / (200 * 16 * RATIO),
        "tilt_gravity_torque_worst_Nm": t_gravity, "tilt_worst_angle_deg": worst,
        "tilt_servo_stall_Nm": SERVO_STALL, "tilt_margin_x": SERVO_STALL / t_gravity,
        "tilt_accel_deg_s2": math.degrees(alpha_tilt),
        "times_s": {f"{v}dps_{a}dps2": {"90deg": move_time(90, v, a), "330deg": move_time(330, v, a)}
                    for v, a in [(180, 1000), (360, 3000), (720, 6000)]},
        "homing_worst_s": (173 + 166) / 60 + move_time(166, 360, 3000),
    }
    if "--json" in sys.argv:
        print(json.dumps(out, indent=2)); return
    print(f"Head            {out['head_mass_g']:6.0f} g   centre of mass x {hc[0]:+.1f}  y {hc[1]:+.1f}  z {hc[2]:+.1f} mm from the tilt axis")
    print(f"Pan stage       {out['pan_stage_mass_g']:6.0f} g   rotating total {out['rotating_mass_g']:.0f} g, whole robot {out['total_mass_g']:.0f} g")
    print(f"Pan inertia     {i_pan_load*1e4:6.2f} e-4 kg m2 load + {i_reflected*1e4:.2f} e-4 reflected rotor")
    print(f"Pan torque      {torque_pan:6.2f} N m at the head (motor x ratio {torque_head:.2f}, belt limit {belt_limit:.2f})")
    print(f"Pan accel max   {out['pan_accel_max_deg_s2']:6.0f} deg/s2   base starts to twist on the desk near {out['pan_accel_base_slips_deg_s2']:.0f} deg/s2")
    print(f"Pan microstep   {out['pan_step_deg']:6.3f} deg")
    print(f"Tilt gravity    {t_gravity*1000:6.1f} mN m worst case (at {worst} deg) vs {SERVO_STALL*1000:.0f} mN m stall: {out['tilt_margin_x']:.0f}x margin")
    print(f"Tilt inertia    {i_tilt*1e4:6.2f} e-4 kg m2   accel at half stall torque {out['tilt_accel_deg_s2']:.0f} deg/s2")
    for k, v in out["times_s"].items():
        print(f"Move times      {k:>16}:  90 deg in {v['90deg']:.2f} s, 330 deg in {v['330deg']:.2f} s")
    print(f"Homing          up to {out['homing_worst_s']:.1f} s at 60 deg/s")


if __name__ == "__main__":
    main()
