"""Kho Thép (SAT_STEEL_DEPOT): hai container xanh biển chồng lệch nhau, sọc cam, cửa mở, cần cẩu nhỏ và pa-lét.
Toạ độ cục bộ: gốc ở mặt đảo tại chỗ đặt tiện ích, +x hướng ra ngoài, y lên."""
import kit

SEA = (0.16, 0.4, 0.62)
SEA_LIGHT = (0.25, 0.52, 0.75)
IVORY = (0.88, 0.85, 0.77)
ORANGE = (1.0, 0.45, 0.1)
DARK = (0.12, 0.13, 0.15)
STEEL = (0.32, 0.36, 0.4)
WOOD = (0.62, 0.45, 0.28)


def container(m, x, y, z, color, door_side):
    """Container 1,9 × 0,85 × 0,85: thân, gân sóng, sọc cam, cửa đôi ở một đầu."""
    m.box((x, y, z), (1.9, 0.85, 0.85), color, top_color=IVORY)
    for i in range(-3, 4):
        m.box((x + i * 0.24, y, z + 0.44), (0.09, 0.72, 0.04), DARK, chamfer=0.0)
        m.box((x + i * 0.24, y, z - 0.44), (0.09, 0.72, 0.04), DARK, chamfer=0.0)
    m.box((x, y + 0.2, z + 0.435), (1.8, 0.1, 0.02), ORANGE, chamfer=0.0)
    m.box((x + door_side * 0.96, y, z), (0.04, 0.78, 0.8), STEEL, chamfer=0.0)
    m.box((x + door_side * 0.985, y, z + 0.2), (0.03, 0.7, 0.02), DARK, chamfer=0.0)
    m.box((x + door_side * 0.985, y, z - 0.2), (0.03, 0.7, 0.02), DARK, chamfer=0.0)


def build():
    m = kit.Model("sat_steel_depot")
    # Sàn kê pa-lét gỗ.
    m.box((0.1, 0.07, 0.0), (2.3, 0.14, 1.9), WOOD, top_color=(0.72, 0.55, 0.36))
    # Hai container: một nằm dưới, một chồng lệch lên trên và xoay nhẹ.
    container(m, 0.0, 0.57, 0.45, SEA, 1)
    container(m, 0.05, 1.42, 0.45, SEA_LIGHT, -1)
    container(m, -0.1, 0.57, -0.52, (0.82, 0.38, 0.12), -1)
    # Cần cẩu nhỏ bên cạnh: cột, tay cần, móc.
    m.box((0.95, 0.6, -0.8), (0.12, 1.2, 0.12), ORANGE, chamfer=0.0)
    m.box((0.5, 1.22, -0.8), (1.0, 0.1, 0.1), ORANGE, chamfer=0.0)
    m.box((0.1, 0.95, -0.8), (0.03, 0.55, 0.03), DARK, chamfer=0.0)
    m.box((0.1, 0.65, -0.8), (0.14, 0.12, 0.14), DARK)
    # Cọc neo.
    m.lathe([(0.0, 0.14), (0.1, 0.14), (0.08, 0.34), (0.0, 0.36)], 8, DARK, center=(1.1, 0.7))
    return [m.finish()]
