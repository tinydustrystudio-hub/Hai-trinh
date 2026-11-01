"""Đài Truyền Tin (SAT_COMMS_TOWER): tháp bốn chân giằng chéo thon dần, chảo nhỏ quay ra ngoài, ăng-ten, đèn báo vàng ấm, nhà thiết bị.
Toạ độ cục bộ: gốc ở mặt đảo tại chỗ đặt tiện ích, +x hướng ra ngoài, y lên."""
import kit

IVORY = (0.88, 0.85, 0.77)
STEEL = (0.32, 0.36, 0.4)
DARK = (0.12, 0.13, 0.15)
ORANGE = (1.0, 0.45, 0.1)
LAMP = (1.0, 0.82, 0.45)
GLASS = (0.55, 0.8, 0.92)


def build():
    m = kit.Model("sat_comms_tower")
    m.lathe([(0.0, 0.0), (0.8, 0.0), (0.8, 0.2), (0.0, 0.2)], 10, IVORY)
    legs = ((-1, -1), (1, -1), (-1, 1), (1, 1))
    height = 4.2
    for sx, sz in legs:
        m.hull([(sx * 0.45 - 0.05, 0.2, sz * 0.45 - 0.05), (sx * 0.45 + 0.05, 0.2, sz * 0.45 + 0.05), (sx * 0.45 - 0.05, 0.2, sz * 0.45 + 0.05),
                (sx * 0.45 + 0.05, 0.2, sz * 0.45 - 0.05), (sx * 0.12 - 0.03, height, sz * 0.12 - 0.03), (sx * 0.12 + 0.03, height, sz * 0.12 + 0.03),
                (sx * 0.12 - 0.03, height, sz * 0.12 + 0.03), (sx * 0.12 + 0.03, height, sz * 0.12 - 0.03)], STEEL)
    # Vòng giằng ngang và giằng chéo chữ X ở ba tầng.
    for y, half in ((0.9, 0.38), (1.9, 0.29), (2.9, 0.2)):
        for sx in (-1, 1):
            m.box((sx * half, y, 0.0), (0.05, 0.05, half * 2), STEEL, chamfer=0.0)
            m.box((0.0, y, sx * half), (half * 2, 0.05, 0.05), STEEL, chamfer=0.0)
    for y0, y1, h0, h1 in ((0.2, 0.9, 0.45, 0.38), (0.9, 1.9, 0.38, 0.29), (1.9, 2.9, 0.29, 0.2)):
        for sz in (-1, 1):
            m.hull([(-h0, y0, sz * h0), (-h0 + 0.03, y0, sz * h0), (h1, y1, sz * h1), (h1 - 0.03, y1, sz * h1)], STEEL)
    # Sàn đài trên đỉnh, chảo quay ra ngoài, ăng-ten roi, đèn báo.
    m.box((0.0, height, 0.0), (0.5, 0.1, 0.5), DARK, top_color=STEEL)
    m.lathe([(0.0, 0.0), (0.45, 0.0), (0.4, 0.12), (0.0, 0.15)], 12, IVORY, top_color=(0.95, 0.93, 0.86), center=(0.0, 0.0))
    m.hull([(0.2, height + 0.15, -0.35), (0.2, height + 0.15, 0.35), (0.2, height + 0.85, -0.35), (0.2, height + 0.85, 0.35),
            (0.55, height + 0.5, -0.12), (0.55, height + 0.5, 0.12)], (0.85, 0.87, 0.85), top_color=(0.95, 0.95, 0.93))
    m.box((-0.15, height + 0.9, 0.12), (0.04, 1.0, 0.04), DARK, chamfer=0.0)
    m.ellipsoid((-0.15, height + 1.45, 0.12), (0.1, 0.1, 0.1), 8, 4, LAMP)
    m.box((-0.15, height + 0.5, -0.1), (0.04, 0.55, 0.04), ORANGE, chamfer=0.0)
    # Nhà thiết bị thấp dưới chân tháp.
    m.box((0.35, 0.55, -0.85), (0.9, 0.7, 0.8), IVORY, top_color=(0.95, 0.93, 0.86))
    m.box((0.35, 0.6, -0.44), (0.5, 0.5, 0.04), DARK, chamfer=0.0)
    m.box((0.35, 0.95, -0.85), (1.0, 0.1, 0.9), ORANGE)
    m.box((0.35, 0.75, -0.44), (0.3, 0.2, 0.03), GLASS, chamfer=0.0)
    return [m.finish()]
