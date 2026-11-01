"""Lô Cốt Tia Sáng (TWR_LIGHT_BEAM): ống hội tụ dài đặt trên bệ tròn xám than, ba vòng hội tụ cam, thấu kính lam sáng ở đầu,
hai cánh tản nhiệt cam dựng đứng. Toạ độ như TowerMeshes (nòng tới z = −1,6)."""
import kit
import tower_base

DARK = (0.12, 0.13, 0.15)
STEEL = (0.32, 0.36, 0.4)
ORANGE = (1.0, 0.45, 0.1)
BODY = (0.2, 0.5, 0.58)  # data/towers/light_beam.tres
LENS = (0.62, 0.88, 1.0)


def build():
    base = tower_base.build("twr_light_beam_base", BODY)
    m = kit.Model("twr_light_beam_turret")
    y = 0.7
    tube_y = y + 0.2
    # Bệ tròn xám than.
    m.lathe([(0.0, y - 0.3), (0.62, y - 0.3), (0.66, y + 0.1), (0.55, y + 0.3), (0.0, y + 0.32)], 12, (0.27, 0.28, 0.3), top_color=BODY, center=(0.0, 0.2))
    m.prism((0, 0, 0.2), 0.45, y + 0.3, y + 0.42, 10, DARK)
    # Ống hội tụ thon dần về phía trước.
    m.tube((0.0, tube_y), 0.34, 0.24, 0.55, -1.25, 10, BODY)
    # Ba vòng hội tụ cam, khoảng cách và cỡ nhỏ dần.
    for z, r in ((0.15, 0.36), (-0.4, 0.3), (-0.95, 0.27)):
        m.tube((0.0, tube_y), r, r, z, z - 0.1, 12, ORANGE)
    # Hộp đầu đen và thấu kính sáng.
    m.tube((0.0, tube_y), 0.4, 0.4, -1.25, -1.42, 10, DARK)
    m.tube((0.0, tube_y), 0.27, 0.27, -1.42, -1.5, 12, LENS)
    m.tube((0.0, tube_y), 0.12, 0.12, -1.5, -1.6, 8, (1.0, 1.0, 1.0))
    # Hai cánh tản nhiệt (hình thang đứng) hai bên.
    for side in (-1.0, 1.0):
        m.hull([
            (side * 0.42, y + 0.4, 0.5), (side * 0.5, y + 0.4, 0.5), (side * 0.42, y + 0.4, -0.3), (side * 0.5, y + 0.4, -0.3),
            (side * 0.44, y + 0.95, 0.3), (side * 0.5, y + 0.95, 0.3), (side * 0.44, y + 0.95, -0.05), (side * 0.5, y + 0.95, -0.05),
        ], ORANGE, top_color=(1.0, 0.6, 0.3))
    return {"twr_light_beam_base": [base], "twr_light_beam_turret": [m.finish()]}
