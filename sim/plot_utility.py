import matplotlib.pyplot as plt
import numpy as np

def plot_heatmap(results, key, filename="Heat_map.png"):
    stages_list = sorted(list(set(r["stages"] for r in results)))
    shift_list = sorted(list(set(r["shift"] for r in results)))

    data = np.zeros((len(stages_list), len(shift_list)))

    for r in results:
        i = stages_list.index(r["stages"])
        j = shift_list.index(r["shift"])
        data[i, j] = r[key]

    plt.figure()
    plt.imshow(data, aspect='auto')
    plt.colorbar(label="Match Rate (%)")

    plt.xticks(range(len(shift_list)), shift_list)
    plt.yticks(range(len(stages_list)), stages_list)

    plt.xlabel("OUTPUT_SHIFT")
    plt.ylabel("STAGES")
    plt.title(f"{key} Match Rate Heatmap")

    for i in range(len(stages_list)):
        for j in range(len(shift_list)):
            plt.text(j, i, f"{data[i,j]:.1f}",
                     ha="center", va="center", fontsize=8)

    plt.savefig(filename)
    plt.show()
    plt.close()

def plot_lines(results, filename="lines"):
    stages_list = sorted(list(set(r["stages"] for r in results)))
    shift_list = sorted(list(set(r["shift"] for r in results)))

    for shift in shift_list:
        c1 = []
        c2 = []

        for s in stages_list:
            for r in results:
                if r["stages"] == s and r["shift"] == shift:
                    c1.append(r["chirp1"])
                    c2.append(r["chirp2"])

        plt.figure()
        plt.plot(stages_list, c1, marker='o', label="Chirp1")
        plt.plot(stages_list, c2, marker='s', label="Chirp2")

        plt.xlabel("Stages")
        plt.ylabel("Match Rate (%)")
        plt.title(f"Shift = {shift}")
        plt.legend()
        plt.grid()

        plt.savefig(f"{filename}_shift{shift}.png")
        plt.show()
        plt.close()