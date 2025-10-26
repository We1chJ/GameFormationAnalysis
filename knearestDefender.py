"""
player_to_defenders_graph.py

Uses shifted coordinates of 22 soccer players, takes a player ID (1-11) as input,
plots the selected player in a red filled circle, the 11 defenders (IDs 12-22) in blue
filled circles, draws edges between the selected player and each defender, and prints
the length of each edge.

Usage:
    python player_to_defenders_graph.py --player_id <ID>
"""

import matplotlib.pyplot as plt
import math
import argparse

# Store the shifted player coordinates
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

# Parse command-line argument for player ID
parser = argparse.ArgumentParser(description="Plot a player and defenders with edge lengths.")
parser.add_argument("--player_id", type=int, required=True, help="ID of the player (1-11)")
args = parser.parse_args()

# Validate player ID
player_id = args.player_id
if player_id < 1 or player_id > 11:
    raise ValueError("Player ID must be between 1 and 11")

# Find the selected player
selected_player = next(p for p in players if p["id"] == player_id)

# Calculate edge lengths from selected player to defenders (IDs 12-22)
edge_lengths = []
for defender in players[11:]:  # Players 12-22 (indices 11-21)
    distance = math.sqrt((defender["x"] - selected_player["x"])**2 + (defender["y"] - selected_player["y"])**2)
    edge_lengths.append({
        "from_id": selected_player["id"],
        "to_id": defender["id"],
        "length": distance
    })

# Plot the selected player and defenders with edges
def plot_player_to_defenders(selected_player, defenders, save_path="player_to_defenders_plot.png"):
    plt.figure(figsize=(8, 10))  # Adjusted for 400x500 axis range
    ax = plt.gca()

    # Plot selected player (red)
    x, y, r = selected_player["x"], selected_player["y"], selected_player["radius"]
    ax.add_patch(plt.Circle((x, y), r, fill=True, color='red', alpha=0.5))  # Filled circle
    ax.add_patch(plt.Circle((x, y), r, fill=False, color='black', lw=1))  # Black outline

    # Plot defenders (blue)
    for p in defenders:
        x, y, r = p["x"], p["y"], p["radius"]
        ax.add_patch(plt.Circle((x, y), r, fill=True, color='blue', alpha=0.5))  # Filled circle
        ax.add_patch(plt.Circle((x, y), r, fill=False, color='black', lw=1))  # Black outline

        # Draw edge from selected player to defender
        x_values = [selected_player["x"], p["x"]]
        y_values = [selected_player["y"], p["y"]]
        plt.plot(x_values, y_values, 'k-', lw=0.5)  # Black edge, thin line

    plt.xlim(0, 400)
    plt.ylim(0, 500)
    plt.grid(True)
    plt.title(f"Player ID {selected_player['id']} to Defenders — Origin at Lower Left")
    plt.xlabel("X (px)")
    plt.ylabel("Y (px)")

    # Center the plot with equal margins
    ax.set_position([0.1, 0.1, 0.8, 0.8])  # Centered plot with 10% margins

    if save_path:
        plt.savefig(save_path, dpi=300)
        print(f"Plot saved to: {save_path}")

    plt.show()

# Print all shifted coordinates for reference
print("Shifted Player Coordinates (All):")
for p in players:
    print(f"ID {p['id']:02d}: x={p['x']:.1f}, y={p['y']:.1f}, r={p['radius']:.1f}")

# Plot the selected player and defenders
plot_player_to_defenders(selected_player, players[11:])

# Print edge lengths
print(f"\nEdge Lengths from Player ID {player_id} to Defenders:")
for edge in edge_lengths:
    print(f"Edge (ID {edge['from_id']:02d} to ID {edge['to_id']:02d}): {edge['length']:.1f}")