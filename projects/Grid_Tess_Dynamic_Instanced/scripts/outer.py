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


workg_len = 32
divs = 1

oLvl = float(sys.argv[1])
iuLvl = float(sys.argv[2])
ivLvl = 1

ceil_oLvl = int(ceil(oLvl))
ceil_oLvl += ceil_oLvl % 2
ceil_iuLvl = int(ceil(iuLvl))
ceil_iuLvl += ceil_iuLvl % 2
ceil_ivLvl = int(ceil(ivLvl))
ceil_ivLvl += ceil_ivLvl % 2

print(f"Ceil_oLvl: {ceil_oLvl}")
print(f"Ceil_iuLvl: {ceil_iuLvl}")

top_divergent_idx = ceil_iuLvl - 2 - \
    pow(2, floor(log2(max(1, ceil_iuLvl - 2)))) + 1
bot_divergent_idx = ceil_oLvl - 2 - \
    pow(2, floor(log2(max(1, ceil_oLvl - 2)))) + 1

mesh_max_verts = 16

print(f"Max_verts: {mesh_max_verts}")

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

min_ratio = pow(2, floor(log2(ceil_higher)) - ceil(log2(ceil_lesser)))
print(f"Min_ratio: {min_ratio}")

# no_lesser_verts = int(
# floor((mesh_max_verts + 2 * min_ratio) / (1 + min_ratio)))
# no_higher_verts = int(min_ratio * (no_lesser_verts - 2))

no_higher_verts = int(floor((mesh_max_verts - 2) / ceil(1 + 1.0 / min_ratio)))
no_lesser_verts = int(ceil(float(no_higher_verts) / min_ratio) + 2)

print(f"No_higher_verts: {no_higher_verts}")
print(f"No_lesser_verts: {no_lesser_verts}")

# divs = int(ceil(float(ceil_higher + higher_is_down -
# higher_is_up) / (no_higher_verts - 2)))
divs = int(ceil(float(ceil_higher + higher_is_down -
           higher_is_up - 2) / (no_higher_verts - 2)))
# divs = int(ceil(float(ceil_higher + higher_is_down - higher_is_up) /
# float(mesh_max_verts - 4 - ceil(2.0 / min_ratio))))
# divs = int(ceil(float(ceil_higher + higher_is_down - higher_is_up) /
# 4))
print(f"Divs: {divs}")

# no_higher_verts=mesh_max_verts - 2 - int(ceil(2.0 * divs / min_ratio))
# no_lesser_verts=mesh_max_verts - no_higher_verts
print(
    f"No_higher_verts: {no_higher_verts} || No_lesser_verts: {no_lesser_verts}")

print("========================================================================================")
for side_wg_id in range(divs):

    print(f"{side_wg_id} ======================================================================")

    # min_u_higher = (no_higher_verts - 1) * side_wg_id
    # max_u_higher = (no_higher_verts - 1) * (side_wg_id + 1)

    min_u_higher = int(round(float(ceil_higher + higher_is_down -
                       higher_is_up) * float(side_wg_id) / float(divs)) - 1)
    max_u_higher = int(round(float(ceil_higher + higher_is_down -
                       higher_is_up) * float(side_wg_id + 1) / float(divs)) - 1)

    min_u_lesser = calculate_adj_idx(ceil_higher, ceil_lesser, min_u_higher - 1, higher_is_down,
                                     higher_is_up, log_higher, log_lesser, higher_divergent_idx, lesser_divergent_idx)
    max_u_lesser = calculate_adj_idx(ceil_higher, ceil_lesser, max_u_higher + 1, higher_is_down,
                                     higher_is_up, log_higher, log_lesser, higher_divergent_idx, lesser_divergent_idx)
    # min_u_lesser = int(floor(float(min_u_higher) / float(max_ratio)))
    # max_u_lesser = int(floor(float(max_u_higher) / float(min_ratio)))

    print(
        f"- min_u_higher: {min_u_higher} || max_u_higher: {max_u_higher} || min_u_lesser: {min_u_lesser} || max_u_lesser: {max_u_lesser}")

    min_u_down = max(0, min(ceil_oLvl, higher_is_down *
                            min_u_higher + higher_is_up * min_u_lesser))
    max_u_down = max(0, min(ceil_oLvl, higher_is_down *
                            max_u_higher + higher_is_up * max_u_lesser))
    min_u_top = max(1, min(ceil_iuLvl - 1, 1 + higher_is_down *
                           min_u_lesser + higher_is_up * min_u_higher))
    max_u_top = max(1, min(ceil_iuLvl - 1, 1 + higher_is_down *
                           max_u_lesser + higher_is_up * max_u_higher))

    # print(
    # f"- min_u_down: {min_u_down} || max_u_down: {max_u_down} || min_u_top: {min_u_top} || max_u_top: {max_u_top}")

    no_bottom_verts = max_u_down - min_u_down + 1
    no_top_verts = max_u_top - min_u_top + 1
    no_verts = no_bottom_verts + no_top_verts

    print(
        f"- no_bottom_verts: {no_bottom_verts} || no_top_verts: {no_top_verts} || no_verts: {no_verts}")
print("========================================================================================")
# top_divergent_idx = ceil_iuLvl - 2 - \
# int(pow(2, floor(log2(ceil_iuLvl - 2)))) + 1

# bot_divergent_idx = ceil_oLvl - 2 - \
# int(pow(2, floor(log2(ceil_oLvl - 2)))) + 1

# print(f"Bot_div_idx: {bot_divergent_idx}")
# print(f"Top_div_idx: {top_divergent_idx}")

# log_oLvl = log2(ceil_oLvl)
# log_iuLvl = log2(ceil_iuLvl)

# print("=============================================================================================================")

# for side_wg_id in range(divs):

# down_min = float(ceil_oLvl) * float(side_wg_id) / float(divs)
# down_max = float(ceil_oLvl) * float(side_wg_id + 1) / float(divs)
# top_min = 1.0 + float(ceil_iuLvl - 2) * float(side_wg_id) / float(divs)
# top_max = 1.0 + float(ceil_iuLvl - 2) * float(side_wg_id + 1) / float(divs)

# min_u_down = int(max(0.0, int(side_wg_id >= float(divs) * 0.5) * round(down_min) +
# int(side_wg_id < float(divs) * 0.5) * round(down_min)))
# max_u_down = int(max(0.0, int(side_wg_id + 1 >= float(divs) * 0.5) * round(down_max) +
# int(side_wg_id + 1 < float(divs) * 0.5) * round(down_max)))
# min_u_top = int(max(0.0, int(side_wg_id >= float(divs) * 0.5) * round(top_min) +
# int(side_wg_id < float(divs) * 0.5) * round(top_min)))
# max_u_top = int(max(0.0, int(side_wg_id + 1 >= float(divs) * 0.5) * round(top_max) +
# int(side_wg_id + 1 < float(divs) * 0.5) * round(top_max)))

# no_bottom_verts = max_u_down - min_u_down + 1
# no_top_verts = max_u_top - min_u_top + 1
# no_verts = no_bottom_verts + no_top_verts

# # if (side_wg_id != 0) return

# for idx in range(no_verts):

# is_down = int(idx < no_bottom_verts)
# is_up = int(idx >= no_bottom_verts)

# min_u_idx = is_down * min_u_down + is_up * min_u_top

# u_idx = min_u_idx + idx - is_up * no_bottom_verts
# v_idx = is_down * 0 + is_up * 1

# lvl = is_down * oLvl + is_up * iuLvl
# ceil_lvl = is_down * ceil_oLvl + is_up * ceil_iuLvl

# adj_lvl = is_down * iuLvl + is_up * oLvl
# ceil_adj = is_down * ceil_iuLvl + is_up * ceil_oLvl

# lvl_divergent_idx = is_down * bot_divergent_idx + is_up * top_divergent_idx
# adj_divergent_idx = is_down * top_divergent_idx + is_up * bot_divergent_idx

# prev_u_idx = max(is_up, min(ceil_lvl - 2 - is_up, u_idx -
# int(u_idx > lvl_divergent_idx) - int(u_idx >= ceil_lvl - lvl_divergent_idx)))
# prev_v_idx = is_up

# u = float(u_idx) / float(ceil_lvl)
# prev_u = float(prev_u_idx) / float(max(1, ceil_lvl - 2))
# v = float(v_idx) / float(ceil_ivLvl)
# prev_v = float(prev_v_idx) / float(max(1, ceil_ivLvl - 2))

# inter_u = mix(prev_u, u, 1 - int(lvl >= 2) * 0.5 * (ceil_lvl - lvl))
# inter_v = mix(prev_v, v, 1 - is_up *
# (int(ivLvl >= 2) * 0.5 * (ceil_ivLvl - ivLvl)))

# # gl_MeshVerticesNV[idx].gl_Position = m_pvm * mix(
# # mix(v0, v1, float(inter_u)), mix(v3, v2, float(inter_u)), float(inter_v))

# uvs = [
# [inter_u, inter_v],
# [1 - inter_v, inter_u],
# [1 - inter_u, 1 - inter_v],
# [inter_v, 1 - inter_u]
# ]

# # if idx < no_bottom_verts:
# # continue
# # if idx == no_bottom_verts - 1:
# # print("=============================================================================================================")
# # continue

# is_fst_half = int(u_idx < ceil_lvl * 0.5)
# is_snd_half = int(u_idx >= ceil_lvl * 0.5)

# u_idx -= is_up
# # u_idx = is_fst_half * (u_idx - is_up) + is_snd_half * (ceil_lvl - 1 - (u_idx + is_up))

# # print(f"{u_idx} => ", end="")

# # u_idx += is_up
# u_idx = is_fst_half * u_idx + is_snd_half * \
# (ceil_lvl - 1 - u_idx - 2 * is_up)
# # if is_up == 1:
# # continue

# log_lvl = is_down * log_oLvl + is_up * log_iuLvl
# log_adj = is_down * log_iuLvl + is_up * log_oLvl

# trunc_log_lvl = int(u_idx > lvl_divergent_idx) * int(floor(log_lvl)) + \
# int(u_idx <= lvl_divergent_idx) * int(ceil(log_lvl))

# ratio = pow(2, int(trunc_log_lvl - floor(log_adj)))

# lvl_offset = max(0, int((ceil_lvl - pow(2, trunc_log_lvl)) * 0.5))
# adj_offset = max(
# 0, int((ceil_adj - pow(2, int(floor(log_adj)))) * 0.5))

# inter_idx = min((ceil_adj - 2) * 0.5,
# float(u_idx - lvl_offset) / ratio)

# # print(f"{u_idx} => ", end="")

# ratio /= int(floor(log_adj) != ceil(log_adj)) * \
# int(floor(inter_idx) < ceil(int(adj_divergent_idx) * 0.5)) + 1

# inter_idx = min((ceil_adj - 2) * 0.5, float(u_idx - lvl_offset) / ratio) + \
# int(floor(inter_idx) >= ceil(int(adj_divergent_idx) * 0.5)) * adj_offset

# # print(
# # f"Inter: {inter_idx} || Rat: {ratio} ", end="")

# new_verts = pow(2, int(floor(log_adj) - trunc_log_lvl))
# new_vert_idx = ceil(float(adj_divergent_idx) * 0.5)

# up_offset = new_verts + int(floor(log_adj) != ceil(log_adj)) * \
# max(0, min(new_verts, (adj_divergent_idx + 1 - inter_idx) * 0.5))

# # print(
# # f"|| Nv: {new_verts} || Nvi: {new_vert_idx} || UpOffset: {up_offset} ", end="")
# # inter_idx += is_up * (1 / up_offset)
# # int(floor(inter_idx) < ceil(int(adj_divergent_idx) * 0.5)) * adj_offset)

# inter_idx += is_up * max(1, up_offset)

# # print(f"|| Inter: {inter_idx} =>", end="")

# inter_idx = is_fst_half * \
# floor(inter_idx) + is_snd_half * \
# ceil((ceil_adj - 2 * is_down - inter_idx))

# offset_inter_idx = is_down * \
# (no_bottom_verts + int(inter_idx) -
# min_u_top + 1) + is_up * (int(inter_idx))

# # print(
# # f" {inter_idx} || LvlOff: {lvl_offset} || AdjOff: {adj_offset} || OffInterIdx: {offset_inter_idx}")
# # gl_PrimitiveIndicesNV[idx * 3 + 0] = idx + is_up
# # gl_PrimitiveIndicesNV[idx * 3 + 1] = idx + is_down
# # gl_PrimitiveIndicesNV[idx * 3 + 2] = offset_inter_idx

# true_idx = min(no_bottom_verts + no_top_verts - 3, idx - is_up)

# print(f"Idx: {idx} || TrueIdx: {true_idx}")
# # p_out[idx].mesh_id = is_up
# # p_out[idx].divs = 3

# print("=============================================================================================================")
