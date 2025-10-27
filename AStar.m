function [path, totalCost] = AStar(adjMatrix, st, en, XG)

    adjMatrix = max(adjMatrix, 1e-6);
    adjCost = 1 - adjMatrix;

    numNodes = size(adjMatrix, 1);

    openSet = [st];
    closedSet = [];

    gScore = inf(1, numNodes);
    gScore(st) = 1;

    fScore = inf(1, numNodes);
    fScore(st) = heuristic(st, XG);

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

            if adjCost(current, neighbor) == 0 || ismember(neighbor, closedSet)
                continue;
            end

            tentative_gScore = gScore(current) * adjCost(current, neighbor);

            if ~ismember(neighbor, openSet)
                openSet(end+1) = neighbor;
            elseif tentative_gScore >= gScore(neighbor)
                continue;
            end

            cameFrom(neighbor) = current;
            gScore(neighbor) = tentative_gScore;
            fScore(neighbor) = tentative_gScore + heuristic(neighbor, XG);
        end
    end

    path = [];
    totalCost = -inf;
    disp("No valid path found");

end


function h = heuristic(node, XG)
    h = 1 - XG(node);
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
