// =====================================================================
//  Strix v0.1 - desktop turret robot, parametric CONCEPT model
//  Units: mm.  Z = pan axis.  Front = +X.  Rail runs along Y.
//
//  This is a layout model (volumes, heights, clearances), not a set of
//  print-ready parts: fasteners, fit tolerances and cable routing are
//  still missing.
//
//  Colours:  orange/dark grey = 3D printed   |  wood  = laser cut
//            silver/black     = off the shelf |  green = electronics
// =====================================================================

$fn = 72;

/* [View] */
pan           = 30;     // head pan (degrees, limit +-170)
tilt          = 12;     // elevation (degrees, -15 .. +35)
show_launcher = true;   // false = sensor-only head (phase 1)
show_rail     = false;  // true  = rail module (phase 3)
rail_pos      = -110;   // carriage position along the rail
explode       = 0;      // 0 = assembled, 1 = exploded
cutaway       = false;  // lengthwise section through the housings (use with pan=0)

/* [Base] */
base_d     = 160;
wall       = 3;
plate_t    = 4;      // bottom plate (laser cut)
base_int_h = 46;     // clear height inside the base
deck_t     = 5;      // top deck (laser cut)
foot_h     = 5;
mount_sq   = 100;    // 4xM4 pattern: rubber feet or rail carriage

/* [Pan drive] */
brg_id = 30; brg_od = 42; brg_w = 7;   // 6806-2RS bearing
t_big   = 80;     // teeth, printed pulley (turntable)
t_small = 20;     // teeth, motor pulley (the one fitted to Ender 3 X/Y motors)
belt_len = 200;   // closed-loop GT2 belt
cable_d  = 20;    // cable bore through the hollow axis
nema_w = 42.3; nema_len = 34; shaft_len = 24;

/* [Head] */
tt_d   = 110;     // turntable
tilt_h = 62;      // tilt axis height above the turntable
cr_w   = 80;      // cradle width
arm_t  = 5; arm_gap = 2;

/* [Rail] */
rail_len    = 600;
rail_gap    = 10;    // gap between extrusion and carriage (the belt runs here)
wheel_d     = 23.9;  wheel_w = 10.2;
wheel_span  = 59.7;  // V-wheel axle spacing across the 40 mm face (verify)

// ---------------- derived ----------------
function pitch_d(t) = t * 2 / PI;
d_big = pitch_d(t_big);  d_small = pitch_d(t_small);
K = belt_len - PI * (d_big + d_small) / 2;
pan_c = (K + sqrt(K * K - 2 * pow(d_big - d_small, 2))) / 4;   // centre distance

z_deck = plate_t + base_int_h;   // underside of the deck
zd     = z_deck + deck_t;        // top of the deck
belt_z = zd + 11;
z_tt   = zd + 20;  tt_t = 4;
z_top  = z_tt + tt_t;
z_tilt = z_top + tilt_h;

echo(str("PAN: centre distance = ", pan_c, " mm, reduction ", t_big / t_small, ":1"));
echo(str("HEIGHT of tilt axis = ", z_tilt + foot_h, " mm; overall height approx = ", z_tilt + 70 + foot_h, " mm"));
echo(str("RAIL: usable travel approx = ", rail_len - base_d - 40, " mm"));

C_PRINT = "#e8792b";  C_PRINT2 = "#3a3f47";  C_WOOD = "#d9b98a";
C_METAL = "#b9bec6";  C_BLACK = "#22252a";   C_PCB = "#2e8b57";
C_DART  = "#ff9f1c";

// simple chamfered box
module cbox(x0, x1, w, z0, z1, c = 4) {
    hull() {
        translate([x0 + c, -w / 2, z0]) cube([x1 - x0 - 2 * c, w, z1 - z0]);
        translate([x0, -w / 2 + c, z0 + c]) cube([x1 - x0, w - 2 * c, z1 - z0 - 2 * c]);
    }
}
// section cut: applied to housings only, components stay whole
module cutY() { if (cutaway) difference() { children(); translate([-500, -1000, -500]) cube(1000); } else children(); }
module tube(od, id, h) { difference() { cylinder(d = od, h = h); translate([0, 0, -1]) cylinder(d = id, h = h + 2); } }
module nema17(len = nema_len) {
    // mounting face at z=0, shaft towards +Z
    color(C_BLACK) translate([-nema_w / 2, -nema_w / 2, -len]) cube([nema_w, nema_w, len]);
    color(C_METAL) cylinder(d = 22, h = 2);
    color(C_METAL) cylinder(d = 5, h = shaft_len);
}

// =============================== BASE ===============================
module base_bottom() {
    color(C_WOOD) cutY() difference() {
        cylinder(d = base_d, h = plate_t);
        for (sx = [-1, 1], sy = [-1, 1]) translate([sx * mount_sq / 2, sy * mount_sq / 2, -1]) cylinder(d = 4.3, h = plate_t + 2);
    }
    if (!show_rail)
        color(C_BLACK) for (sx = [-1, 1], sy = [-1, 1]) translate([sx * mount_sq / 2, sy * mount_sq / 2, -foot_h]) cylinder(d1 = 12, d2 = 15, h = foot_h);
}

module base_shell() {
    color(C_PRINT2) cutY() difference() {
        translate([0, 0, plate_t]) tube(base_d, base_d - 2 * wall, base_int_h);
        // side vents
        for (a = [50 : 10 : 130], s = [-1, 1]) rotate([0, 0, s * a])
            translate([base_d / 2 - wall - 1, -1.5, plate_t + 10]) cube([wall + 2, 3, base_int_h - 20]);
        // rear panel: DC jack, USB, arming switch
        rotate([0, 0, 180]) translate([base_d / 2 - wall - 1, 0, plate_t]) {
            translate([0, -22, 14]) rotate([0, 90, 0]) cylinder(d = 8, h = wall + 2);
            translate([0, -6, 10]) cube([wall + 2, 12, 6]);
            translate([0, 16, 8]) cube([wall + 2, 13, 19]);
        }
    }
    // side connector reserved for the rail (motor + endstop)
    color(C_METAL) rotate([0, 0, 155]) translate([base_d / 2 - 2, -8, plate_t + 8]) cube([4, 16, 10]);
}

module deck() {
    color(C_WOOD) cutY() difference() {
        translate([0, 0, z_deck]) cylinder(d = base_d, h = deck_t);
        translate([0, 0, z_deck - 1]) cylinder(d = cable_d, h = deck_t + 2);
        // motor shaft slot (belt tensioning)
        hull() for (dx = [-4, 4]) translate([-pan_c + dx, 0, z_deck - 1]) cylinder(d = 23, h = deck_t + 2);
    }
}

module pan_motor() {
    translate([-pan_c, 0, z_deck]) nema17();
    // motor pulley, hub down
    color(C_METAL) translate([-pan_c, 0, 0]) {
        translate([0, 0, zd + 0.5]) cylinder(d = 14, h = 6.5);
        translate([0, 0, zd + 7]) cylinder(d = 13.5, h = 0.8);
        translate([0, 0, zd + 7.5]) cylinder(d = d_small - 0.5, h = 7);
        translate([0, 0, zd + 14.5]) cylinder(d = 13.5, h = 0.8);
    }
}

module pan_belt() {
    color(C_BLACK) cutY() translate([0, 0, belt_z - 3]) linear_extrude(6) difference() {
        hull() { circle(d = d_big + 1.6); translate([-pan_c, 0]) circle(d = d_small + 1.6); }
        hull() { circle(d = d_big - 1.0); translate([-pan_c, 0]) circle(d = d_small - 1.0); }
    }
}

module spigot() {
    // fixed hollow spigot: holds the bearing inner race
    color(C_PRINT) cutY() difference() {
        union() {
            translate([0, 0, zd]) cylinder(d = 48, h = 2);
            translate([0, 0, zd]) cylinder(d = brg_id + 4, h = 7);
            translate([0, 0, zd]) cylinder(d = brg_id, h = 14);
        }
        translate([0, 0, zd - 1]) cylinder(d = cable_d, h = 20);
    }
    // cap that retains the inner race
    color(C_PRINT) cutY() translate([0, 0, zd + 14]) tube(brg_id + 4, cable_d, 2);
}

module bearing() {
    color(C_METAL) cutY() translate([0, 0, zd + 7]) tube(brg_od, brg_id, brg_w);
}

module turret_ring() {
    // fixed ring that hides the belt and keeps fingers out
    color(C_PRINT2) cutY() difference() {
        translate([0, 0, zd]) cylinder(d = 132, h = 19.5);
        translate([0, 0, zd - 1]) cylinder(d = 126, h = 18.5);
        translate([0, 0, zd]) cylinder(d = tt_d + 3, h = 30);
    }
}

module turntable() {
    // turntable + 80T pulley printed as one part
    color(C_PRINT) cutY() difference() {
        union() {
            translate([0, 0, zd + 7]) cylinder(d = d_big - 0.5, h = 13);
            translate([0, 0, z_tt]) cylinder(d = tt_d, h = tt_t);
            translate([0, 0, z_tt - 2]) cylinder(d1 = d_big + 3, d2 = d_big + 7, h = 2);
        }
        translate([0, 0, zd + 6]) cylinder(d = brg_od, h = brg_w + 1);          // bearing pocket
        translate([0, 0, zd]) cylinder(d = brg_od - 4, h = 40);                 // centre bore
        for (i = [0 : t_big - 1]) rotate([0, 0, i * 360 / t_big])               // teeth (cosmetic)
            translate([d_big / 2 - 0.9, -0.5, zd + 7.5]) cube([1.2, 1, 7]);
    }
    // lower ring: retains the outer race and acts as belt flange
    color(C_PRINT) cutY() translate([0, 0, zd + 5]) tube(d_big + 4, brg_od - 3, 2);
}

module yoke() {
    y0 = cr_w / 2 + arm_gap;
    for (s = [-1, 1]) color(C_PRINT) cutY() difference() {
        hull() {
            translate([-27, s * (y0 + arm_t / 2) - arm_t / 2, z_top]) cube([54, arm_t, 2]);
            translate([0, s * (y0 + arm_t / 2), z_tilt]) rotate([90, 0, 0]) cylinder(r = 14, h = arm_t, center = true);
        }
        translate([0, s * (y0 + arm_t / 2), z_tilt]) rotate([90, 0, 0]) cylinder(d = 8, h = arm_t + 2, center = true);
        // lightening slot
        hull() {
            translate([0, s * (y0 + arm_t / 2), z_top + 14]) rotate([90, 0, 0]) cylinder(r = 9, h = arm_t + 2, center = true);
            translate([0, s * (y0 + arm_t / 2), z_tilt - 24]) rotate([90, 0, 0]) cylinder(r = 5, h = arm_t + 2, center = true);
        }
    }
    // tilt servo (MG90S) on the +Y arm
    color("#2a5db0") translate([-17, y0 + arm_t, z_tilt - 6.2]) cube([22.8, 22.7, 12.4]);
    // trunnion bearing on the -Y arm
    if (!cutaway) color(C_METAL) translate([0, -(y0 + arm_t), z_tilt]) rotate([90, 0, 0]) cylinder(d = 14, h = 3);
}

// =============================== HEAD ===============================
module eye(x, z) {
    // USB camera + LED ring
    color(C_PCB) translate([x - 7, -16, z - 16]) cube([2, 32, 32]);
    color(C_BLACK) translate([x - 5, 0, z]) rotate([0, 90, 0]) cylinder(d = 14, h = 10);
    color("#f4f4f4") translate([x, 0, z]) rotate([0, 90, 0]) tube(37, 24, 2.5);
    // ToF distance sensor
    color(C_BLACK) translate([x - 1, 24, z - 8]) cube([2.5, 11, 16]);
}

module cradle_launcher() {
    x0 = -62; x1 = 78; z0 = -32; z1 = 34;
    color(C_PRINT) cutY() difference() {
        cbox(x0, x1, cr_w, z0, z1);
        cbox(x0 + 2.4, x1 - 2.4, cr_w - 4.8, z0 + 2.4, z1 - 2.4, 3);
        translate([x1 - 6, 0, -18]) rotate([0, 90, 0]) cylinder(d = 15, h = 12);     // muzzle
        translate([x1 - 6, 0, 13]) rotate([0, 90, 0]) cylinder(d = 16, h = 12);      // lens
        translate([-42, -9.5, 0]) cube([79, 19, 60]);                                // magazine well
    }
    // trunnions
    color(C_PRINT) cutY() for (s = [-1, 1]) translate([0, s * (cr_w / 2 + 4), 0]) rotate([90, 0, 0]) cylinder(d = 7.6, h = 10, center = true);
    eye(x1, 13);
    // barrel
    color(C_PRINT2) cutY() translate([64, 0, -18]) rotate([0, 90, 0]) tube(20, 14, 22);
    // flywheels + 130-size motors
    for (s = cutaway ? [1] : [-1, 1]) {
        color(C_BLACK) translate([51, s * 20.75, -24]) cylinder(d = 32, h = 12);
        color(C_METAL) translate([51, s * 20.75, -12]) cylinder(d = 20, h = 25);
    }
    // gravity-fed magazine (6 darts) + chambered dart
    color(C_PRINT2) cutY() difference() {
        translate([-42, -9.5, -11]) cube([79, 19, 81]);
        translate([-40.4, -7.9, -12]) cube([75.8, 15.8, 84]);
    }
    color(C_DART) translate([-39, 0, -18]) rotate([0, 90, 0]) cylinder(d = 12.7, h = 73);
    color(C_DART) for (i = [0 : 5]) translate([-39, 0, -5 + i * 13]) rotate([0, 90, 0]) cylinder(d = 12.7, h = 73);
    // pusher servo
    color("#2a5db0") translate([-60, -12, -30]) cube([17, 23, 24]);
    color(C_METAL) translate([-43, 0, -18]) rotate([0, 90, 0]) cylinder(d = 5, h = 5);
}

module cradle_sensor() {
    x0 = -34; x1 = 46; z0 = -25; z1 = 25;
    color(C_PRINT) cutY() difference() {
        cbox(x0, x1, cr_w, z0, z1, 6);
        cbox(x0 + 2.4, x1 - 2.4, cr_w - 4.8, z0 + 2.4, z1 - 2.4, 5);
        translate([x1 - 6, 0, 0]) rotate([0, 90, 0]) cylinder(d = 16, h = 12);
    }
    color(C_PRINT) cutY() for (s = [-1, 1]) translate([0, s * (cr_w / 2 + 4), 0]) rotate([90, 0, 0]) cylinder(d = 7.6, h = 10, center = true);
    eye(x1, 0);
}

// ============================ ELECTRONICS ============================
module electronics() {
    // brain (Raspberry Pi 4/5 or similar)
    color(C_PCB) translate([4, -42.5, plate_t + 5]) cube([56, 85, 2]);
    color(C_METAL) translate([8, 22, plate_t + 7]) cube([48, 18, 14]);
    // motor controller (ESP32 + 2 TMC2209 drivers), stacked on top
    color("#1f6f8b") translate([8, -32, plate_t + 27]) cube([48, 64, 2]);
    color(C_BLACK) for (dy = [-20, 4]) translate([16, dy, plate_t + 29]) cube([15, 20, 10]);
    // 12 V -> 5 V buck converter
    color("#7a3fa0") translate([-38, 42, plate_t + 3]) cube([45, 22, 14]);
}

// =============================== RAIL ===============================
module vwheel() { color(C_BLACK) rotate_extrude() polygon([[2.5, -wheel_w / 2], [wheel_d / 2 - 3, -wheel_w / 2], [wheel_d / 2, -1.5], [wheel_d / 2, 1.5], [wheel_d / 2 - 3, wheel_w / 2], [2.5, wheel_w / 2]]); }

module rail_system() {
    car_t = 5;
    z_rt = -car_t - rail_gap;         // top face of the extrusion
    // 2040 V-slot extrusion lying flat (40 wide, 20 tall)
    color(C_METAL) difference() {
        translate([-20, -rail_len / 2, z_rt - 20]) cube([40, rail_len, 20]);
        for (sx = [-10, 10]) translate([sx - 3.1, -rail_len / 2 - 1, z_rt - 5]) cube([6.2, rail_len + 2, 6]);
        for (sx = [-1, 1]) translate([sx * 20 - 3, -rail_len / 2 - 1, z_rt - 13.1]) cube([6, rail_len + 2, 6.2]);
    }
    // printed end brackets: raise the extrusion and carry motor / idler
    for (s = [-1, 1]) color(C_PRINT) translate([-32, s * (rail_len / 2 + 19) - 19, z_rt - 30]) difference() {
        cube([64, 38, 30]);
        translate([11.5, s > 0 ? -1 : 25, 9.5]) cube([41, 14, 21]);
    }
    // motor end: NEMA17 shaft-down + 20T pulley
    translate([0, rail_len / 2 + 19, z_rt + 14]) {
        color(C_PRINT) translate([-28, -19, 0]) cube([56, 38, 4]);
        color(C_PRINT) for (sx = [-1, 1]) translate([sx * 26 - 3, -19, -14]) cube([6, 38, 14]);
        translate([0, 0, 4]) rotate([180, 0, 0]) nema17();
        color(C_METAL) translate([0, 0, -13]) cylinder(d = 12.7, h = 9);
    }
    // idler end: tensioner pulley
    color(C_METAL) translate([0, -rail_len / 2 - 19, z_rt + 1]) cylinder(d = 12.7, h = 9);
    // open GT2 belt, on edge, above the extrusion
    color(C_BLACK) for (sx = [-1, 1]) translate([sx * 6.4 - 0.7, -rail_len / 2 - 19, z_rt + 2.5]) cube([1.4, rail_len + 38, 6]);
    // endstop
    color("#c0392b") translate([22, -rail_len / 2 + 2, z_rt]) cube([8, 16, 8]);

    // carriage
    translate([0, rail_pos, 0]) {
        color(C_WOOD) translate([0, 0, -car_t]) linear_extrude(car_t) offset(r = 8) square([96, 134], center = true);
        for (sx = [-1, 1], sy = [-1, 1]) translate([sx * wheel_span / 2, sy * 55, 0]) {
            translate([0, 0, z_rt - 10]) vwheel();
            color(C_METAL) translate([0, 0, z_rt - 10 + wheel_w / 2]) cylinder(d = 9, h = -car_t - (z_rt - 10 + wheel_w / 2));
        }
        // belt clamp
        color(C_PRINT) translate([3, -12, z_rt + 1.5]) cube([8, 24, rail_gap - 1.5]);
    }
}

// ============================= ASSEMBLY =============================
module robot() {
    e = explode;
    translate([0, 0, -45 * e]) base_bottom();
    base_shell();
    electronics();
    translate([0, 0, 22 * e]) pan_motor();
    translate([0, 0, 50 * e]) deck();
    translate([0, 0, 75 * e]) { spigot(); bearing(); }
    translate([0, 0, 75 * e]) pan_belt();
    translate([0, 0, 62 * e]) turret_ring();
    rotate([0, 0, pan]) {
        translate([0, 0, 105 * e]) turntable();
        translate([0, 0, 125 * e]) yoke();
        translate([0, 0, z_tilt + 175 * e]) rotate([0, -tilt, 0])
            if (show_launcher) cradle_launcher(); else cradle_sensor();
    }
}

module all() {
    if (show_rail) { rail_system(); translate([0, rail_pos, 0]) robot(); }
    else robot();
}

all();
