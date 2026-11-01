"""Xưởng Tàu (BLD_SHIPYARD), 5 cấp: ụ nổi chữ U ở sàn ngoài (hướng 0°), mở ra biển.
Cấp 1 ụ trống; cấp 2 cầu cẩu có chân; cấp 3 thân tàu đang đóng; cấp 4 buồng lái kính, cột và đèn hàn; cấp 5 ụ thứ hai ở hướng 120° với tàu tuần tra neo sẵn.
Toạ độ cục bộ đảo chính (tâm ở gốc, bán kính 14, sàn y = 0,8)."""
import math

import kit

R = 14.0
DECK = 0.8
SEA_BLUE = (0.16, 0.4, 0.62)
IVORY = (0.88, 0.85, 0.77)
ORANGE = (1.0, 0.45, 0.1)
STEEL = (0.32, 0.36, 0.4)
DARK = (0.12, 0.13, 0.15)
GLASS = (0.55, 0.8, 0.92)
LAMP = (1.0, 0.9, 0.55)


def dock(m, degrees, level, hull_on):
    f = kit.Frame(R * 0.8 * math.cos(math.radians(degrees)), R * 0.8 * math.sin(math.radians(degrees)), degrees)
    # Sàn ụ và hai mạn cao, vách đuôi (phía trong đảo), vạch cam.
    f.box(m, 0, DECK + 0.12, 0, (3.2, 0.24, 3.2), SEA_BLUE, top_color=IVORY)
    for v in (-1.55, 1.55):
        f.box(m, 0, DECK + 0.65, v, (3.2, 1.1, 0.34), SEA_BLUE, top_color=ORANGE)
        f.box(m, 0, DECK + 1.25, v, (3.2, 0.1, 0.38), STEEL, chamfer=0.0)
    f.box(m, -1.5, DECK + 0.65, 0, (0.34, 1.1, 3.2), SEA_BLUE, top_color=IVORY)
    # Cọc neo đen ở đầu hai mạn.
    for v in (-1.55, 1.55):
        m.lathe([(0.0, DECK + 1.3), (0.16, DECK + 1.3), (0.13, DECK + 1.55), (0.0, DECK + 1.58)], 8, DARK, center=(f.p(1.6, 0, v)[0], f.p(1.6, 0, v)[2]))
    if level >= 2:
        # Cầu cẩu: dầm ngang cam trên hai chân, ròng rọc treo.
        for v in (-1.75, 1.75):
            f.box(m, 0, DECK + 1.2, v, (0.4, 2.4, 0.4), ORANGE)
        f.box(m, 0, DECK + 2.5, 0, (0.45, 0.4, 4.0), ORANGE, top_color=(1.0, 0.6, 0.3))
        f.box(m, 0, DECK + 1.9, 0.0, (0.1, 1.0, 0.1), DARK, chamfer=0.0)
        f.box(m, 0, DECK + 1.3, 0.0, (0.5, 0.3, 0.5), DARK)
    if hull_on and level >= 3:
        # Thân tàu đang đóng nằm trong ụ: sống tàu, mạn ngà, mũi nhọn về phía biển.
        f.hull(m, [(-1.2, DECK + 0.3, -0.7), (-1.2, DECK + 0.3, 0.7), (-1.2, DECK + 1.0, -0.85), (-1.2, DECK + 1.0, 0.85),
                   (0.5, DECK + 0.3, -0.7), (0.5, DECK + 0.3, 0.7), (0.5, DECK + 1.05, -0.85), (0.5, DECK + 1.05, 0.85),
                   (1.45, DECK + 0.35, 0.0), (1.45, DECK + 0.9, 0.0)], IVORY, top_color=(0.55, 0.57, 0.6))
        f.box(m, 0.1, DECK + 0.4, 0, (2.4, 0.12, 1.5), ORANGE, chamfer=0.0)
    if hull_on and level >= 4:
        # Buồng lái kính, cột ăng-ten, đèn hàn sáng.
        f.box(m, -0.8, DECK + 1.35, 0, (0.8, 0.6, 0.9), IVORY, top_color=(0.95, 0.93, 0.86))
        f.box(m, -0.4, DECK + 1.4, 0, (0.06, 0.34, 0.7), GLASS, chamfer=0.0)
        f.box(m, -0.8, DECK + 2.0, 0, (0.06, 0.9, 0.06), DARK, chamfer=0.0)
        m.ellipsoid(f.p(0.5, DECK + 2.7, 0.0), (0.2, 0.15, 0.2), 8, 4, LAMP)


def patrol_boat(m, degrees):
    """Tàu tuần tra nhỏ neo cạnh ụ thứ hai (cấp 5)."""
    f = kit.Frame(R * 0.8 * math.cos(math.radians(degrees)) + 0.0, R * 0.8 * math.sin(math.radians(degrees)), degrees)
    f.hull(m, [(-0.8, DECK + 0.45, -0.4), (-0.8, DECK + 0.45, 0.4), (-0.8, DECK + 0.9, -0.45), (-0.8, DECK + 0.9, 0.45),
               (0.6, DECK + 0.45, -0.35), (0.6, DECK + 0.45, 0.35), (0.6, DECK + 0.85, -0.4), (0.6, DECK + 0.85, 0.4), (1.1, DECK + 0.7, 0.0)], (0.9, 0.9, 0.92), top_color=(0.95, 0.95, 0.97))
    f.box(m, -0.3, DECK + 1.15, 0, (0.5, 0.35, 0.5), ORANGE)


def build_level(level):
    m = kit.Model("bld_shipyard_l%d" % level)
    dock(m, 0, level, hull_on=True)
    if level >= 5:
        dock(m, 120, level, hull_on=False)
        patrol_boat(m, 120)
    return m.finish()


def build():
    return {"bld_shipyard_l%d" % level: [build_level(level)] for level in range(1, 6)}
