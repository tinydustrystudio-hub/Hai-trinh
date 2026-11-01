"""Xưởng Sửa Chữa (BLD_REPAIR_WORKS), 5 cấp: nhà xưởng mái răng cưa ở vành trong (hướng 0°) cùng khu băng chuyền ở sàn ngoài (hướng 180°).
Cấp 1 nhà xưởng; cấp 2 băng chuyền và thùng; cấp 3 thêm cánh xưởng thứ hai, tháp đèn; cấp 4 mái vòm kính; cấp 5 tay máy robot hàn có đèn tia lửa.
Toạ độ cục bộ đảo chính (tâm ở gốc, bán kính 14, sàn ngoài y = 0,8, sàn vành trong y = 2,05)."""
import math

import kit

R = 14.0
DECK = 0.8
RING_Y = 2.05
IVORY = (0.88, 0.85, 0.77)
SEA_BLUE = (0.2, 0.43, 0.65)
ORANGE = (1.0, 0.45, 0.1)
STEEL = (0.32, 0.36, 0.4)
DARK = (0.12, 0.13, 0.15)
GLASS = (0.5, 0.75, 0.88)
LAMP = (1.0, 0.82, 0.45)
S = R * 0.075


def shed(m, level):
    """Nhà xưởng ở vành trong, hướng 0°: thân xanh biển, mái răng cưa, cửa cuốn cam, ống khói; cấp 3 thêm cánh phụ."""
    f = kit.Frame(6.1, 0.0, 0.0)
    f.box(m, 0, RING_Y + S, 0, (S * 3.2, S * 2.0, S * 4.4), SEA_BLUE, top_color=IVORY)
    # Mái răng cưa: ba răng nghiêng.
    for i, v in enumerate((-1.4, 0.0, 1.4)):
        f.hull(m, [(-S * 1.5, RING_Y + S * 2.0, v - 0.65), (S * 1.5, RING_Y + S * 2.0, v - 0.65),
                   (-S * 1.5, RING_Y + S * 2.0, v + 0.65), (S * 1.5, RING_Y + S * 2.0, v + 0.65),
                   (-S * 1.5, RING_Y + S * 2.55, v - 0.65), (S * 1.5, RING_Y + S * 2.55, v - 0.65)], IVORY, top_color=(0.95, 0.93, 0.86))
        f.box(m, 0, RING_Y + S * 2.35, v + 0.66, (S * 3.0, S * 0.4, 0.06), GLASS, chamfer=0.0)
    # Cửa cuốn cam quay ra biển, ô cửa sổ, ống khói.
    f.box(m, S * 1.62, RING_Y + S * 0.8, 0, (0.08, S * 1.5, S * 2.0), ORANGE, chamfer=0.0)
    for v in (-1.7, 1.7):
        f.box(m, S * 1.62, RING_Y + S * 1.3, v, (0.06, S * 0.6, S * 0.7), GLASS, chamfer=0.0)
    m.lathe([(0.0, RING_Y + S * 2.5), (0.28, RING_Y + S * 2.5), (0.22, RING_Y + S * 3.4), (0.0, RING_Y + S * 3.45)], 8, STEEL, center=(f.p(-S, 0, 1.5)[0], f.p(-S, 0, 1.5)[2]))
    if level >= 3:
        f.box(m, 0.3, RING_Y + S * 0.6, -3.1, (S * 2.4, S * 1.2, S * 1.8), SEA_BLUE, top_color=IVORY)
        f.box(m, 0.3, RING_Y + S * 1.35, -3.1, (S * 2.0, 0.3, S * 1.4), IVORY)


def yard(m, level):
    """Khu băng chuyền ở sàn ngoài, hướng 180° (đối diện Xưởng Tàu); từ cấp 2."""
    if level < 2:
        return
    f = kit.Frame(-R * 0.8, 0.0, 180.0)
    # Băng chuyền thấp có hai thanh dẫn, thùng vật liệu cam chạy trên đó (thêm một thùng mỗi cấp).
    f.box(m, 0, DECK + 0.18, 0, (5.0, 0.3, 1.2), DARK)
    for v in (-0.6, 0.6):
        f.box(m, 0, DECK + 0.42, v, (5.0, 0.18, 0.08), STEEL, chamfer=0.0)
    for i in range(min(level - 1, 4)):
        f.box(m, -1.8 + i * 1.2, DECK + 0.66, 0, (0.7, 0.7, 0.7), ORANGE, top_color=(1.0, 0.6, 0.3))
    if level >= 3:
        # Tháp đèn công tác.
        f.box(m, 2.8, DECK + 1.6, 1.0, (0.2, 3.2, 0.2), DARK, chamfer=0.0)
        f.hull(m, [(2.55, DECK + 3.2, 0.75), (3.05, DECK + 3.2, 0.75), (2.55, DECK + 3.2, 1.25), (3.05, DECK + 3.2, 1.25),
                   (2.5, DECK + 3.6, 0.7), (3.1, DECK + 3.6, 0.7), (2.5, DECK + 3.6, 1.3), (3.1, DECK + 3.6, 1.3)], LAMP)
    if level >= 4:
        # Mái vòm kính trên đế tròn.
        c = f.p(0.0, 0.0, 3.0)
        m.lathe([(2.0, DECK), (2.0, DECK + 0.4), (1.9, DECK + 1.1), (1.5, DECK + 1.75), (0.8, DECK + 2.1), (0.0, DECK + 2.2)], 14, GLASS,
                top_color=(0.7, 0.88, 0.95), center=(c[0], c[2]))
        m.lathe([(1.98, DECK), (2.06, DECK), (2.06, DECK + 0.45), (1.98, DECK + 0.45)], 14, IVORY, center=(c[0], c[2]), cap_bottom=False, cap_top=False)
        for i in range(4):
            a = i * math.pi / 2
            m.box((c[0] + 1.3 * math.cos(a), DECK + 1.1, c[2] + 1.3 * math.sin(a)), (0.1, 2.0, 0.1), ORANGE, chamfer=0.0)
    if level >= 5:
        # Tay máy robot hàn: đế xoay, hai đốt, mỏ hàn phát tia lửa.
        f.box(m, 0.4, DECK + 0.3, 3.0, (0.9, 0.6, 0.9), STEEL, top_color=(0.45, 0.5, 0.55))
        f.hull(m, [(0.2, DECK + 0.6, 2.8), (0.6, DECK + 0.6, 2.8), (0.2, DECK + 0.6, 3.2), (0.6, DECK + 0.6, 3.2),
                   (0.3, DECK + 2.6, 2.9), (0.5, DECK + 2.6, 2.9), (0.3, DECK + 2.6, 3.1), (0.5, DECK + 2.6, 3.1)], ORANGE)
        f.hull(m, [(0.25, DECK + 2.5, 2.9), (0.55, DECK + 2.5, 2.9), (0.25, DECK + 2.7, 3.1), (0.55, DECK + 2.7, 3.1),
                   (1.8, DECK + 1.9, 2.95), (1.9, DECK + 1.9, 3.05), (1.8, DECK + 1.8, 2.95), (1.9, DECK + 1.8, 3.05)], ORANGE, top_color=(1.0, 0.6, 0.3))
        m.ellipsoid(f.p(1.95, DECK + 1.82, 3.0), (0.12, 0.12, 0.12), 6, 4, (1.0, 0.95, 0.6))


def build_level(level):
    m = kit.Model("bld_repair_works_l%d" % level)
    shed(m, level)
    yard(m, level)
    return m.finish()


def build():
    return {"bld_repair_works_l%d" % level: [build_level(level)] for level in range(1, 6)}
