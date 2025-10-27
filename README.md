# Game Formation Analysis Scripts

All scripts use python version `3.13`


## Scripts Usage
- `circleFinding.py` takes in a raw soccer formation image, finds the coordinates the circles of each player on the full court and radius. Producing `processed.png`
- `overlap.py` takes in the processed image and shift the 11 players on the right side to the left side overlapping. Producing `overlapped.png`
- `edges.py` takes in the coordinates and player info to produce the complete graph of 11 players of one team. Producing `k11_player_plot.png`
- `knearestDefender.py` takes in the players coords and the ID of one player to construct the graph of k clotheset defenders. Producing `player_to_defenders_plot.png`