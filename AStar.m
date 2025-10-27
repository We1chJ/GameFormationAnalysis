function [path, totalCost] = AStar(adjMatrix, x, y, st, en, GK_POS, MAX_DISTANCE)

    % invert to turn into passing failing rate, thus a minimizing problem
    adjMatrix = 1 - adjMatrix;

    numNodes = size(adjMatrix, 1);

    openSet = [st];
    closedSet = [];

    gScore = inf(1, numNodes);
    gScore(st) = 1;

    fScore = inf(1, numNodes);
    fScore(st) = heuristic(st, en, x, y, MAX_DISTANCE);

    cameFrom = zeros(1, numNodes);

    while ~isempty(openSet)

        [~, idx] = min(fScore(openSet));
        current = openSet(idx);

        if current == en
            [path, totalCost] = rebuildPath(cameFrom, current, adjMatrix);
            return;
        end

        openSet(openSet == current) = [];
        closedSet(end+1) = current;

        for neighbor = 1:numNodes

            if adjMatrix(current, neighbor) == 0 || ismember(neighbor, closedSet)
                continue;
            end

            tentative_gScore = gScore(current) * adjMatrix(current, neighbor);

            if ~ismember(neighbor, openSet)
                openSet(end+1) = neighbor;
            elseif tentative_gScore >= gScore(neighbor)
                continue;
            end

            cameFrom(neighbor) = current;
            gScore(neighbor) = tentative_gScore;
            fScore(neighbor) = tentative_gScore * heuristic(neighbor, en, x, y, MAX_DISTANCE);
        end
    end

    path = [];
    totalCost = -inf;
    disp("No valid path found");

end

function h = heuristic(node, goal, x, y, MAX_DISTANCE)
    dx = x(goal) - x(node);
    dy = y(goal) - y(node);
    h = sqrt(dx^2 + dy^2) / MAX_DISTANCE; % normalize to [0,1]
end

function [path, cost] = rebuildPath(cameFrom, current, adjMatrix)
    path = current;
    while cameFrom(current) ~= 0
        current = cameFrom(current);
        path = [current path];
    end
    cost = 1;
    for i = 1:length(path)-1
        cost = cost * adjMatrix(path(i), path(i+1));
    end
end
