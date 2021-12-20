import sys
import os
from multiprocessing import Pool
from statistics import mean


def calculate_miss_ratio(line):

    words = line.split()

    return len(set(words)), len(words)


def get_ratios(buf_dir, ratios_file):

    maxi = []
    mini = []
    avgi = []
    acmr = []
    many = []
    conf = buf_dir.split("/")[-1]

    for buf in os.listdir(buf_dir):

        # print(f"Buffer: {buf}")

        if "primitives.buf" in buf:

            fd = open(buf_dir + "/" + buf, "r")

            with Pool() as p:

                ratios = p.map(calculate_miss_ratio, fd)

            fd.close()

            if ratios[-1][1] == 0:
                continue

            print(buf)
            # print(ratios)

            maxi.append(max([r[1] / 3 for r in ratios]))
            mini.append(min([r[1] / 3 for r in ratios]))
            avgi.append(mean([r[1] / 3 for r in ratios]))
            acmr.append(mean([r[0] / r[1] for r in ratios]))
            many.append(len(ratios))

    fd = open(ratios_file, "a")
    fd.write(
        f"{conf};{sum(many)};{min(mini)};{mean(avgi)};{max(maxi)};{mean(acmr)}\n".replace(".", ","))
    fd.close()


if len(sys.argv) != 2:
    print("Illegal number of parameters")
    exit(1)

filepath = sys.argv[1]

fd = open(filepath, "w")
fd.write("Configuration;No. Meshlets; Min Prims; Avg Prims; Max Prims; ACMR\n")
fd.close()

dirname = "/".join(filepath.split("/")[:-1])

for conf in os.listdir(dirname + "/buffers"):

    print(f"Configuration: {conf}")

    get_ratios(dirname + "/buffers/" + conf, dirname + "/ratios.csv")
