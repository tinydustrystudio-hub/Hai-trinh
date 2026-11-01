"""Đế lô cốt dùng chung: đế lục giác trắng ngà viền cam, cột tròn màu riêng của từng loại lô cốt, cọc neo, ốc.
Cùng toạ độ TowerMeshes.base_mesh: mặt bệ ở y = 0,7, cột cao tới 1,85 (nơi đầu nòng tựa lên)."""
import math

import kit  # noqa

IVORY = (0.88, 0.85, 0.77)
ORANGE = (1.0, 0.45, 0.1)
DARK = (0.12, 0.13, 0.15)


def build(name, column_color):
    m = kit.Model(name)
    top = 0.7
    m.prism((0, 0, 0), 1.25, top, top + 0.55, 6, IVORY, top_color=tuple(c * 0.92 for c in IVORY), yaw=math.radians(30))
    m.ring((0, 0, 0), 1.25, 1.3, top + 0.35, top + 0.55, 6, ORANGE, yaw=math.radians(30))
    # Cọc neo ở sáu góc đế.
    for i in range(6):
        a = math.radians(30 + 60 * i)
        m.box((math.cos(a) * 1.12, top + 0.62, math.sin(a) * 1.12), (0.16, 0.14, 0.16), DARK)
    # Vòng đệm cam và cột tròn.
    m.prism((0, 0, 0), 0.92, top + 0.55, top + 0.62, 12, ORANGE)
    m.prism((0, 0, 0), 0.8, top + 0.62, 1.85, 12, column_color, top_color=tuple(min(c * 1.25, 1.0) for c in column_color), top_radius=0.74)
    # Sọc dọc ngà trên cột.
    for i in range(4):
        a = math.radians(45 + 90 * i)
        m.box((math.cos(a) * 0.78, 1.25, math.sin(a) * 0.78), (0.1, 0.55, 0.1), IVORY, yaw=-a)
    return m.finish()
