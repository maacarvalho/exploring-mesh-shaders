import sys
from math import floor, ceil

if len(sys.argv) < 3:
    print("Less then 2 parameters")
    exit(1)


icols = float(sys.argv[1])
irows = float(sys.argv[2])

ceil_cols = floor(ceil(icols))
ceil_cols += ceil_cols % 2
ceil_rows = floor(ceil(irows))
ceil_rows += ceil_rows % 2

no_verts = (ceil_cols - 1) * (ceil_rows - 1)

print(
    f"Ceil_cols: {ceil_cols} || Ceil_rows: {ceil_rows} || No_verts: {no_verts}")

mesh_max_verts = 256
# int mesh_max_verts = 16;

mesh_wg_needed = ceil(no_verts / float(mesh_max_verts))
print(f"Mesh_wg_needed: {mesh_wg_needed}")
divs = 1
for i in range(1, mesh_max_verts + 1):

    if int(ceil(float(ceil_cols + 1) / float(i) + 1)) * int(ceil(float(ceil_rows + 1) / float(i) + 1)) <= mesh_max_verts:
        divs = i
        break

gl_TaskCountNV = divs * divs

print(f"- gl_TaskCountNV: {gl_TaskCountNV}")
