"""
k11_graph_soccer_players.py

Uses shifted coordinates of 22 soccer players, plots only the first 11 players (IDs 1-11)
as red filled circles, draws a complete graph K11 (all pairwise edges), and prints the
length of each edge in the terminal.

Usage:
    python k11_graph_soccer_players.py
"""

import matplotlib.pyplot as plt
import math

# Store the shifted player coordinates (IDs 1-11 only for plotting, all for reference)
players = [
    {"id": 1, "x": 38.0, "y": 230.0, "radius": 19.0},
    {"id": 2, "x": 115.0, "y": 62.0, "radius": 19.0},
    {"id": 3, "x": 115.0, "y": 174.0, "radius": 19.0},
    {"id": 4, "x": 115.0, "y": 286.0, "radius": 19.0},
    {"id": 5, "x": 115.0, "y": 400.0, "radius": 19.0},
    {"id": 6, "x": 192.0, "y": 230.0, "radius": 19.0},
    {"id": 7, "x": 268.0, "y": 140.0, "radius": 19.0},
    {"id": 8, "x": 268.0, "y": 320.0, "radius": 19.0},
    {"id": 9, "x": 345.0, "y": 82.0, "radius": 19.0},
    {"id": 10, "x": 345.0, "y": 230.0, "radius": 19.0},
    {"id": 11, "x": 345.0, "y": 378.0, "radius": 19.0},
    {"id": 12, "x": 54.0, "y": 230.0, "radius": 19.0},
    {"id": 13, "x": 131.0, "y": 78.0, "radius": 19.0},
    {"id": 14, "x": 131.0, "y": 230.0, "radius": 19.0},
    {"id": 15, "x": 131.0, "y": 382.0, "radius": 19.0},
    {"id": 16, "x": 208.0, "y": 140.0, "radius": 19.0},
    {"id": 17, "x": 208.0, "y": 320.0, "radius": 19.0},
    {"id": 18, "x": 284.0, "y": 62.0, "radius": 19.0},
    {"id": 19, "x": 284.0, "y": 174.0, "radius": 19.0},
    {"id": 20, "x": 284.0, "y": 286.0, "radius": 19.0},
    {"id": 21, "x": 284.0, "y": 400.0, "radius": 19.0},
    {"id": 22, "x": 361.0, "y": 230.0, "radius": 19.0}
]

# Calculate edge lengths for K11 (all pairs of players 1-11)
edge_lengths = []
for i in range(11):  # Players 1-11 (indices 0-10)
    for j in range(i + 1, 11):  # Pair with all subsequent players
        p1 = players[i]
        p2 = players[j]
        # Euclidean distance between (x1, y1) and (x2, y2)
        distance = math.sqrt((p2["x"] - p1["x"])**2 + (p2["y"] - p1["y"])**2)
        edge_lengths.append({
            "from_id": p1["id"],
            "to_id": p2["id"],
            "length": distance
        })

# Plot the players (only IDs 1-11) and K11 edges
def plot_k11_graph(players, save_path="k11_player_plot.png"):
    plt.figure(figsize=(8, 10))  # Adjusted for 400x500 axis range
    ax = plt.gca()

    # Plot players 1-11 as red filled circles
    for p in players[:11]:  # Only IDs 1-11
        x, y, r = p["x"], p["y"], p["radius"]
        ax.add_patch(plt.Circle((x, y), r, fill=True, color='red', alpha=0.5))  # Filled circle
        ax.add_patch(plt.Circle((x, y), r, fill=False, color='black', lw=1))  # Black outline

    # Draw edges for K11 (all pairs of players 1-11)
    for edge in edge_lengths:
        p1 = players[edge["from_id"] - 1]  # ID to index (1-based to 0-based)
        p2 = players[edge["to_id"] - 1]
        x_values = [p1["x"], p2["x"]]
        y_values = [p1["y"], p2["y"]]
        plt.plot(x_values, y_values, 'k-', lw=0.5)  # Black edges, thin line

    plt.xlim(0, 400)
    plt.ylim(0, 500)
    plt.grid(True)
    plt.title("K11 Graph of Soccer Players (IDs 1-11) — Origin at Lower Left")
    plt.xlabel("X (px)")
    plt.ylabel("Y (px)")

    # Center the plot with equal margins
    ax.set_position([0.1, 0.1, 0.8, 0.8])  # Centered plot with 10% margins

    if save_path:
        plt.savefig(save_path, dpi=300)
        print(f"Plot saved to: {save_path}")

    plt.show()

# Print shifted coordinates for reference
print("Shifted Player Coordinates (All):")
for p in players:
    print(f"ID {p['id']:02d}: x={p['x']:.1f}, y={p['y']:.1f}, r={p['radius']:.1f}")

# Plot the K11 graph (players 1-11 only)
plot_k11_graph(players)

# Print edge lengths
print("\nK11 Edge Lengths:")
for edge in edge_lengths:
    print(f"Edge (ID {edge['from_id']:02d} to ID {edge['to_id']:02d}): {edge['length']:.1f}")



'''
K11 Edge Lengths:
Edge (ID 01 to ID 02): 184.8
Edge (ID 01 to ID 03): 95.2
Edge (ID 01 to ID 04): 95.2
Edge (ID 01 to ID 05): 186.6
Edge (ID 01 to ID 06): 154.0
Edge (ID 01 to ID 07): 247.0
Edge (ID 01 to ID 08): 247.0
Edge (ID 01 to ID 09): 340.8
Edge (ID 01 to ID 10): 307.0
Edge (ID 01 to ID 11): 340.8
Edge (ID 02 to ID 03): 112.0
Edge (ID 02 to ID 04): 224.0
Edge (ID 02 to ID 05): 338.0
Edge (ID 02 to ID 06): 184.8
Edge (ID 02 to ID 07): 171.7
Edge (ID 02 to ID 08): 300.0
Edge (ID 02 to ID 09): 230.9
Edge (ID 02 to ID 10): 284.8
Edge (ID 02 to ID 11): 390.8
Edge (ID 03 to ID 04): 112.0
Edge (ID 03 to ID 05): 226.0
Edge (ID 03 to ID 06): 95.2
Edge (ID 03 to ID 07): 156.7
Edge (ID 03 to ID 08): 211.5
Edge (ID 03 to ID 09): 247.7
Edge (ID 03 to ID 10): 236.7
Edge (ID 03 to ID 11): 307.4
Edge (ID 04 to ID 05): 114.0
Edge (ID 04 to ID 06): 95.2
Edge (ID 04 to ID 07): 211.5
Edge (ID 04 to ID 08): 156.7
Edge (ID 04 to ID 09): 307.4
Edge (ID 04 to ID 10): 236.7
Edge (ID 04 to ID 11): 247.7
Edge (ID 05 to ID 06): 186.6
Edge (ID 05 to ID 07): 301.7
Edge (ID 05 to ID 08): 172.7
Edge (ID 05 to ID 09): 392.5
Edge (ID 05 to ID 10): 286.0
Edge (ID 05 to ID 11): 231.0
Edge (ID 06 to ID 07): 117.8
Edge (ID 06 to ID 08): 117.8
Edge (ID 06 to ID 09): 212.9
Edge (ID 06 to ID 10): 153.0
Edge (ID 06 to ID 11): 212.9
Edge (ID 07 to ID 08): 180.0
Edge (ID 07 to ID 09): 96.4
Edge (ID 07 to ID 10): 118.4
Edge (ID 07 to ID 11): 250.1
Edge (ID 08 to ID 09): 250.1
Edge (ID 08 to ID 10): 118.4
Edge (ID 08 to ID 11): 96.4
Edge (ID 09 to ID 10): 148.0
Edge (ID 09 to ID 11): 296.0
Edge (ID 10 to ID 11): 148.0
'''