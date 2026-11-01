"""Xuồng Cướp (ENM_RAIDER_SKIFF): xuồng hở thân thon, mũi nhọn có răng vàng, mạn ốp sắt, buồng lái, cờ đen phía sau.
Dài 0,8 ô = 3,2 đơn vị, mũi hướng −z, gốc ở mực nước. Màu gốc lấy từ data/enemies/raider_skiff.tres."""
import math

import kit

BODY = (0.18, 0.19, 0.21)
DECK = (0.26, 0.27, 0.3)
LIGHT = (0.34, 0.36, 0.4)
DARK = (0.07, 0.07, 0.09)
RUST = (0.36, 0.17, 0.12)
BELOW = (0.3, 0.13, 0.1)
ACCENT = (1.0, 0.78, 0.1)
GLASS = (0.25, 0.45, 0.55)
NAME = "enm_raider_skiff"


def section(z, width, keel, rise):
    """Mặt cắt thân: đáy hẹp, sườn phình, mạn trên khép nhẹ; rise nâng mạn về phía mũi."""
    pts = []
    for s in (-1.0, 1.0):
        pts += [(s * keel, -0.1), (s * width, 0.12), (s * width * 0.94, 0.46 + rise)]
    return (z, pts)


def build():
    m = kit.Model(NAME)
    stations = [
        section(1.62, 0.62, 0.42, 0.0), section(1.0, 0.74, 0.5, 0.0), section(0.2, 0.8, 0.5, 0.02),
        section(-0.6, 0.7, 0.38, 0.06), section(-1.2, 0.42, 0.2, 0.14), section(-1.65, 0.07, 0.03, 0.24),
    ]
    # Phần dưới mực nước sơn nâu đỏ, phần trên xám than.
    lower = [(z, [p for p in pts if p[1] < 0.2]) for z, pts in stations]
    upper = [(z, [(x, max(y, 0.12)) for x, y in pts if y > 0.1]) for z, pts in stations]
    m.loft(lower, BELOW)
    m.loft(upper, BODY, top_color=DECK)
    # Gờ mạn (rub rail) sáng màu chạy dọc hai bên.
    for side in (-1.0, 1.0):
        pts = []
        for z, sec in stations[:-1]:
            x, y = sec[2 if side < 0 else 5]
            pts.append((z, x, y))
        for (za, xa, ya), (zb, xb, yb) in zip(pts, pts[1:]):
            m.hull([(xa - side * 0.08, ya, za), (xa + side * 0.02, ya + 0.07, za), (xa - side * 0.08, ya + 0.14, za),
                    (xb - side * 0.08, yb, zb), (xb + side * 0.02, yb + 0.07, zb), (xb - side * 0.08, yb + 0.14, zb)], LIGHT)
    # Mũi: sống mũi vàng và ba răng nanh.
    m.hull([(-0.1, 0.56, -1.2), (0.1, 0.56, -1.2), (-0.05, 0.74, -1.55), (0.05, 0.74, -1.55), (0.0, 0.8, -1.72), (0.0, 0.5, -1.7)], ACCENT)
    for x in (-0.24, 0.0, 0.24):
        m.hull([(x - 0.07, 0.5, -1.15 - abs(x) * 0.4), (x + 0.07, 0.5, -1.15 - abs(x) * 0.4), (x, 0.5, -1.4 - abs(x) * 0.4), (x, 0.7, -1.15 - abs(x) * 0.4)], ACCENT)
    # Buồng lái vát phía trước, kính, mái và đèn pha.
    m.hull([(-0.46, 0.46, 1.35), (0.46, 0.46, 1.35), (-0.46, 1.1, 1.3), (0.46, 1.1, 1.3),
            (-0.4, 0.46, 0.62), (0.4, 0.46, 0.62), (-0.4, 0.84, 0.66), (0.4, 0.84, 0.66)], LIGHT, top_color=(0.46, 0.48, 0.52))
    m.hull([(-0.36, 0.86, 0.66), (0.36, 0.86, 0.66), (-0.36, 1.04, 0.62), (0.36, 1.04, 0.62),
            (-0.36, 0.84, 0.8), (0.36, 0.84, 0.8)], GLASS)
    m.box((0.0, 1.16, 0.95), (0.9, 0.08, 1.0), DARK)
    m.lathe([(0.0, 1.2), (0.09, 1.2), (0.09, 1.32), (0.0, 1.34)], 8, (1.0, 0.95, 0.7), center=(0.0, 0.9))
    # Boong: thùng gỗ, bao tải, cuộn dây, đệm cao su ở mạn.
    m.box((-0.38, 0.6, -0.15), (0.42, 0.3, 0.42), RUST, top_color=(0.52, 0.34, 0.22))
    m.box((0.32, 0.56, -0.5), (0.34, 0.24, 0.34), BODY, top_color=LIGHT)
    m.lathe([(0.0, 0.5), (0.22, 0.5), (0.22, 0.6), (0.14, 0.64), (0.0, 0.64)], 10, (0.6, 0.5, 0.35), center=(0.3, 0.2))
    for side in (-1.0, 1.0):
        for z in (0.5, -0.2):
            m.lathe([(0.0, 0.1), (0.1, 0.1), (0.1, 0.34), (0.0, 0.34)], 8, DARK, center=(side * 0.84, z))
    # Động cơ gắn đuôi và chân vịt.
    m.hull([(-0.16, 0.2, 1.62), (0.16, 0.2, 1.62), (-0.14, 0.7, 1.7), (0.14, 0.7, 1.7), (-0.14, 0.2, 1.92), (0.14, 0.2, 1.92), (-0.12, 0.7, 1.9), (0.12, 0.7, 1.9)], DARK)
    m.box((0.0, -0.05, 1.9), (0.08, 0.5, 0.08), DARK, chamfer=0.0)
    m.box((0.0, -0.3, 1.9), (0.5, 0.06, 0.12), LIGHT, chamfer=0.0)
    # Cột và cờ đen có đầu lâu vàng.
    m.box((0.0, 1.95, 1.2), (0.07, 1.3, 0.07), DARK, chamfer=0.0)
    m.hull([(-0.02, 2.5, 1.2), (0.02, 2.5, 1.2), (-0.02, 2.0, 1.2), (0.02, 2.0, 1.2), (-0.02, 2.45, 0.72), (0.02, 2.45, 0.72), (-0.02, 2.05, 0.78), (0.02, 2.05, 0.78)], DARK)
    m.lathe([(0.0, 2.2), (0.06, 2.2), (0.06, 2.32), (0.0, 2.32)], 6, ACCENT, center=(0.0, 0.95), scale=(0.3, 1.0))
    return [m.finish()]
