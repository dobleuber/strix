// =====================================================================
//  Strix - printable parts, phase 1
//  Base, pan stage, yoke and the cyclops sensor head.
//
//  Units: mm.  Z = pan axis.  Front = +X.  Head parts are modelled in the
//  head frame (origin on the tilt axis).
//
//  Pick a part with `part` (or -D 'part="shell"' on the command line).
//  Single parts come out already laid on the bed in their print pose.
//  scripts/export-stl.sh writes every part to stl/.
//
//  UNTESTED GEOMETRY: nothing here has been printed yet. Print the `gauge`
//  part first and tune the fit parameters below to your printer, inserts
//  and bearing before committing to the big parts.
// =====================================================================

$fn = 96;

/* [What to show] */
part    = "assembly";  // assembly | plate | shell | deck | cap | turntable | retainer | ring | arm_servo | arm_idle | head_rear | head_front | iris | bezel | sled | spacer | port_plug | gauge
pan     = 0;
tilt    = 0;
cutaway = false;       // section through the assembly
as_built = false;      // true: emit a single part where it sits in the assembly, not in print pose

/* [Fits - tune with the gauge part] */
tol          = 0.2;          // general sliding clearance
ins_m3       = [4.0, 6.2];   // heat-set insert: [hole diameter, hole depth]
ins_m25      = [3.6, 5.2];
ins_m2       = [3.2, 4.5];
clr_m3       = 3.4;          // clearance holes
clr_m25      = 2.9;
clr_m2       = 2.4;
pilot_m2     = 1.7;          // self-tapping M2 / servo screws straight into plastic
brg          = [30, 42, 7];  // 6806-2RS: bore, OD, width
brg_post_fit = -0.05;        // added to the post diameter
brg_bore_fit = 0.10;         // added to the pocket diameter
gt2_fit      = 0.05;         // opens the pulley tooth grooves

/* [Base] */
base_d      = 160;
wall        = 3;
plate_t     = 3;
shell_h     = 46;
deck_t      = 5;
foot_h      = 5;
mount_sq    = 100;                       // 4 x M4: rubber feet now, rail carriage later
boss_r      = 75;
boss_angles = [0, 72, 144, 216, 288];    // one M3 screw joins ring, deck and shell at each
dc_jack_d   = 8.2;                       // panel-mount DC jack
switch_d    = 6.2;                       // panel-mount toggle switch
rail_port_d = 12.2;                      // GX12 connector for the rail, plugged until then
proto       = [50, 70];                  // protoboard carrying the Pico and the two drivers
proto_inset = 2;                         // hole centres from the board edge
proto_pos   = [32, 0];
proto_so    = 6;                         // standoff height

/* [Pan drive] */
t_big    = 80;
t_small  = 20;       // the pulley fitted to Ender 3 X/Y motors
belt_len = 200;      // closed GT2 loop
cable_d  = 18;       // bore through the hollow axis
nema_w   = 42.3;  nema_len = 34;  nema_hole = 31;  shaft_len = 24;
tt_d     = 124;      // turntable
tt_t     = 6;
stop_r   = 59.25;    // radius of the hard stop post and the lug that hits it
sw_angle = -14;      // homing microswitch, just before the stop
sw_hole_z = 5.3;     // height of the switch mounting holes above the deck
sw_hole_pitch = 9.5;

/* [Yoke] */
tilt_h   = 62;       // tilt axis above the turntable
arm_y    = 42;       // inner face of the arms
arm_t    = 5;
servo_len = 22.8;  servo_w = 12.2;        // MG90S / SG90 body
servo_shaft_off = 6.0;                    // shaft axis to the near end of the body
servo_ear_pitch = 27.8;                   // between the two ear screws
axle_brg = [3, 10, 4];                    // 623 bearing on the idle side

/* [Head] */
hx0 = -40;  htail = 46;      // tail: rear end and length of the tapering zone
hx1 = 46;   hnose = 32;      // nose
hseam = 10;                  // front / rear split
p_wt = 40;  p_rt = 28;       // section: half width and corner radius at the top
p_wb = 30;  p_rb = 14;       //          and at the bottom
p_z0 = -30; p_z1 = 41; p_zc = 4;
hwall = 2.4;
lip_t = 1.2;                 // outer lip of the lap joint
tongue_len = 8;
eye_d = 50;  eye_z = 6;
pad_servo_y = 34.5;          // flat on the servo side that takes the horn
pad_idle_y  = -35.5;
sled_z = 14;  sled_t = 2;
pi_holes = [58, 23];         // Raspberry Pi Zero 2 mounting pattern (M2.5)
pi_pos_x = 3;
cam_holes = [21, 12.5];      // Raspberry Pi camera v1/v2/3 mounting pattern (M2)
cam_lens_off = 1.2;          // lens centre from the centroid of the 4 holes, towards the connector (measure yours)
cam_connector_up = true;     // ribbon leaves upwards, straight back to the Pi
led_d = 5.1;                 // iris LEDs sit in blind pockets behind a 0.8 mm skin

// ---------------- derived ----------------
function pitch_d(t) = t * 2 / PI;
function gt2_od(t)  = pitch_d(t) - 0.508;
d_big = pitch_d(t_big);  d_small = pitch_d(t_small);  od_big = gt2_od(t_big);
K = belt_len - PI * (d_big + d_small) / 2;
pan_c = (K + sqrt(K * K - 2 * pow(d_big - d_small, 2))) / 4;

z_deck = plate_t + shell_h;
zd     = z_deck + deck_t;
z_tt   = zd + 20;
z_top  = z_tt + tt_t;
z_tilt = z_top + tilt_h;
tongue_x0 = hseam - tongue_len + 0.3;
proto_holes = [for (sx = [-1, 1], sy = [-1, 1])
    [proto_pos[0] + sx * (proto[0] / 2 - proto_inset), proto_pos[1] + sy * (proto[1] / 2 - proto_inset)]];
pi_hole_xy = [for (sx = [-1, 1], sy = [-1, 1]) [pi_pos_x + sx * pi_holes[0] / 2, sy * pi_holes[1] / 2]];
cam_cz = (cam_connector_up ? -1 : 1) * cam_lens_off;      // hole centroid relative to the eye axis
cam_hole_yz = [for (sy = [-1, 1], sz = [-1, 1]) [sy * cam_holes[0] / 2, cam_cz + sz * cam_holes[1] / 2]];
lug_angles = [30, 150, 270];
lug_r = 22.6;
led_angles = [0, 60, 120, 180, 240, 300];

echo(str("pan centre distance ", pan_c, " mm, ratio ", t_big / t_small, ":1, tilt axis at ", z_tilt + foot_h, " mm"));

C_PRINT = "#e8792b";  C_DARK = "#3a3f47";  C_LIGHT = "#eceff2";
C_METAL = "#b9bec6";  C_BLACK = "#22252a"; C_PCB = "#2e8b57";

// ---------------- helpers ----------------
module tube(od, id, h) { difference() { cylinder(d = od, h = h); translate([0, 0, -1]) cylinder(d = id, h = h + 2); } }
// insert hole going +Z from the origin, with a small lead-in
module ins(spec) {
    translate([0, 0, -0.01]) cylinder(d = spec[0], h = spec[1] + 0.01, $fn = 32);
    translate([0, 0, -0.01]) cylinder(d1 = spec[0] + 0.8, d2 = spec[0], h = 0.4, $fn = 32);
}
module ins_down(spec) { mirror([0, 0, 1]) ins(spec); }
module hole(d, h) { cylinder(d = d, h = h, $fn = 32); }
module xslab(xa, xb) { translate([xa, -200, -200]) cube([xb - xa, 400, 400]); }
// local x -> Y, local y -> Z, local z -> +X, origin on the eye axis
module eye_frame(x) { translate([x, 0, eye_z]) rotate([90, 0, 90]) children(); }

module gt2_2d(teeth) {
    od = gt2_od(teeth);
    difference() {
        circle(d = od, $fn = teeth * 4);
        for (i = [0 : teeth - 1]) rotate(i * 360 / teeth) translate([od / 2 - 0.75 + 0.555, 0]) hull() {
            circle(r = 0.555 + gt2_fit, $fn = 16);
            translate([0.3, -(1.15 + 2 * gt2_fit) / 2]) square([0.6, 1.15 + 2 * gt2_fit]);
        }
    }
}

// =============================== BASE ===============================
module plate() {
    difference() {
        union() {
            cylinder(d = base_d, h = plate_t);
            for (p = proto_holes) translate([p[0], p[1], 0]) cylinder(d = 6.5, h = plate_t + proto_so, $fn = 32);
            // rim that locates the buck converter (held by a zip tie)
            translate([-43, -60, 0]) difference() { cube([46, 24, plate_t + 2]); translate([1.2, 1.2, plate_t]) cube([43.6, 21.6, 3]); }
        }
        for (a = boss_angles) rotate(a) translate([boss_r, 0, -1]) hole(clr_m3, plate_t + 2);
        for (sx = [-1, 1], sy = [-1, 1]) translate([sx * mount_sq / 2, sy * mount_sq / 2, -1]) hole(4.4, plate_t + 2);
        for (p = proto_holes) translate([p[0], p[1], plate_t + proto_so]) ins_down(ins_m2);
        for (dx = [-34, -8]) translate([dx, -62, -1]) cube([4, 28, plate_t + 4]);        // zip tie slots
    }
}

module shell() {
    difference() {
        intersection() {
            union() {
                translate([0, 0, plate_t]) tube(base_d, base_d - 2 * wall, shell_h);
                for (a = boss_angles) rotate(a) translate([boss_r, 0, plate_t]) cylinder(d = 10, h = shell_h, $fn = 32);
            }
            cylinder(d = base_d, h = 200);
        }
        for (a = boss_angles) rotate(a) {
            translate([boss_r, 0, plate_t]) ins(ins_m3);
            translate([boss_r, 0, z_deck]) ins_down(ins_m3);
        }
        for (a = [84 : 8 : 116], s = [-1, 1]) rotate(s * a)                               // vents
            translate([base_d / 2 - wall - 1, -1.5, plate_t + 10]) cube([wall + 2, 3, shell_h - 20]);
        rotate(195) translate([base_d / 2 - wall - 1, 0, 9]) rotate([0, 90, 0]) hole(dc_jack_d, wall + 2);
        rotate(165) translate([base_d / 2 - wall - 1, 0, 9]) rotate([0, 90, 0]) hole(switch_d, wall + 2);
        rotate(128) translate([base_d / 2 - wall - 1, 0, plate_t + shell_h / 2]) rotate([0, 90, 0]) hole(rail_port_d, wall + 2);
    }
}

module port_plug() {
    rotate(128) translate([base_d / 2 - wall, 0, plate_t + shell_h / 2]) rotate([0, 90, 0]) {
        translate([0, 0, wall]) cylinder(d = rail_port_d + 4, h = 1.2);
        cylinder(d = rail_port_d - 0.15, h = wall);
        translate([0, 0, -1]) cylinder(d1 = rail_port_d - 1, d2 = rail_port_d + 0.5, h = 1);
    }
}

// deck with the hollow spigot, the hard stop post and the switch wall
module deck() {
    difference() {
        union() {
            translate([0, 0, z_deck]) cylinder(d = base_d, h = deck_t);
            translate([0, 0, zd]) cylinder(d = brg[0] + 4, h = 7);                        // shoulder under the inner race
            translate([0, 0, zd]) cylinder(d = brg[0] + brg_post_fit, h = 7 + brg[2]);    // post
            translate([stop_r, 0, zd]) cylinder(d = 7, h = 19, $fn = 32);                 // hard stop
            rotate(sw_angle) translate([63.2, -11, zd]) cube([4, 22, 13]);                // switch wall
        }
        translate([0, 0, z_deck - 1]) cylinder(d = cable_d, h = 40);
        for (a = [90, 210, 330]) rotate(a) translate([12, 0, zd + 7 + brg[2] - 8]) hole(pilot_m2, 9);
        // NEMA17 on slots: slide the motor away from the axis to tension the belt
        translate([-pan_c, 0, z_deck - 1]) {
            hull() for (dx = [-4, 3]) translate([dx, 0, 0]) cylinder(d = 22.8, h = deck_t + 2);
            for (sx = [-1, 1], sy = [-1, 1]) hull() for (dx = [-4, 3])
                translate([sx * nema_hole / 2 + dx, sy * nema_hole / 2, 0]) hole(clr_m3, deck_t + 2);
        }
        for (a = boss_angles) rotate(a) translate([boss_r, 0, z_deck - 1]) hole(clr_m3, deck_t + 2);
        rotate(sw_angle) for (dy = [-1, 1]) translate([62, dy * sw_hole_pitch / 2, zd + sw_hole_z]) rotate([0, 90, 0]) hole(pilot_m2, 7);
    }
}

module cap() {
    translate([0, 0, zd + 7 + brg[2]]) difference() {
        cylinder(d = brg[0] + 4, h = 2.4);
        translate([0, 0, -1]) cylinder(d = cable_d, h = 5);
        for (a = [90, 210, 330]) rotate(a) translate([12, 0, -1]) hole(clr_m2, 5);
    }
}

// fixed cover around the belt; clamped by the same five screws as the deck
module ring() {
    difference() {
        intersection() {
            union() {
                translate([0, 0, zd]) cylinder(r = 80, h = 2.5);
                translate([0, 0, zd]) cylinder(r = 71.5, h = 22.5);
            }
            cylinder(d = base_d, h = 200);
        }
        translate([0, 0, zd - 1]) cylinder(r = 69, h = 15.5);
        translate([0, 0, zd + 14.49]) cylinder(r1 = 69, r2 = 63.5, h = 5.52);
        translate([0, 0, zd + 20]) cylinder(r = 63.5, h = 5);
        for (a = boss_angles) rotate(a) translate([boss_r, 0, zd - 1]) hole(clr_m3, 5);
    }
}

// ============================= PAN STAGE =============================
// turntable and 80T pulley in one piece; the bearing drops in from the top
module turntable() {
    difference() {
        union() {
            translate([0, 0, zd + 5.2]) cylinder(d = od_big + 3.5, h = 1.3);
            translate([0, 0, zd + 6.5]) cylinder(d1 = od_big + 3.5, d2 = od_big, h = 1.75);
            translate([0, 0, zd + 7.5]) linear_extrude(7.2) gt2_2d(t_big);
            translate([0, 0, zd + 14.5]) cylinder(d = od_big + 3.5, h = z_tt - zd - 14.5);
            translate([0, 0, z_tt]) cylinder(d = tt_d, h = tt_t);
            rotate(180) translate([stop_r - 2.75, -3, zd + 14]) cube([5.5, 6, 6.5]);      // lug that meets the stop post
        }
        translate([0, 0, zd + 7]) cylinder(d = brg[1] + brg_bore_fit, h = 40);             // bearing pocket
        translate([0, 0, zd]) cylinder(d = brg[1] - 3.6, h = 10);                           // lip under the outer race
        for (a = [60, 180, 300]) rotate(a) translate([26.5, 0, z_top]) ins_down([ins_m3[0], tt_t + 0.5]);
        for (sx = [-1, 1], sy = [-1, 1]) translate([sx * 16, sy * (arm_y + arm_t + 6), z_top]) ins_down([ins_m3[0], tt_t + 1]);
        // reach the motor screws through the disc with the head turned to pan = 180
        for (sx = [-1, 1], sy = [-1, 1]) hull() for (dx = [-3, 4])
            translate([pan_c + sx * nema_hole / 2 + dx, sy * nema_hole / 2, z_tt - 1]) hole(6.5, tt_t + 2);
    }
}

module retainer() {
    difference() {
        union() {
            translate([0, 0, zd + 7 + brg[2] + 0.05]) cylinder(d = brg[1] - 0.3, h = z_top - (zd + 7 + brg[2]));
            translate([0, 0, z_top]) linear_extrude(3) hull() {
                circle(d = 50);
                for (a = [60, 180, 300]) rotate(a) translate([26.5, 0]) circle(d = 10);
            }
        }
        translate([0, 0, zd]) cylinder(d = brg[1] - 3.6, h = 60);
        for (a = [60, 180, 300]) rotate(a) translate([26.5, 0, z_top - 1]) hole(clr_m3, 6);
    }
}

// =============================== YOKE ===============================
module arm_profile(servo) {
    hull() {
        translate([-27, 0]) square([54, 2]);
        if (servo) translate([-26 + 6, tilt_h - 12 + 6]) offset(r = 6) square([41 - 12, 24 - 12]);
        else translate([0, tilt_h]) circle(r = 12);
    }
}
module arm(servo) {
    s = servo ? 1 : -1;
    yi = s * arm_y;                       // inner face
    yo = s * (arm_y + arm_t);             // outer face
    xc = servo_shaft_off - servo_len / 2; // servo body centre
    difference() {
        union() {
            translate([0, max(yi, yo), z_top]) rotate([90, 0, 0]) linear_extrude(arm_t) arm_profile(servo);
            intersection() {                                                               // foot, outwards
                translate([-27, min(yo, yo + s * 12), z_top]) cube([54, 12, 5]);
                cylinder(d = tt_d, h = 300);
            }
            for (gx = [-22, 19]) translate([gx, yo, z_top]) rotate([90, 0, 90])           // gussets
                linear_extrude(3) polygon([[0, 0], [s * 10, 0], [s * 10, 5], [0, 20]]);
        }
        for (sx = [-1, 1]) translate([sx * 16, s * (arm_y + arm_t + 6), z_top - 1]) hole(clr_m3, 30);
        for (sx = [-1, 1]) translate([sx * 16, s * (arm_y + arm_t + 6), z_top + 5]) hole(6.4, 30);   // screw head clearance through the gusset zone
        if (servo) {
            translate([xc - servo_len / 2 - tol, yi - 1, z_tilt - servo_w / 2 - tol]) cube([servo_len + 2 * tol, arm_t + 2, servo_w + 2 * tol]);
            for (d = [-1, 1]) translate([xc + d * servo_ear_pitch / 2, yi - 1, z_tilt]) rotate([-90, 0, 0]) hole(pilot_m2, arm_t + 2);
        } else {
            translate([0, yi + 0.01, z_tilt]) rotate([90, 0, 0]) hole(axle_brg[1] + 0.1, axle_brg[2] + 0.1);
            translate([0, yi, z_tilt]) rotate([90, 0, 0]) hole(6.5, arm_t + 1);
        }
    }
}

// =============================== HEAD ===============================
module pod_profile(inset = 0) {
    offset(delta = -inset) hull() for (s = [-1, 1]) {
        translate([s * (p_wb - p_rb), p_z0 + p_rb]) circle(r = p_rb);
        translate([s * (p_wt - p_rt), p_z1 - p_rt]) circle(r = p_rt);
    }
}
// Hull of sections that shrink parabolically towards both ends. The taper
// lengths keep every wall within about 45 degrees of vertical when each
// half is printed standing on its seam.
module pod(inset = 0) {
    n = 10;  xa = hx0 + inset;  xb = hx1 - inset;
    st = concat([for (i = [0 : n]) [xa + htail * i / n, 1 - 0.6 * pow(1 - i / n, 2)]],
                [for (i = [0 : n]) [xb - hnose + hnose * i / n, 1 - 0.4 * pow(i / n, 2)]]);
    hull() for (q = st) translate([q[0], 0, 0]) rotate([90, 0, 90]) linear_extrude(0.01)
        translate([0, p_zc]) scale([q[1], q[1]]) translate([0, -p_zc]) pod_profile(inset);
}
// the lap joint is interrupted beside the trunnions, where the pads are
module side_gap(h) { for (s = [-1, 1]) translate([-100, s > 0 ? 20 : -80, -h]) cube([200, 60, 2 * h]); }

module rails() {
    for (band = [[sled_z - 2.5, sled_z - 0.15], [sled_z + sled_t + 0.15, sled_z + sled_t + 2.5]]) {
        intersection() { difference() { pod(hwall - 0.1); pod(5.0); } translate([-14, -100, band[0]]) cube([13.5, 200, band[1] - band[0]]); }
        intersection() { difference() { pod(hwall - 0.1); pod(3.7); } translate([-0.6, -100, band[0]]) cube([1.4, 200, band[1] - band[0]]); }
    }
}

module head_rear() {
    difference() {
        union() {
            intersection() { difference() { pod(); pod(hwall); } xslab(-200, hseam); }
            intersection() {
                pod(0.01);
                xslab(-200, hseam);
                union() {
                    translate([0, pad_servo_y - 4, 0]) rotate([-90, 0, 0]) cylinder(d = 26, h = 8);       // horn pad
                    translate([0, pad_idle_y + 7, 0]) rotate([90, 0, 0]) cylinder(d = 10, h = 9, $fn = 32); // axle boss
                    for (s = [-1, 1]) hull() {                                                              // chin screw bosses
                        translate([-19, s * 13, -21]) rotate([0, 90, 0]) cylinder(d = 9, h = 10, $fn = 32);
                        translate([1.2, s * 13 - 4.5, p_z0 + hwall - 1]) cube([0.2, 9, 1.2]);
                    }
                    translate([-14, 0, 28]) cylinder(d = 8, h = 14, $fn = 32);                              // antenna socket
                    rails();
                }
            }
        }
        difference() { intersection() { pod(lip_t); xslab(hseam - tongue_len, hseam + 1); } side_gap(13); }  // rebate for the tongue
        // servo side: flat for the horn, with a recess that keys a straight two-arm horn
        translate([0, pad_servo_y, 0]) rotate([-90, 0, 0]) cylinder(d = 24, h = 20);
        translate([0, pad_servo_y - 1.6, 0]) rotate([-90, 0, 0]) linear_extrude(3) hull() for (dx = [-13.5, 13.5]) translate([dx, 0]) circle(d = 7.6, $fn = 32);
        translate([0, pad_servo_y - 6, 0]) rotate([-90, 0, 0]) hole(4, 10);
        // idle side: flat and M3 insert for the axle screw
        translate([0, pad_idle_y, 0]) rotate([90, 0, 0]) cylinder(d = 12, h = 20);
        translate([0, pad_idle_y, 0]) rotate([-90, 0, 0]) ins(ins_m3);
        for (s = [-1, 1]) {                                                                                  // chin screws, driven from behind
            translate([-13, s * 13, -21]) rotate([0, 90, 0]) hole(clr_m3, 30);
            translate([-13, s * 13, -21]) rotate([0, -90, 0]) hole(6.4, 80);
        }
        translate([hseam - tongue_len / 2, 0, 30]) hole(clr_m3, 20);                                         // top seam screw
        translate([-6, 0, p_z0 - 5]) cylinder(d = 14, h = 12);                                               // cables down to the hollow axis
        translate([-14, 0, 29]) hole(3.2, 20);                                                               // 3 mm antenna rod
    }
}

module lugs() {
    for (a = lug_angles) translate([0, 0, eye_z]) rotate([a, 0, 0]) translate([0, 0, -3.5])
        linear_extrude(7) polygon([[40, 31], [40, 25], [44.5, 20.5], [hx1, 20.5], [hx1, 31]]);
}

module head_front() {
    difference() {
        union() {
            difference() {
                union() {
                    intersection() { difference() { pod(); pod(hwall); } xslab(hseam, 200); }
                    difference() {                                                                           // tongue, running on inside the shell
                        intersection() { difference() { pod(lip_t + 0.2); pod(lip_t + 2.4); } xslab(tongue_x0, hseam + 6); }
                        intersection() { side_gap(14); xslab(-200, hseam); }
                    }
                    difference() { translate([34, 0, eye_z]) rotate([0, 90, 0]) cylinder(d = eye_d + 4, h = hx1 + 5 - 34); pod(hwall); }   // eye barrel
                }
                translate([20, 0, eye_z]) rotate([0, 90, 0]) cylinder(d = eye_d, h = 80);                   // eye bore
            }
            intersection() {                                                                                 // lugs that carry the iris plate
                union() { pod(0.01); translate([34, 0, eye_z]) rotate([0, 90, 0]) cylinder(d = eye_d + 4, h = hx1 - 34); }
                lugs();
            }
            intersection() {
                pod(lip_t + 0.2);
                union() {
                    for (s = [-1, 1]) {                                                                      // chin insert bosses
                        translate([tongue_x0, s * 13, -21]) rotate([0, 90, 0]) cylinder(d = 9, h = 14, $fn = 32);
                        translate([tongue_x0, s * 13 - 4.5, -28]) cube([14, 9, 7]);
                    }
                    translate([tongue_x0, -5, 31]) cube([tongue_len + 2, 10, 10]);                           // top seam block
                }
            }
        }
        for (s = [-1, 1]) translate([tongue_x0, s * 13, -21]) rotate([0, 90, 0]) ins(ins_m3);
        translate([hseam - tongue_len / 2, 0, p_z1 - lip_t - 0.15]) ins_down(ins_m3);
        for (a = lug_angles) translate([0, 0, eye_z]) rotate([a, 0, 0]) translate([hx1, lug_r, 0]) rotate([0, -90, 0]) ins(ins_m2);
    }
}

// camera carrier and LED diffuser: print in white or translucent filament
module iris() {
    eye_frame(hx1) difference() {
        union() {
            cylinder(d = eye_d - 0.4, h = 2);
            for (p = cam_hole_yz) translate([p[0], p[1] , -4.5]) cylinder(d = 6.4, h = 4.5, $fn = 32);
        }
        translate([0, 0, -1]) cylinder(d = 11, h = 4);                                                       // lens
        translate([0, 0, 1.2]) cylinder(d1 = 11, d2 = 13, h = 0.81);
        for (p = cam_hole_yz) translate([p[0], p[1], -4.5]) ins(ins_m2);
        for (a = lug_angles) rotate(a) translate([lug_r, 0, -1]) hole(clr_m2, 4);
        for (a = led_angles) rotate(a) translate([21, 0, -0.01]) hole(led_d, 1.21);
    }
}

// dark ring with the two fixed lids; pushes over the end of the barrel
module bezel() {
    eye_frame(hx1) {
        translate([0, 0, 0.5]) tube(eye_d + 8.3, eye_d + 4.3, 4.5);
        translate([0, 0, 5]) linear_extrude(2) {
            difference() { circle(d = eye_d + 8.3); circle(d = eye_d - 1); }
            intersection() { circle(d = eye_d - 0.8); translate([-50, 0.22 * eye_d]) square([100, 50]); }
            intersection() { circle(d = eye_d - 0.8); translate([-50, -50 - 0.36 * eye_d]) square([100, 50]); }
        }
    }
}

// tray for the Pi Zero 2: slides into the rails of the rear half
module sled() {
    difference() {
        union() {
            intersection() { translate([-30, -100, sled_z]) cube([32, 200, sled_t]); pod(hwall + 0.3); }
            intersection() { translate([2, -100, sled_z]) cube([34, 200, sled_t]); pod(lip_t + 2.4 + 0.3); }
            for (p = pi_hole_xy) translate([p[0], p[1], sled_z + sled_t]) cylinder(d = 6.2, h = 3.5, $fn = 32);
        }
        for (p = pi_hole_xy) translate([p[0], p[1], sled_z + sled_t + 3.5]) ins_down(ins_m25);
        translate([-18, -7, sled_z - 1]) cube([42, 14, sled_t + 2]);                                         // cables and weight
        for (s = [-1, 1]) translate([-10, s * 24 - 5, sled_z - 1]) cube([26, 10, sled_t + 2]);
    }
}

module spacer() { translate([0, pad_idle_y, 0]) rotate([90, 0, 0]) tube(5.4, 3.3, arm_y + pad_idle_y); }

// test coupon: insert holes at -0.2 / nominal / +0.2, bearing post and pocket
module gauge() {
    difference() {
        cube([64, 20, 8]);
        for (i = [0 : 2]) {
            translate([6 + i * 7, 5, 8]) ins_down([ins_m3[0] + (i - 1) * 0.2, ins_m3[1]]);
            translate([30 + i * 7, 5, 8]) ins_down([ins_m25[0] + (i - 1) * 0.2, ins_m25[1]]);
            translate([52 + i * 5, 5, 8]) ins_down([ins_m2[0] + (i - 1) * 0.2, ins_m2[1]]);
        }
        translate([6, 13, 7.4]) linear_extrude(1) text("M3", size = 5);
        translate([30, 13, 7.4]) linear_extrude(1) text("M2.5", size = 5);
        translate([52, 13, 7.4]) linear_extrude(1) text("M2", size = 4);
    }
    translate([20, 50, 0]) { cylinder(d = brg[0] + 8, h = 2); cylinder(d = brg[0] + brg_post_fit, h = 2 + brg[2]); }
    translate([20, 100, 0]) difference() { cylinder(d = brg[1] + 8, h = 2 + brg[2]); translate([0, 0, 2]) cylinder(d = brg[1] + brg_bore_fit, h = 10); }
}

// ============================== VITAMINS ==============================
module v_nema() translate([-pan_c, 0, z_deck]) {
    color(C_BLACK) translate([-nema_w / 2, -nema_w / 2, -nema_len]) cube([nema_w, nema_w, nema_len]);
    color(C_METAL) cylinder(d = 22, h = 2);
    color(C_METAL) cylinder(d = 5, h = shaft_len);
    color(C_METAL) translate([0, 0, deck_t + 0.5]) cylinder(d = 14, h = 7);
    color(C_METAL) translate([0, 0, deck_t + 7.5]) cylinder(d = gt2_od(t_small), h = 7.5);
    color(C_METAL) for (z = [7.5, 15]) translate([0, 0, deck_t + z]) cylinder(d = 15, h = 1);
}
module v_belt() color(C_BLACK) translate([0, 0, zd + 8.4]) linear_extrude(6) difference() {
    hull() { circle(d = d_big + 1.6); translate([-pan_c, 0]) circle(d = d_small + 1.6); }
    hull() { circle(d = d_big - 1.0); translate([-pan_c, 0]) circle(d = d_small - 1.0); }
}
module v_bearing() color(C_METAL) translate([0, 0, zd + 7]) tube(brg[1], brg[0], brg[2]);
module v_servo() color("#2a5db0") translate([servo_shaft_off - servo_len, arm_y + arm_t, z_tilt - servo_w / 2]) {
    cube([servo_len, 18.4, servo_w]);
    translate([-4.75, 0, 0]) cube([32.3, 2.5, servo_w]);
    translate([0, -4.6, 0]) cube([servo_len, 4.6, servo_w]);
    translate([servo_len - servo_shaft_off, -4.6, servo_w / 2]) rotate([90, 0, 0]) cylinder(d = 11.5, h = 4, $fn = 32);
    translate([servo_len - servo_shaft_off, -8.6, servo_w / 2]) rotate([90, 0, 0]) cylinder(d = 4.8, h = 3.2, $fn = 32);
}
module v_switch() color("#c0392b") rotate(sw_angle) translate([56.8, -10, zd + 2.3]) cube([6.4, 20, 10.2]);
module v_proto() {
    color("#1f6f8b") translate([proto_pos[0] - proto[0] / 2, proto_pos[1] - proto[1] / 2, plate_t + proto_so]) cube([proto[0], proto[1], 1.6]);
    color(C_PCB) translate([proto_pos[0] + 2, proto_pos[1] - 25.5, plate_t + proto_so + 4]) cube([21, 51, 1.6]);     // Pico
    color(C_BLACK) for (dy = [-24, 4]) translate([proto_pos[0] - 20, proto_pos[1] + dy, plate_t + proto_so + 1.6]) cube([15, 20, 12]);
}
module v_pi() color(C_PCB) translate([pi_pos_x - 32.5, -15, sled_z + sled_t + 3.5]) cube([65, 30, 1.6]);
module v_camera() eye_frame(hx1) color(C_PCB) {
    translate([-12.5, cam_cz + (cam_connector_up ? -(9.46 - 1.2) - 0 : -(14.4 + 1.2)) , -5.6]) cube([25, 23.86, 1.1]);
    color(C_BLACK) translate([-4, -4, -4.5]) cube([8, 8, 5]);
}

// ============================== ASSEMBLY ==============================
module assembly() {
    color(C_DARK) plate();
    color(C_DARK) shell();
    color(C_DARK) port_plug();
    color(C_DARK) deck();
    color(C_DARK) cap();
    color(C_DARK) ring();
    v_nema(); v_belt(); v_bearing(); v_switch(); v_proto();
    rotate(pan) {
        color(C_PRINT) turntable();
        color(C_DARK) retainer();
        color(C_PRINT) arm(true);
        color(C_PRINT) arm(false);
        v_servo();
        translate([0, 0, z_tilt]) rotate([0, -tilt, 0]) {
            color(C_PRINT) head_rear();
            color(C_PRINT) head_front();
            color(C_LIGHT) iris();
            color(C_DARK) bezel();
            color(C_LIGHT) sled();
            color(C_METAL) spacer();
            v_pi(); v_camera();
        }
    }
}

// a single part in its own frame (base and turntable frame, or head frame)
module raw(p) {
    if (p == "plate") plate();            else if (p == "shell") shell();
    else if (p == "deck") deck();         else if (p == "cap") cap();
    else if (p == "ring") ring();         else if (p == "port_plug") port_plug();
    else if (p == "turntable") turntable(); else if (p == "retainer") retainer();
    else if (p == "arm_servo") arm(true); else if (p == "arm_idle") arm(false);
    else if (p == "head_rear") head_rear(); else if (p == "head_front") head_front();
    else if (p == "iris") iris();         else if (p == "bezel") bezel();
    else if (p == "sled") sled();         else if (p == "spacer") spacer();
}

// ============================ PRINT POSES ============================
if (as_built) raw(part);
else if (part == "assembly") {
    if (cutaway) difference() { assembly(); translate([-500, -1000, -500]) cube(1000); }
    else assembly();
}
else if (part == "plate")      plate();
else if (part == "shell")      translate([0, 0, -plate_t]) shell();
else if (part == "deck")       translate([0, 0, -z_deck]) deck();
else if (part == "cap")        translate([0, 0, -(zd + 7 + brg[2])]) cap();
else if (part == "ring")       translate([0, 0, -zd]) ring();
else if (part == "turntable")  rotate([180, 0, 0]) translate([0, 0, -z_top]) turntable();
else if (part == "retainer")   rotate([180, 0, 0]) translate([0, 0, -(z_top + 3)]) retainer();
else if (part == "arm_servo")  translate([0, 0, -arm_y]) rotate([90, 0, 0]) translate([0, 0, -z_top]) arm(true);
else if (part == "arm_idle")   translate([0, 0, -arm_y]) rotate([-90, 0, 0]) translate([0, 0, -z_top]) arm(false);
else if (part == "head_rear")  translate([0, 0, hseam]) rotate([0, 90, 0]) head_rear();
else if (part == "head_front") translate([0, 0, -tongue_x0]) rotate([0, -90, 0]) head_front();
else if (part == "iris")       translate([0, 0, hx1 + 2]) rotate([0, 90, 0]) iris();
else if (part == "bezel")      translate([0, 0, hx1 + 7]) rotate([0, 90, 0]) bezel();
else if (part == "sled")       translate([0, 0, -sled_z]) sled();
else if (part == "spacer")     translate([0, 0, pad_idle_y]) rotate([-90, 0, 0]) spacer();
else if (part == "port_plug")  translate([0, 0, base_d / 2 + 1.2]) rotate([0, 90, 0]) rotate(-128) port_plug();
else if (part == "gauge")      gauge();
// interference probes: an empty result means the two parts do not touch
else if (part == "x_head")       intersection() { head_rear(); head_front(); }
else if (part == "x_sled_rear")  intersection() { head_rear(); sled(); }
else if (part == "x_sled_front") intersection() { head_front(); sled(); }
else if (part == "x_iris")       intersection() { head_front(); iris(); }
else if (part == "x_tt_deck")    intersection() { turntable(); union() { deck(); ring(); v_nema(); v_switch(); } }
else if (part == "x_yoke_head")  intersection() { union() { arm(true); arm(false); turntable(); retainer(); }
                                                  translate([0, 0, z_tilt]) rotate([0, -tilt, 0]) union() { head_rear(); head_front(); bezel(); } }
