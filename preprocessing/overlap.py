"""
shifted_soccer_players_no_labels.py

Stores 22 soccer player coordinates, shifts the x-coordinates of the last 11 players
by subtracting half the image width (394 pixels), and plots them on a coordinate
plane with x-axis fixed at 0-400, y-axis fixed at 0-500, IDs 1-11 in red filled circles,
IDs 12-22 in blue filled circles, without labels, and centered.

Usage:
    python shifted_soccer_players_no_labels.py
"""

import matplotlib.pyplot as plt

# Store the original player coordinates
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
    {"id": 12, "x": 448.0, "y": 230.0, "radius": 19.0},
    {"id": 13, "x": 525.0, "y": 78.0, "radius": 19.0},
    {"id": 14, "x": 525.0, "y": 230.0, "radius": 19.0},
    {"id": 15, "x": 525.0, "y": 382.0, "radius": 19.0},
    {"id": 16, "x": 602.0, "y": 140.0, "radius": 19.0},
    {"id": 17, "x": 602.0, "y": 320.0, "radius": 19.0},
    {"id": 18, "x": 678.0, "y": 62.0, "radius": 19.0},
    {"id": 19, "x": 678.0, "y": 174.0, "radius": 19.0},
    {"id": 20, "x": 678.0, "y": 286.0, "radius": 19.0},
    {"id": 21, "x": 678.0, "y": 400.0, "radius": 19.0},
    {"id": 22, "x": 755.0, "y": 230.0, "radius": 19.0}
]

# Shift x-coordinates of the last 11 players (IDs 12-22) by subtracting 394
image_width = 788
shift_amount = image_width / 2  # 394 pixels
for player in players:
    if player["id"] >= 12:
        player["x"] -= shift_amount

# Plot the players
def plot_shifted_players(players, save_path="shifted_player_plot_no_labels.png"):
    plt.figure(figsize=(8, 10))  # Adjusted for 400x500 axis range
    ax = plt.gca()

    for p in players:
        x, y, r = p["x"], p["y"], p["radius"]
        # First 11 players red, next 11 blue
        color = 'red' if p["id"] <= 11 else 'blue'
        ax.add_patch(plt.Circle((x, y), r, fill=True, color=color, alpha=0.5))  # Filled circle
        ax.add_patch(plt.Circle((x, y), r, fill=False, color='black', lw=1))  # Black outline

    plt.xlim(0, 400)
    plt.ylim(0, 500)
    plt.grid(True)
    plt.title("Shifted Soccer Players — Origin at Lower Left")
    plt.xlabel("X (px)")
    plt.ylabel("Y (px)")

    # Center the plot with equal margins
    ax.set_position([0.1, 0.1, 0.8, 0.8])  # Centered plot with 10% margins

    if save_path:
        plt.savefig(save_path, dpi=300)
        print(f"Plot saved to: {save_path}")

    plt.show()

# Print shifted coordinates
print("Shifted Player Coordinates:")
for p in players:
    print(f"ID {p['id']:02d}: x={p['x']:.1f}, y={p['y']:.1f}, r={p['radius']:.1f}")

# Plot with shifted coordinates
plot_shifted_players(players)