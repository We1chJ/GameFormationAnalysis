% MAIN_BELLMAN_FORD
% Comprehensive Bellman-Ford analysis in the same graph-construction style
% as GameFormationAnalysis\main.m (Zack's). Builds the adjacency matrix from
% positions and player stats, converts success likelihoods to additive costs,
% runs Bellman-Ford (with predecessor tracking, negative-cycle check, early
% termination), reconstructs the best path, and prints extensive metrics and
% runtime statistics. Also draws optional plots for interpretation.

% WHAT THIS SCRIPT OUTPUTS (console)
% - Graph build summary (22-node dense -> 11-node attackers subgraph)
% - Bellman-Ford best path from source 1 to target 11
% - Total additive cost (sum of -log p) and equivalent success probability
% - Independent verification: product of edge probabilities along the path
% - Relaxations performed, iterations (with early stop), and timing stats
% - Degree summary and Top-10 strongest edges in the attackers subgraph

% OPTIONAL FIGURE (try/catch)
% - Attackers graph (nodes 1..11) with a subset of strong edges and the
%   highlighted best path. If plotting is unavailable, analysis still runs.

clear; clc; close all;

fprintf('============================================================\n');
fprintf('     BELLMan-FORD: Formation Passing Graph (Zack-style)\n');
fprintf('============================================================\n\n');

%% 1) INPUT DATA (copied to match Zack\'s main.m style)
% x and y coords of 22 players on the court overlapped
x = [38.0 115.0 115.0 115.0 115.0 192.0 268.0 268.0 345.0 345.0 345.0 54.0 131.0 131.0 131.0 208.0 208.0 284.0 284.0 284.0 284.0 361.0];
y = [230.0  62.0 174.0 286.0 400.0 230.0 140.0 320.0  82.0 230.0 378.0 230.0  78.0 230.0 382.0 140.0 320.0  62.0 174.0 286.0 400.0 230.0];

% Player Stats (aligned with Zack's arrays)
% Assume GK has 100%% Pass Completion, 0%% Interception, 0 XG
pass_completion = [1.0 0.8930 0.9360 0.9020 0.855 0.925 0.866 0.863 0.871 0.842 0.75 0.757 0.8130 0.742 0.741 0.888 0.902 0.885 0.914 0.934 0.867 1.0];
interception    = [0.0 1.39  0.68   1.2    1.38  1.45  0.95  0.47  0.43  0.07  0.2  0.13  0.31   0.12  0.43  0.78  1.13  0.2   1.08  0.8   0.79  0.0];
XG              = [0.0 0.07  0.01   0.09   0.03  0.06  0.4   0.24  0.31  0.64  0.36 0.3   0.39   0.69  0.32  0.05  0.04  0.01  0.17  0.03  0.05  0.0];

numPlayers = numel(x);

%% 2) GRAPH CONSTRUCTION (same approach/logic as Zack's main.m)
% Base distances as the starting adjacency.
% Step 2a: Build a dense, directed 22x22 matrix of Euclidean distances.
% These geometric distances will later be transformed into success
% likelihoods for passes using player pressure and pass completion.
adjMatrix = zeros(numPlayers, numPlayers);
for i = 1:numPlayers
    for j = 1:numPlayers
        dx = x(i) - x(j);
        dy = y(i) - y(j);
        adjMatrix(i, j) = sqrt(dx*dx + dy*dy);
    end
end

% Field image geometry and normalization constants (from main.m)
% MAX_DISTANCE normalizes distances into [0,1] so spatial effects are
% comparable across the field; MAX_INTERCEPTION normalizes interception.
IMG_SIZE_X = 788; % full court
IMG_SIZE_Y = 450;
IMG_SIZE_X_HALF = IMG_SIZE_X/2;

MAX_DISTANCE = sqrt(IMG_SIZE_X_HALF^2 + IMG_SIZE_Y^2);
MAX_INTERCEPTION = max(interception);

% Passing score per player: combination of their pass completion and the
% pressure from the opposing side (mirrors main.m logic)
% Step 2b: For each player i, aggregate normalized opponent interception
% pressure weighted by proximity, then scale by pass_completion(i).
% - If i is an attacker (1..11), opponents are defenders (12..22).
% - If i is a defender (12..22), opponents are attackers (1..11).
passing_score = zeros(1, numPlayers);
for i = 1:numPlayers
    sumInterception = 0;
    if i <= 11
        % Attacker: compute defensive pressure from all defenders
        for j = 12:22
            dis = hypot(x(i) - x(j), y(i) - y(j));
            sumInterception = sumInterception + interception(j) / MAX_INTERCEPTION * ...
                              (1.0 - (dis / MAX_DISTANCE)^2);
        end
    else
        % Defender: compute offensive pressure from all attackers
        for j = 1:11
            dis = hypot(x(i) - x(j), y(i) - y(j));
            sumInterception = sumInterception + interception(j) / MAX_INTERCEPTION * ...
                              (1.0 - (dis / MAX_DISTANCE)^2);
        end
    end
    passing_score(i) = pass_completion(i) * sumInterception;
end

% Step 2c: Convert geometric distance into a success-likelihood score by
% combining endpoint passing scores and a distance penalty term.
for i = 1:numPlayers
    for j = 1:numPlayers
        dis = adjMatrix(i,j);
        normDis = dis / MAX_DISTANCE;
        % Higher passing_score and shorter distance -> higher success likelihood
        adjMatrix(i,j) = (passing_score(i) + passing_score(j)) - normDis^2;
    end
end

% Step 2d: Normalize entries to [0,1] to interpret them as success
% probabilities. Later, we clamp with eps before applying -log.
adjMatrix = adjMatrix / max(adjMatrix(:));

fprintf('Graph built: %d nodes, %d directed edges (dense)\n', numPlayers, numPlayers^2);

%% 3) REDUCE TO ATTACKERS AND DEFINE SOURCE/TARGET
% Focus the analysis on attackers-only play (nodes 1..11), from source
% node 1 to target node 11, consistent with the formation example.
% Zack's A* example uses attackers subgraph 1..11, from node 1 to 11
A_idx = 1:11;
adjA = adjMatrix(A_idx, A_idx);      % success likelihoods in [0,1]
src = 1; tgt = 11;                    % match main.m call signature

fprintf('Subgraph (attackers): |V| = %d, source = %d, target = %d\n\n', numel(A_idx), src, tgt);

%% 4) CONVERT SUCCESS PROBABILITIES TO ADDITIVE COSTS FOR BELLMAN-FORD
% Use cost = -log(max(p, eps)) so the path-sum of costs equals
% -log(product of edge probabilities). Minimizing additive cost
% is equivalent to maximizing multiplicative success.
epsP = 1e-9;                 % avoid log(0)
probA = max(adjA, epsP);
costA = -log(probA);         % all costs >= 0
N = size(costA,1);

% For clarity: no self-loop costs (keep as 0 on diagonal), others defined.
for i = 1:N
    costA(i,i) = 0;
end

%% 5) BELLMan-FORD IMPLEMENTATION (with logs and metrics)
% Standard Bellman-Ford on the dense attackers cost matrix:
% - Initialize distances/pred
% - Relax all edges up to |V|-1 passes (early stop if converged)
% - Extra pass to detect negative cycles (none expected here)
fprintf('Running Bellman-Ford on attackers subgraph...\n');

numRuns = 100;                   % repeat for timing statistics
runTimes = zeros(1,numRuns);
totalRelaxations = 0;            % aggregate over last run for reporting

bestPath = [];
bestDist = inf;
bestProb = 0;

for r = 1:numRuns
    t0 = tic;
    [dist, pred, negCycle, relaxCount, iters] = bellmanFordDense(costA, src);
    runTimes(r) = toc(t0);
    if r == numRuns
        totalRelaxations = relaxCount;
        if negCycle
            fprintf('WARNING: Negative cycle detected (unexpected with -log costs).\n');
        end
        % Reconstruct path src->tgt
        bestPath = reconstructPath(pred, src, tgt);
        bestDist = dist(tgt);
        if ~isempty(bestPath)
            % Convert back to success probability (product of edge probs)
            bestProb = exp(-bestDist);
        end
    end
end

%% 6) REPORT RESULTS
% Report: path nodes, total cost (sum -log p), equivalent success
% probability exp(-cost), and an explicit product of edge probabilities
% along the path for verification. Also print relaxations, size, timing.
fprintf('\n============================================================\n');
fprintf('Bellman-Ford Results (last run)\n');
fprintf('------------------------------------------------------------\n');
if isempty(bestPath)
    fprintf('No path found from %d to %d.\n', src, tgt);
else
    fprintf('Path (nodes): ');
    fprintf('%d', bestPath(1));
    for k = 2:numel(bestPath)
        fprintf(' -> %d', bestPath(k));
    end
    fprintf('\n');
    fprintf('Total additive cost (sum -log p): %.6f\n', bestDist);
    fprintf('Equivalent success likelihood (product p): %.6f\n', bestProb);
    % Verify by direct multiplication along the path
    pathProb = 1.0;
    for k = 1:(numel(bestPath)-1)
        u = bestPath(k); v = bestPath(k+1);
        pathProb = pathProb * probA(u,v);
    end
    fprintf('Product of edge probabilities along path: %.6f\n', pathProb);
end
fprintf('Relaxations performed (last run): %d\n', totalRelaxations);
fprintf('Graph size: |V|=%d, |E|=%d (dense ~%d)\n', N, N*N, N*N);
fprintf('Theoretical complexity: O(|V|*|E|) ~= O(%d)\n', N*(N*N));
fprintf('Iterations performed (last run): %d (cap = |V|-1 = %d)\n', iters, N-1);

% Timing stats
fprintf('\nTiming over %d runs:\n', numRuns);
fprintf('  Mean  time: %.6f s\n', mean(runTimes));
fprintf('  Median time: %.6f s\n', median(runTimes));
fprintf('  Min   time: %.6f s\n', min(runTimes));
fprintf('  Max   time: %.6f s\n', max(runTimes));

%% 7) ADDITIONAL ANALYSIS
% Light graph analytics for interpretation: degree summary (under a very
% small threshold) and Top-K strongest edges by success probability.
% Degrees (treat edges with prob > small threshold as present)
thr = 1e-6;
present = probA > thr;
outdeg = sum(present,2) - 1; % exclude self
indeg  = sum(present,1)' - 1;

fprintf('\nNode degree summary (attackers subgraph)\n');
fprintf('  Avg out-degree: %.2f\n', mean(outdeg));
fprintf('  Avg in-degree : %.2f\n', mean(indeg));
fprintf('  Max out-degree: %d (node %d)\n', max(outdeg), find(outdeg==max(outdeg),1));
fprintf('  Max in-degree : %d (node %d)\n', max(indeg), find(indeg==max(indeg),1));

% Top-10 strongest edges by probability
K = 10;
probs = probA(:);
[sortedP, idxP] = sort(probs, 'descend');
fprintf('\nTop-%d strongest edges by success probability (u->v, p):\n', K);
count = 0;
for m = 1:numel(sortedP)
    if count >= K, break; end
    if sortedP(m) < 1 - 1e-12 % ignore self (p=1 on diag after max)
        [u,v] = ind2sub(size(probA), idxP(m));
        if u ~= v
            fprintf('  %2d -> %2d : p = %.4f\n', u, v, sortedP(m));
            count = count + 1;
        end
    end
end

%% 8) TECHNICAL APPENDIX: BELLMan-FORD MATH & LOGIC
% On-screen recap of the BF equations, initialization, relaxation, and
% negative-cycle detection; also shows the success<->cost equivalence.
fprintf('\n============================================================\n');
fprintf('Technical Appendix: Bellman-Ford Mathematics\n');
fprintf('------------------------------------------------------------\n');
fprintf('Graph model: G = (V, E, w),  |V| = %d\n', N);
fprintf('  Edge success p(u->v) in [0,1], cost w(u,v) = -log( max(p, eps) )\n');
fprintf('  Path cost C(P) = \/_e w(e) = -log( \/_e p(e) )\n');
fprintf('  => Maximizing path success product equals minimizing additive cost.\n');
fprintf('\nInitialization:\n');
fprintf('  d[s] = 0,  d[v] = +inf for v \\ s;  pred[v] = 0\n');
fprintf('\nRelaxation (Dynamic Programming):\n');
fprintf('  For each edge (u,v): if d[u] + w(u,v) < d[v] then\n');
fprintf('    d[v] := d[u] + w(u,v),  pred[v] := u\n');
fprintf('  Repeat for |V|-1 iterations; early-stop if no updates.\n');
fprintf('\nNegative-cycle detection:\n');
fprintf('  If any edge can still be relaxed on iteration |V|, a negative cycle exists.\n');
fprintf('  Here w = -log p >= 0, so negative cycles should not occur (unless data injects them).\n');
fprintf('\nComplexity:\n');
fprintf('  Time: O(|V|*|E|) ~ O(%d) for dense; Space: O(|V|^2) for dense adjacency.\n', N*(N*N));
fprintf('\nBest-path math check (last run):\n');
if isempty(bestPath)
    fprintf('  No path s->t.\n');
else
    fprintf('  d[t] = %.6f,  exp(-d[t]) = %.6f (should equal product of edge p).\n', bestDist, exp(-bestDist));
end

%% 9) OPTIONAL PLOTS
% Visual summary figure (attackers nodes, subset of strong edges, and
% best path). Wrapped in try/catch so the script is robust in headless
% or plotting-limited environments.
try
    figure('Name','Attackers graph + best path','Color','w');
    hold on; axis equal; axis off;
    % Plot all attacker nodes
    scatter(x(A_idx), y(A_idx), 80, 'filled', 'MarkerFaceColor',[0.2 0.5 1]);
    % Label nodes
    for i = 1:numel(A_idx)
        text(x(A_idx(i))+6, y(A_idx(i))+6, sprintf('%d', i), 'Color',[0.15 0.15 0.15]);
    end
    % Draw a subset of stronger edges for readability
    quant = 0.9; % show top 10%% edges by probability
    qv = quantile(probA(:), quant);
    for u = 1:N
        for v = 1:N
            if u~=v && probA(u,v) >= qv
                plot([x(A_idx(u)) x(A_idx(v))], [y(A_idx(u)) y(A_idx(v))], '-', 'Color',[0 0 0 0.12]);
            end
        end
    end
    % Highlight best path if present
    if ~isempty(bestPath)
        P = [x(A_idx(bestPath))' y(A_idx(bestPath))'];
        plot(P(:,1), P(:,2), '-o', 'LineWidth', 3, 'Color',[0.1 0.7 0.1]);
        title(sprintf('Best path %d->%d (success=%.3f)', src, tgt, bestProb));
    else
        title('No path found');
    end
    hold off;
catch ME
    warning('Plotting skipped: %s', ME.message);
end

%% --- Bellman-Ford (dense) helper ---
% bellmanFordDense(C, s)
% Inputs:
%   C  : NxN cost matrix (nonnegative), dense representation
%   s  : source node index (1-based)
% Outputs:
%   dist       : 1xN distances (sum of costs) from s
%   pred       : 1xN predecessors for path reconstruction
%   negCycle   : true if a negative cycle is detected in an extra pass
%   relaxCount : number of successful edge relaxations
%   iters      : number of main relaxation passes executed (<= N-1)
function [dist, pred, negCycle, relaxCount, iters] = bellmanFordDense(C, s)
    N = size(C,1);
    dist = inf(1,N); dist(s) = 0;
    pred = zeros(1,N);
    relaxCount = 0;
    negCycle = false;
    iters = 0;
    % Main relaxation loop (|V|-1 passes)
    for it = 1:N-1
        iters = it;
        updated = false;
        for u = 1:N
            du = dist(u);
            if isinf(du), continue; end
            for v = 1:N
                if u==v, continue; end
                w = C(u,v);
                if isinf(w), continue; end
                nd = du + w;
                if nd < dist(v)
                    dist(v) = nd;
                    pred(v) = u;
                    updated = true;
                    relaxCount = relaxCount + 1;
                end
            end
        end
        if ~updated
            break; % early termination
        end
    end
    % Negative cycle detection
    for u = 1:N
        du = dist(u);
        if isinf(du), continue; end
        for v = 1:N
            if u==v, continue; end
            w = C(u,v);
            if isinf(w), continue; end
            if du + w < dist(v) - 1e-12
                negCycle = true; return;
            end
        end
    end
end

%% --- Reconstruct path helper ---
% reconstructPath(pred, s, t)
% Walk predecessors backward from t to s to recover the path.
% Returns [] if t is unreachable (pred(t)==0) or if a loop is detected
% while traversing predecessors (defensive guard).
function path = reconstructPath(pred, s, t)
    if s==t, path = s; return; end
    if pred(t) == 0, path = []; return; end
    path = t;
    seen = false(1,numel(pred));
    while path(1) ~= s
        u = pred(path(1));
        if u==0 || seen(u)
            path = []; return; % unreachable or loop
        end
        seen(u) = true;
        path = [u path]; %#ok<AGROW>
    end
end
