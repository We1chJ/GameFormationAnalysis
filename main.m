
% x and y coords of 22 players on the court overlapped
x = [38.0 115.0 115.0 115.0 115.0 192.0 268.0 268.0 345.0 345.0 345.0 54.0 131.0 131.0 131.0 208.0 208.0 284.0 284.0 284.0 284.0 361.0];
y = [230.0 62.0 174.0 286.0 400.0 230.0 140.0 320.0 82.0 230.0 378.0 230.0 78.0 230.0 382.0 140.0 320.0 62.0 174.0 286.0 400.0 230.0];

% Player Stats
% Assume GK has 100% Pass Completion, 0% Interception, 0 XG
pass_completion = [1.0 0.8930 0.9360 0.9020 0.855 0.925 0.866 0.863 0.871 0.842 0.75 0.757 0.8130 0.742 0.741 0.888 0.902 0.885 0.914 0.934 0.867 1.0];
interception = [0.0 1.39 0.68 1.2 1.38 1.45 0.95 0.47 0.43 0.07 0.2 0.13 0.31 0.12 0.43 0.78 1.13 0.2 1.08 0.8 0.79 0.0];
XG = [0.0 0.07 0.01 0.09 0.03 0.06 0.4 0.24 0.31 0.64 0.36 0.3 0.39 0.69 0.32 0.05 0.04 0.01 0.17 0.03 0.05 0.0];

% scatter(x, y);

% Number of players
numPlayers = length(x);

% Construct adjacency matrix based on Euclidean distances as edge weights
adjMatrix = zeros(numPlayers, numPlayers);

for i = 1:numPlayers
    for j = 1:numPlayers
        dx = x(i) - x(j);
        dy = y(i) - y(j);
        adjMatrix(i, j) = sqrt(dx^2 + dy^2);
    end
end

IMG_SIZE_X = 788; % full court
IMG_SIZE_Y = 450;
IMG_SIZE_X_HALF = IMG_SIZE_X/2;

% Calculate the player Passing Score
MAX_DISTANCE = sqrt(IMG_SIZE_X_HALF^2 + IMG_SIZE_Y^2);
MAX_INTERCEPTION = max(interception);
passing_score = zeros(1, numPlayers);
for i = 1:numPlayers
    sumInterception = 0;
    if i <= 11
        % Player i is an attacker → compute defensive pressure from all defenders
        for j = 12:22
            dis = pdist2([x(i) y(i)], [x(j) y(j)]);
            sumInterception = sumInterception + interception(j) / MAX_INTERCEPTION * ...
                              (1.0 - (dis / MAX_DISTANCE)^2);
        end
    else
        % Player i is a defender → compute offensive pressure from all attackers
        for j = 1:11
            dis = pdist2([x(i) y(i)], [x(j) y(j)]);
            sumInterception = sumInterception + interception(j) / MAX_INTERCEPTION * ...
                              (1.0 - (dis / MAX_DISTANCE)^2);
        end
    end

    passing_score(i) = pass_completion(i) * sumInterception;
end

% Edit edge weights using Passing Score
% After this, adjMatrix stores the true passing success likelihood in this
% particular match formations
for i = 1:numPlayers
    for j = 1:numPlayers
        dis = adjMatrix(i,j); % adjMatrix already has the distance
        % Normalize by maximum distance
        normDis = dis / MAX_DISTANCE;
        % Apply passing score effect
        adjMatrix(i,j) = (passing_score(i) + passing_score(j)) - normDis^2; % the farther the distance, the less the passing success likelihood
    end
end

adjMatrix = adjMatrix / max(adjMatrix(:)); % Normalize the adjMatrix to get an edge weight of passing success rate



% ================= SHORTEST PATH PROCESSING =================
numRuns = 100;
times = zeros(1, numRuns);

for i = 1:numRuns
    tic;
    AStar(adjMatrix(1:11, 1:11), 1, 11, XG);
    times(i) = toc;
end

fprintf('Average A* time over %d runs: %.6f seconds\n', ...
        numRuns, mean(times));

