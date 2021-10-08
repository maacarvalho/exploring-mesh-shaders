import sys
from math import log2, floor, ceil

if len(sys.argv) < 3:
    print("Less then 2 parameters")
    exit(1)


def mix(a, b, c):
    return a + (b - a) * c


def calculate_adj_idx(ceil_lvl, ceil_adj, u_idx, is_down, is_up, log_lvl, log_adj, lvl_divergent_idx, adj_divergent_idx):

    is_fst_half = int(u_idx < ceil_lvl * 0.5)
    is_snd_half = 1 - is_fst_half

    u_idx = is_fst_half * (u_idx - is_up) + is_snd_half * \
        (ceil_lvl - 1 - (u_idx + is_up))

    trunc_log_lvl = int(u_idx > lvl_divergent_idx) * int(floor(log_lvl)) + \
        int(u_idx <= lvl_divergent_idx) * int(ceil(log_lvl))

    ratio = pow(2, int(trunc_log_lvl - floor(log_adj)))

    lvl_offset = max(0, int((ceil_lvl - pow(2, trunc_log_lvl)) * 0.5))
    adj_offset = max(0, int((ceil_adj - pow(2, int(floor(log_adj)))) * 0.5))

    inter_idx = min((ceil_adj - 2) * 0.5, float(u_idx - lvl_offset) / ratio)

    ratio /= int(floor(log_adj) != ceil(log_adj)) * \
        int(floor(inter_idx) < ceil(int(adj_divergent_idx) * 0.5)) + 1

    inter_idx = min((ceil_adj - 2) * 0.5, float(u_idx - lvl_offset) / ratio) + \
        int(floor(inter_idx) >= ceil(int(adj_divergent_idx) * 0.5)) * adj_offset

    # Is_Up Offset
    new_verts = pow(2, int(floor(log_adj) - trunc_log_lvl))

    up_offset = int(new_verts + int(floor(log_adj) != ceil(log_adj)) *
                    max(0, min(new_verts, (adj_divergent_idx + 1 - inter_idx) * 0.5)))

    inter_idx += is_up * max(1, up_offset)
    inter_idx = is_fst_half * \
        floor(inter_idx) + is_snd_half * \
        ceil((ceil_adj - 2 * is_down - inter_idx))

    return int(inter_idx)


def outer_mesh_shader(id, divs, ceil_oLvl, ceil_iuLvl, ceil_ivLvl):

    print(
        f"Ceil_oLvl: {ceil_oLvl} || Ceil_iuLvl: {ceil_iuLvl} || Ceil_ivLvl: {ceil_ivLvl}")

    top_divergent_idx = ceil_iuLvl - 2 - \
        int(pow(2, floor(log2(ceil_iuLvl - 2)))) + 1
    bot_divergent_idx = ceil_oLvl - 2 - \
        int(pow(2, floor(log2(ceil_oLvl - 2)))) + 1

    # Current WorkGroupID portion of the side
    mesh_max_verts = 256
    #mesh_max_verts = 16;

    higher_is_down = int(ceil_oLvl >= ceil_iuLvl - 2)
    higher_is_up = 1 - higher_is_down

    ceil_higher = higher_is_down * ceil_oLvl + higher_is_up * ceil_iuLvl
    ceil_lesser = higher_is_down * ceil_iuLvl + higher_is_up * ceil_oLvl

    log_higher = log2(ceil_higher)
    log_lesser = log2(ceil_lesser)

    higher_divergent_idx = bot_divergent_idx * \
        higher_is_down + top_divergent_idx * higher_is_up
    lesser_divergent_idx = top_divergent_idx * \
        higher_is_down + bot_divergent_idx * higher_is_up

    min_ratio = pow(2, int(floor(log_higher) - ceil(log_lesser)))

    no_higher_verts = int(
        floor((mesh_max_verts - 2) / ceil(1 + 1.0 / min_ratio)))
    no_lesser_verts = int(ceil(float(no_higher_verts) / min_ratio) + 2)

    #min_u_higher = (no_higher_verts - 1) * id;
    #max_u_higher = (no_higher_verts - 1) * (id + 1);

    min_u_higher = int(round(float(ceil_higher + higher_is_down -
                       higher_is_up) * float(id) / float(divs)) - 1)
    max_u_higher = int(round(float(ceil_higher + higher_is_down - higher_is_up)
                       * float(id + 1) / float(divs)) - 1)

    min_u_lesser = calculate_adj_idx(ceil_higher, ceil_lesser, min_u_higher - 1, higher_is_down,
                                     higher_is_up, log_higher, log_lesser, higher_divergent_idx, lesser_divergent_idx)
    max_u_lesser = calculate_adj_idx(ceil_higher, ceil_lesser, max_u_higher + 1, higher_is_down,
                                     higher_is_up, log_higher, log_lesser, higher_divergent_idx, lesser_divergent_idx)

    min_u_down = max(0, min(ceil_oLvl, higher_is_down *
                     min_u_higher + higher_is_up * min_u_lesser))
    max_u_down = max(0, min(ceil_oLvl, higher_is_down *
                     max_u_higher + higher_is_up * max_u_lesser))
    min_u_top = max(1, min(ceil_iuLvl - 1, 1 + higher_is_down *
                    min_u_lesser + higher_is_up * min_u_higher))
    max_u_top = max(1, min(ceil_iuLvl - 1, 1 + higher_is_down *
                    max_u_lesser + higher_is_up * max_u_higher))

    no_bottom_verts = max_u_down - min_u_down + 1
    no_top_verts = max_u_top - min_u_top + 1
    no_verts = no_bottom_verts + no_top_verts

    # print(f"{id} => No_Bottom_Verts: {no_bottom_verts} || No_Top_Verts: {no_top_verts} || No_Verts: {no_verts}")


oLevel = [float(sys.argv[i]) for i in range(1, 5)]
iLevel = [float(sys.argv[i]) for i in range(5, 7)]

print(f"OLevel: {oLevel} || ILevel: {iLevel}")

# Tessellation Levels
ceil_left = int(ceil(oLevel[0]))
ceil_left += ceil_left % 2
ceil_bottom = int(ceil(oLevel[1]))
ceil_bottom += ceil_bottom % 2
ceil_top = int(ceil(oLevel[2]))
ceil_top += ceil_top % 2
ceil_right = int(ceil(oLevel[3]))
ceil_right += ceil_right % 2

ceil_cols = int(ceil(iLevel[0]))
ceil_cols += ceil_cols % 2
ceil_rows = int(ceil(iLevel[1]))
ceil_rows += ceil_rows % 2

# Number of Vertices of the Quad
no_verts_left = (ceil_left + 1) + max(1, ceil_rows - 1)
no_verts_bottom = (ceil_bottom + 1) + max(1, ceil_cols - 1)
no_verts_top = (ceil_top + 1) + max(1, ceil_cols - 1)
no_verts_right = (ceil_right + 1) + max(1, ceil_rows - 1)

print(
    f"No Verts (l,b,t,r): {no_verts_left} || {no_verts_bottom} || {no_verts_top} || {no_verts_right}")

# Maximum number of vertices a Mesh Workgroup can handle
mesh_max_verts = 256
# mesh_max_verts = 16;

# Left
print("============================================================ Left")
higher_is_down = int(ceil_left >= ceil_rows - 2)
higher_is_up = 1 - higher_is_down

ceil_higher = higher_is_down * ceil_left + higher_is_up * ceil_rows
ceil_lesser = higher_is_down * ceil_rows + higher_is_up * ceil_left

min_ratio = pow(2, floor(log2(ceil_higher)) - ceil(log2(ceil_lesser)))

print(
    f"Higher: {ceil_higher} || Lesser: {ceil_lesser} || Min Ratio: {min_ratio}")

no_higher_verts = int(floor((mesh_max_verts - 2) / ceil(1 + 1.0 / min_ratio)))
no_lesser_verts = int(ceil(float(no_higher_verts) / min_ratio) + 2)

print(f"Higher Verts: {no_higher_verts} || Lesser Verts: {no_lesser_verts}")

left_divs = int(ceil(float(ceil_higher + higher_is_down -
                higher_is_up - 2) / (no_higher_verts - 2)))

# Bottom
print("============================================================ Bottom")
higher_is_down = int(ceil_bottom >= ceil_cols - 2)
higher_is_up = 1 - higher_is_down

ceil_higher = higher_is_down * ceil_bottom + higher_is_up * ceil_cols
ceil_lesser = higher_is_down * ceil_cols + higher_is_up * ceil_bottom

min_ratio = pow(2, floor(log2(ceil_higher)) - ceil(log2(ceil_lesser)))

print(
    f"Higher: {ceil_higher} || Lesser: {ceil_lesser} || Min Ratio: {min_ratio}")

no_higher_verts = int(floor((mesh_max_verts - 2) / ceil(1 + 1.0 / min_ratio)))
no_lesser_verts = int(ceil(float(no_higher_verts) / min_ratio) + 2)

print(f"Higher Verts: {no_higher_verts} || Lesser Verts: {no_lesser_verts}")

bottom_divs = int(ceil(float(ceil_higher + higher_is_down -
                  higher_is_up - 2) / (no_higher_verts - 2)))

# Top
print("============================================================ Top")
higher_is_down = int(ceil_top >= ceil_cols - 2)
higher_is_up = 1 - higher_is_down

ceil_higher = higher_is_down * ceil_top + higher_is_up * ceil_cols
ceil_lesser = higher_is_down * ceil_cols + higher_is_up * ceil_top

min_ratio = pow(2, floor(log2(ceil_higher)) - ceil(log2(ceil_lesser)))

print(
    f"Higher: {ceil_higher} || Lesser: {ceil_lesser} || Min Ratio: {min_ratio}")

no_higher_verts = int(floor((mesh_max_verts - 2) / ceil(1 + 1.0 / min_ratio)))
no_lesser_verts = int(ceil(float(no_higher_verts) / min_ratio) + 2)

print(f"Higher Verts: {no_higher_verts} || Lesser Verts: {no_lesser_verts}")

top_divs = int(ceil(float(ceil_higher + higher_is_down -
               higher_is_up - 2) / (no_higher_verts - 2)))

# Right
print("============================================================ Right")
higher_is_down = int(ceil_right >= ceil_rows - 2)
higher_is_up = 1 - higher_is_down

ceil_higher = higher_is_down * ceil_right + higher_is_up * ceil_rows
ceil_lesser = higher_is_down * ceil_rows + higher_is_up * ceil_right

min_ratio = pow(2, floor(log2(ceil_higher)) - ceil(log2(ceil_lesser)))

print(
    f"Higher: {ceil_higher} || Lesser: {ceil_lesser} || Min Ratio: {min_ratio}")

no_higher_verts = int(floor((mesh_max_verts - 2) / ceil(1 + 1.0 / min_ratio)))
no_lesser_verts = int(ceil(float(no_higher_verts) / min_ratio) + 2)

print(f"Higher Verts: {no_higher_verts} || Lesser Verts: {no_lesser_verts}")

right_divs = int(ceil(float(ceil_higher + higher_is_down -
                 higher_is_up - 2) / (no_higher_verts - 2)))

print("============================================================")

# printf[3] = vec4(bottom_divs, right_divs, top_divs, left_divs)
print(f"Divs (l,b,t,r): {left_divs}, {bottom_divs}, {top_divs}, {right_divs}")

print("============================================================ Left")

for i in range(left_divs):
    outer_mesh_shader(i, left_divs, ceil_left, ceil_rows, ceil_cols)

print("============================================================ Bottom")

# for i in range(bottom_divs):
    # outer_mesh_shader(i, bottom_divs, ceil_bottom, ceil_cols, ceil_rows)

print("============================================================ Top")

# for i in range(top_divs):
    # outer_mesh_shader(i, top_divs, ceil_top, ceil_cols, ceil_rows)

print("============================================================ Right")

# for i in range(right_divs):
    # outer_mesh_shader(i, right_divs, ceil_right, ceil_rows, ceil_cols)


# if (iLevel == vec2(0)) {left_divs = 0
# bottom_divs = 0
# right_divs = 0
# top_divs = 0
# }
# print("=============================================================================================================")
