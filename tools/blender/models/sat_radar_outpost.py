"""Trạm Ra-đa Tiền Tiêu (SAT_RADAR_OUTPOST): bệ tròn, cột, đĩa ra-đa nghiêng về phía ngoài, đầu thu, hộp thiết bị, đèn hiệu.
Toạ độ cục bộ: gốc ở mặt đảo tại chỗ đặt tiện ích, trục +x hướng ra ngoài (xa đảo chính), y lên; vừa trong |u| ≤ 1,3."""
import math

import kit

IVORY = (0.88, 0.85, 0.77)
STEEL = (0.32, 0.36, 0.4)
DARK = (0.12, 0.13, 0.15)
ORANGE = (1.0, 0.45, 0.1)
GLASS = (0.55, 0.8, 0.92)


def build():
    m = kit.Model("sat_radar_outpost")
    # Bệ hai tầng, vành cam, hộp thiết bị bên cạnh.
    m.lathe([(0.0, 0.0), (0.85, 0.0), (0.85, 0.28), (0.7, 0.42), (0.0, 0.42)], 12, IVORY, top_color=(0.95, 0.93, 0.86))
    m.lathe([(0.84, 0.18), (0.88, 0.18), (0.88, 0.26), (0.84, 0.26)], 12, ORANGE, cap_bottom=False, cap_top=False)
    m.box((-0.55, 0.65, 0.4), (0.5, 0.45, 0.4), STEEL, top_color=(0.45, 0.5, 0.55))
    m.box((-0.55, 0.9, 0.4), (0.3, 0.06, 0.2), GLASS, chamfer=0.0)
    # Cột tròn thu dần và khớp xoay.
    m.lathe([(0.2, 0.42), (0.14, 1.1), (0.16, 1.3)], 8, STEEL, cap_top=False, cap_bottom=False)
    m.ellipsoid((0.0, 1.38, 0.0), (0.22, 0.16, 0.22), 8, 4, DARK)
    # Đĩa: vành elip nghiêng hướng ra ngoài và lên trời 38°, lòng đĩa sáng, mặt sau tối.
    tilt = math.radians(38)
    ct, st = math.cos(tilt), math.sin(tilt)
    rim, depth = 1.05, 0.28
    centre = (0.12, 1.55, 0.0)
    pts_front, pts_back = [], []
    for i in range(16):
        a = math.tau * i / 16
        lx, lz = rim * math.cos(a), rim * math.sin(a)
        # đĩa nằm ngang (pháp tuyến lên) rồi nghiêng quanh trục z để mặt đĩa quay ra ngoài (+x)
        x0, y0 = lx, 0.0
        x = centre[0] + x0 * ct - y0 * st + st * 0.0
        pts_front.append((centre[0] + lx * ct + 0.0, centre[1] + lx * st, centre[2] + lz))
        pts_back.append((centre[0] + lx * ct - st * depth, centre[1] + lx * st + ct * depth * -1 + 0.0, centre[2] + lz * 0.35))
    m.hull(pts_front + [(centre[0] - st * depth * 1.3, centre[1] - ct * depth * 1.3, centre[2])], (0.8, 0.82, 0.8), top_color=(0.95, 0.95, 0.93))
    # Cần đỡ đầu thu và đầu thu cam ở tiêu điểm.
    focus = (centre[0] + st * 0.9, centre[1] + ct * 0.9, 0.0)
    m.hull([(centre[0], centre[1], -0.04), (centre[0], centre[1], 0.04), (focus[0], focus[1], -0.03), (focus[0], focus[1], 0.03)], STEEL)
    m.ellipsoid(focus, (0.11, 0.11, 0.11), 8, 4, ORANGE)
    # Đèn hiệu đỏ trên hộp thiết bị.
    m.ellipsoid((-0.55, 1.0, 0.4), (0.07, 0.07, 0.07), 6, 3, (1.0, 0.25, 0.2))
    return [m.finish()]
