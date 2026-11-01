"""Lô Cốt Keo (TWR_GLUE_SPRAYER): bồn keo xanh rong biển có đai cam, ống áp lực dẫn tới vòi phun loe, đồng hồ áp suất trên nắp.
Toạ độ như TowerMeshes (đế từ gốc lô cốt, đầu nòng từ trục xoay; vòi tới z = −1,6)."""
import kit
import tower_base

DARK = (0.12, 0.13, 0.15)
STEEL = (0.32, 0.36, 0.4)
IVORY = (0.88, 0.85, 0.77)
ORANGE = (1.0, 0.45, 0.1)
GLUE = (0.55, 0.68, 0.18)  # data/towers/glue_sprayer.tres


def build():
    base = tower_base.build("twr_glue_sprayer_base", GLUE)
    m = kit.Model("twr_glue_sprayer_turret")
    y = 0.7
    cz = 0.35
    # Bồn keo tròn xoay: đáy thu, bụng phình, vai cong lên nắp (pháp tuyến mượt nên nhìn tròn).
    m.lathe([(0.0, y - 0.3), (0.5, y - 0.3), (0.62, y - 0.1), (0.7, y + 0.15), (0.7, y + 0.4), (0.6, y + 0.58), (0.38, y + 0.7), (0.0, y + 0.74)], 14,
            GLUE, top_color=tuple(min(c * 1.3, 1.0) for c in GLUE), center=(0.0, cz))
    # Hai đai cam quanh bồn và vành đáy.
    m.lathe([(0.69, y - 0.02), (0.74, y - 0.02), (0.74, y + 0.1), (0.7, y + 0.1)], 14, ORANGE, center=(0.0, cz), cap_bottom=False, cap_top=False)
    m.lathe([(0.69, y + 0.28), (0.74, y + 0.28), (0.74, y + 0.4), (0.7, y + 0.4)], 14, ORANGE, center=(0.0, cz), cap_bottom=False, cap_top=False)
    # Nắp, cổ nạp và đồng hồ áp suất (mặt đồng hồ quay về phía sau).
    m.prism((0, 0, cz), 0.16, y + 0.74, y + 0.92, 8, STEEL)
    m.lathe([(0.0, y + 0.92), (0.24, y + 0.92), (0.26, y + 0.96), (0.0, y + 0.98)], 12, IVORY, center=(0.0, cz))
    m.tube((0.34, y + 0.62), 0.07, 0.07, cz + 0.05, cz + 0.3, 8, IVORY)
    # Ống áp lực nối bồn với vòi, giá đỡ.
    m.tube((0.0, y + 0.1), 0.11, 0.11, 0.0, -1.05, 8, STEEL)
    m.box((0.0, y - 0.1, -0.5), (0.36, 0.16, 0.5), DARK)
    # Vòi phun loe miệng, vành cam.
    m.tube((0.0, y + 0.1), 0.2, 0.42, -1.05, -1.5, 12, GLUE)
    m.tube((0.0, y + 0.1), 0.43, 0.43, -1.5, -1.6, 12, ORANGE)
    m.tube((0.0, y + 0.1), 0.3, 0.3, -1.58, -1.6, 12, DARK)
    # Hai đai giữ ống.
    m.tube((0.0, y + 0.1), 0.17, 0.17, -0.3, -0.4, 8, ORANGE)
    m.tube((0.0, y + 0.1), 0.17, 0.17, -0.75, -0.85, 8, ORANGE)
    return {"twr_glue_sprayer_base": [base], "twr_glue_sprayer_turret": [m.finish()]}
