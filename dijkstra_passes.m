% === STEP 0: Identify columns from your table ===
players = IDDdata;
name = players.Name;                        % Cell array of player names
shirtnumber = players.JerseyNumber;         % Corrected spelling!
team = players.Team;                        % Cell array of team names
xcoord = players.XCoordinate;               % Numeric
ycoord = players.YCoordinate;               % Numeric
passcomp = players.PassCompletion_;         % Numeric
intpg = players.InterceptionsPerGame;       % Numeric

% === STEP 1: Filter by team ===
isFCB = strcmp(team, 'FCB');
isRM  = strcmp(team, 'RM');

x_FCB = xcoord(isFCB);
y_FCB = ycoord(isFCB);
x_RM  = xcoord(isRM);
y_RM  = ycoord(isRM);
intpg_RM = intpg(isRM);

nFCB = sum(isFCB);

% === STEP 2: Compute pairwise distance matrix between FCB players ===
dist_matrix = zeros(nFCB);
for i = 1:nFCB
    for j = 1:nFCB
        if i ~= j
            dist_matrix(i,j) = sqrt((x_FCB(i) - x_FCB(j))^2 + (y_FCB(i) - y_FCB(j))^2);
        end
    end
end

% === STEP 3: Add incomplete pass rate ===
incomplete_pass = 1 - passcomp;
players.IncompletePassRate = incomplete_pass;

% === STEP 4: Compute average interception rate from nearest RM players ===
avg_intercept_matrix = zeros(nFCB);
for i = 1:nFCB
    for j = 1:nFCB
        if i ~= j
            mid_x = (x_FCB(i) + x_FCB(j)) / 2;
            mid_y = (y_FCB(i) + y_FCB(j)) / 2;
            dist_to_RM = sqrt((x_RM - mid_x).^2 + (y_RM - mid_y).^2);
            [~, idx] = mink(dist_to_RM, 3); % 3 nearest opponents
            avg_intercept_matrix(i,j) = mean(intpg_RM(idx));
        end
    end
end

% === STEP 5: Compute weighted adjacency matrix ===
incomplete_FCB = incomplete_pass(isFCB);
weight_matrix = zeros(nFCB);
for i = 1:nFCB
    for j = 1:nFCB
        if i ~= j
            weight_matrix(i,j) = dist_matrix(i,j) * ...
                                 (1 + incomplete_FCB(i)) * ...
                                 (1 + avg_intercept_matrix(i,j));
        end
    end
end

% === STEP 6: Display results ===
disp('--- Weighted Adjacency Matrix (FCB only) ---');
disp(weight_matrix);

% === STEP 7: Create directed graph ===
fcb_names = string(name(isFCB));
fcb_names = strtrim(strrep(fcb_names, '"', ''));

% Construct digraph G (THIS WAS MISSING)
G = digraph(weight_matrix, fcb_names, 'OmitSelfLoops');

% === STEP 8: Define start and end nodes ===
startNode = "Szczesny";     % Make sure this player exists in fcb_names
endNode   = "Lewandowski";  % Same here

disp('Node names in G:');
disp(G.Nodes.Name)

% === STEP 9: Run Dijkstra's algorithm ===
if any(G.Nodes.Name == startNode) && any(G.Nodes.Name == endNode)
    [shortestPath, totalWeight] = shortestpath(G, startNode, endNode);

    fprintf('\nShortest Passing Path: %s\n', strjoin(shortestPath, ' -> '));
    fprintf('Total Path Cost: %.4f\n', totalWeight);

    % === STEP 10: Visualize ===
    figure;
    p = plot(G, 'Layout', 'force', ...
        'NodeLabel', G.Nodes.Name, ...
        'EdgeLabel', round(G.Edges.Weight,2));
    title('FC Barcelona Passing Network');
    highlight(p, shortestPath, 'EdgeColor', 'r', 'LineWidth', 2.5);
    highlight(p, shortestPath, 'NodeColor', 'r');
else
    error('Start or end node not found in the graph.');
end
