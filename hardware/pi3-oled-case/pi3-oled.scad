/* =====================================================================
   Raspberry Pi 3 (B / B+) half-case  +  integrated raised OLED stand
   ---------------------------------------------------------------------
   ONE printable unit:
     - open-top tray for the Pi, board located by chamfered PEGS that
       slip into the Pi's mounting holes (drop on / pop off, no screws)
     - a RAISED, HOLLOW pedestal holding the OLED flat, screen up
     - two flanges with counterbored holes to screw the case to a desk

   WIRE PATH (side section, not to scale):

        ___________  <- OLED PCB, pins pointing DOWN
       |  |     |  |
       |  |  ^  |  |    hollow pedestal interior
       |  |  |  |  |
    ___|  |  |  |  |
   | Pi|__|  |  |  |
   |  []-----'  |  |  <- doorway through pedestal front wall
   |  GPIO   ^  |  |     + notch through tray back wall
   |_________|__|__|

   Units: millimetres. Prints flat as modelled; no supports needed.

   HONEST NOTES:
   - Pi 3 board + mounting-hole geometry is standardised and exact here.
   - The OLED module is NOT standardised. MEASURE yours and set
     oled_w / oled_h / oled_t.
   - oled_clear is the fit-critical number: headroom under the PCB for
     the pins plus the connector housing. Measure a plugged-in
     connector before printing the whole thing.
   - The board rests on FOUR CORNER PADS. All four edges and the whole
     underside are open, so the header can sit on any edge in any
     rotation and still pass straight down into the cavity.
   - 180 deg display rotation is free in software (SSD1306 segment
     remap; luma.oled rotate=2, Adafruit display.rotation=2). Avoid
     rotating 90 deg in software -- a 128x64 panel rendered into a
     64x128 area loses its aspect fit.
   ===================================================================== */

/* ---------- What to render ---------- */
part      = "both";     // "tray" | "oled" | "both"
oled_stub = false;      // with part="oled": print only a short collar of
                        //   the pocket instead of the full column. Fit-
                        //   tests the PCB in a few minutes, not an hour.
stub_h    = 6;          // how much of the pocket the collar keeps

/* ---------- Raspberry Pi 3 B/B+  (standardised — verified) ---------- */
pi_len      = 85;       // board length  (X)
pi_wid      = 56;       // board width   (Y)
hole_inset  = 3.5;      // holes 3.5 mm from the board edges
hole_dx     = 58;       // hole spacing along the length
hole_dy     = 49;       // hole spacing along the width

/* ---------- Tray ---------- */
base_t      = 2.5;
wall_t      = 2.4;
wall_h      = 8;
clearance   = 0.6;
corner_r    = 3;
standoff_h  = 6;
standoff_od = 6;

/* ---------- Locating pegs (replace screws) ---------- */
peg_d       = 2.5;      // Pi holes are ~2.75; locates but pops out
peg_h       = 3.0;
peg_cham    = 0.6;

/* ---------- Port windows (generous; verify on first print) ---------- */
win_bottom_from = 6;
win_bottom_to   = 56;
win_right_from  = 3;
win_right_to    = 53;
sd_from         = 18;
sd_to           = 34;

/* ---------- Desk-mount flanges ---------- */
tab_len     = 14;
tab_w       = 16;
tab_t       = 4;
tab_overlap = 2.5;
tab_hole_d  = 4.2;
tab_cb_d    = 8.0;
tab_cb_h    = 2.2;
tab_y       = pi_wid/2;

/* ---------- OLED stand — MEASURE YOURS ---------- */
oled_w      = 28;       // PCB width
oled_h      = 27;       // PCB height
oled_t      = 1.5;      // PCB thickness
o_slop      = 0.5;      // pocket looseness

oled_clear  = 25;       // *** headroom under the PCB for pins + connector
                        //   ~25 straight header + Dupont housing + bend
                        //   ~12 if you switch to right-angle headers
                        //   ~30 if your wires are stiff

o_wall      = 2.5;      // pedestal / lip wall thickness
o_pad       = 4.0;      // corner support pad size (square). All four
                        //   board edges stay clear. Shrink if the pads
                        //   foul components at your board's corners.
o_lip       = 2.0;      // lip height above the board face
o_finger    = 12;       // finger-notch width, in the FRONT/BACK lip
ped_floor   = 2.5;      // closed floor at the very bottom (0 = open)

door_flat   = 10;       // flat span at the top of the doorway.
                        //   the rest is chamfered 45 deg so it prints
                        //   without supports. raise toward door_w for a
                        //   wider opening (longer bridge).
door_drop   = 3;        // gap between doorway top and the board

retain_tabs = true;     // snap tabs over the LEFT/RIGHT board edges.
                        //   deliberately not front/back: that is where
                        //   your header's plastic spacer likely sits.
tab_grip    = 0.8;
tab_grip_w  = 8;

holder_center  = true;  // centre the pedestal on the tray's long axis.
                        //   false = use holder_x_manual below.
holder_x_manual = 0;    // left edge of the pedestal, when not centred.
                        //   0 lines it up with the Pi board's left edge.
holder_overlap = 3;     // overlap into the tray back wall (fusion)

$fn = 48;

/* ---- derived ---- */
Wx       = oled_w + o_slop + 2*o_wall;
Dy       = oled_h + o_slop + 2*o_wall;
// tray outer footprint (same expressions tray() uses internally)
tray_x0  = -(clearance + wall_t);
tray_ow  = pi_len + 2*(clearance + wall_t);
holder_x = holder_center ? tray_x0 + (tray_ow - Wx)/2 : holder_x_manual;
top_z    = oled_clear + oled_t + o_lip;
pkt_w    = oled_w + o_slop;                  // pocket / shaft footprint X
pkt_d    = oled_h + o_slop;                  // pocket / shaft footprint Y
door_x0  = o_wall + o_pad;                   // doorway X start
door_w   = pkt_w - 2*o_pad;                  // doorway width
door_top = oled_clear - door_drop;
door_ch  = max(0, (door_w - door_flat) / 2); // 45 deg chamfer rise
hold_y0  = pi_wid + clearance + wall_t - holder_overlap;

/* ===================================================================== */
module rounded_box(x, y, z, r) {
    hull() for (ix = [r, x - r], iy = [r, y - r])
        translate([ix, iy, 0]) cylinder(r = r, h = z);
}

module post() {
    cylinder(d = standoff_od, h = standoff_h);
    translate([0, 0, standoff_h]) {
        cylinder(d = peg_d, h = peg_h - peg_cham);
        translate([0, 0, peg_h - peg_cham])
            cylinder(d1 = peg_d, d2 = peg_d - 2*peg_cham, h = peg_cham);
    }
}

module table_tab() {
    difference() {
        translate([-tab_overlap, -tab_w/2, 0])
            cube([tab_len + tab_overlap, tab_w, tab_t]);
        translate([tab_len * 0.6, 0, -0.1]) {
            cylinder(d = tab_hole_d, h = tab_t + 0.2);
            translate([0, 0, tab_t - tab_cb_h])
                cylinder(d = tab_cb_d, h = tab_cb_h + 0.2);
        }
    }
}

module tray() {
    ox = -clearance - wall_t;
    oy = ox;
    ow = pi_len + 2*(clearance + wall_t);
    od = pi_wid + 2*(clearance + wall_t);
    win_z = base_t + 1;
    win_h = wall_h + 5;

    difference() {
        union() {
            translate([ox, oy, 0])
                difference() {
                    rounded_box(ow, od, base_t + wall_h, corner_r);
                    translate([wall_t, wall_t, base_t])
                        rounded_box(ow - 2*wall_t, od - 2*wall_t,
                                    wall_h + 1, max(0.1, corner_r - wall_t));
                }
            for (hx = [hole_inset, hole_inset + hole_dx],
                 hy = [hole_inset, hole_inset + hole_dy])
                translate([hx, hy, base_t]) post();
            translate([pi_len + clearance + wall_t, tab_y, 0]) table_tab();
            translate([-(clearance + wall_t), tab_y, 0])
                rotate([0,0,180]) table_tab();
        }
        // port windows
        translate([win_bottom_from, oy - 1, win_z])
            cube([win_bottom_to - win_bottom_from, wall_t + 2, win_h]);
        translate([pi_len + clearance - 1, win_right_from, win_z])
            cube([wall_t + 2, win_right_to - win_right_from, win_h]);
        translate([ox - 1, sd_from, win_z])
            cube([wall_t + 2, sd_to - sd_from, win_h]);
        // notch through the tray's back wall, aligned with the pedestal
        // doorway. Cut clear from the tray floor through the wall top.
        translate([holder_x + door_x0, pi_wid + clearance - 1, base_t])
            cube([door_w, wall_t + 3, wall_h + 3]);
    }
}

/* ---------------------------------------------------------------------
   Raised OLED stand.
   Vertical shaft is open from ped_floor all the way to the board.
   Front wall carries a full-cavity-width doorway to the tray.
   --------------------------------------------------------------------- */
module oled_stand() {
    translate([holder_x, hold_y0, 0]) union() {
        difference() {
            cube([Wx, Dy, top_z]);

            // 1. board pocket (open top)
            translate([o_wall, o_wall, oled_clear])
                cube([pkt_w, pkt_d, oled_t + o_lip + 1]);

            // 2. vertical shaft -- the FULL board footprint, so every
            //    edge of the PCB has clear air beneath it. Overruns 1 mm
            //    into the pocket above so the two cuts are not coplanar
            //    (coplanar faces render as a phantom "floor" in preview).
            translate([o_wall, o_wall, ped_floor])
                cube([pkt_w, pkt_d, oled_clear - ped_floor + 1]);

            // 3. doorway through the front wall, facing the Pi.
            //    Spans between the two front corner pads, 45 deg
            //    chamfered top so it prints without supports.
            translate([0, o_wall + 1, 0]) rotate([90, 0, 0])
                linear_extrude(o_wall + 2)
                    polygon([
                        [door_x0,                    ped_floor],
                        [door_x0 + door_w,           ped_floor],
                        [door_x0 + door_w,           door_top - door_ch],
                        [door_x0 + door_w - door_ch, door_top],
                        [door_x0 + door_ch,          door_top],
                        [door_x0,                    door_top - door_ch]
                    ]);

            // 4. finger notches in the FRONT and BACK lip
            for (fy = [-1, Dy - o_wall - 1])
                translate([Wx/2 - o_finger/2, fy, oled_clear])
                    cube([o_finger, o_wall + 2, top_z]);
        }

        // four corner pads the board rests on
        for (cx = [o_wall, Wx - o_wall - o_pad],
             cy = [o_wall, Dy - o_wall - o_pad])
            translate([cx, cy, ped_floor])
                cube([o_pad, o_pad, oled_clear - ped_floor]);

        // snap tabs over the LEFT and RIGHT board edges
        if (retain_tabs)
            for (tx = [o_wall, Wx - o_wall - tab_grip])
                translate([tx, Dy/2 - tab_grip_w/2, oled_clear + oled_t])
                    cube([tab_grip, tab_grip_w, 1.0]);
    }
}

/* =====================================================================
   RENDER
   ===================================================================== */
stub_z = max(0, oled_clear - stub_h);

// the stand normally sits behind the tray; on its own, drop it to 0,0
module oled_at_origin() {
    translate([-holder_x, -hold_y0, 0]) oled_stand();
}

// just the top collar of the pocket, sitting on the bed
module oled_collar() {
    translate([0, 0, -stub_z])
        intersection() {
            oled_at_origin();
            translate([0, 0, stub_z]) cube([Wx, Dy, top_z + 1]);
        }
}

if (part == "tray" || part == "both") tray();
if (part == "both") oled_stand();
if (part == "oled") {
    if (oled_stub) oled_collar();
    else oled_at_origin();
}
