-module (labs_ops).
-behaviour (emas_genetic_ops).
-export ([solution/1, evaluation/2, mutation/2, recombination/3]).

-include_lib("emas/include/emas.hrl").

-type sim_params() :: emas:sim_params().
-type solution() :: emas:solution([0 | 1]).


%% @doc Generates a random solution.
-spec solution(sim_params()) -> solution().
solution(SP) ->
    [random:uniform(2)-1 || _ <- lists:seq(1, SP#sim_params.problem_size)].


%% @doc Evaluates a given solution. Higher is better.
-spec evaluation(solution(), sim_params()) -> float().
evaluation(Solution, _SP) ->
    local_search(Solution).

-spec energy(solution()) -> float().
energy(Solution) ->
    L = length(Solution),
    Cs = [foldzip(drop(Solution, K), Solution)
          || K <- lists:seq(1, L-1)],
    E = lists:foldl(fun (X, Acc) -> X*X + Acc end, 0, Cs),
    L*L*0.5/E.


-spec recombination(solution(), solution(), sim_params()) ->
                           {solution(), solution()}.
recombination(S1, S2, _SP) ->
    Zipped = [recombination_features(F1, F2) || {F1, F2} <- lists:zip(S1, S2)],
    lists:unzip(Zipped).

%% @doc Chooses a random order between the two initial features.
-spec recombination_features(float(), float()) -> {float(), float()}.
recombination_features(F, F) -> {F, F};
recombination_features(F1, F2) ->
    case random:uniform() < 0.5 of
        true -> {F1, F2};
        false -> {F2, F1}
    end.

%% @doc Reproduction function for a single agent (mutation only).
-spec mutation(solution(), sim_params()) -> solution().
mutation(Solution, SP) ->
    lists:map(fun(X) ->
                      case random:uniform() < SP#sim_params.mutation_rate of
                          true -> fnot(X);
                          _ -> X
                      end
              end, Solution).

%% internal functions

drop([], _) -> [];
drop(L, 0) -> L;
drop([_ | T], N) ->
    drop(T, N - 1).

foldzip(A, B) -> foldzip(A, B, 0).

foldzip([], _, Acc) -> Acc;
foldzip(_, [], Acc) -> Acc;
foldzip([HA|TA], [HB|TB], Acc) ->
    foldzip(TA, TB, Acc + dot(HA, HB)).

dot(X, X) -> 1;
dot(_, _) -> -1.

fnot(X) -> -X + 1.

-spec local_search(solution()) -> float().
local_search(Solution) ->
    MaxIterations = 15,
    {_Sol, Eval} = local_search(MaxIterations, Solution, energy(Solution)),
    Eval.

-spec local_search(integer(), solution(), float()) -> {solution(), float()}.
local_search(0, Solution, Evaluation) ->
    {Solution, Evaluation};
local_search(RemainingSteps, Solution, Evaluation) ->
    {BestSol, BestEval} = best_flipped(Solution),
    case BestEval > Evaluation of
        true -> local_search(RemainingSteps-1, BestSol, BestEval);
        _ -> {Solution, Evaluation}
    end.

best_flipped(Solution) ->
    FlippedSols = lists:map(fun (I) -> flip_nth(Solution, I) end,
                            lists:seq(1, length(Solution))),
    First = hd(FlippedSols),
    InitAcc = {First, energy(First)},
    GetBest = fun (S, {AccSol, AccE}) ->
                      E = energy(S),
                      case E > AccE of
                          true -> {S, E};
                          _ -> {AccSol, AccE}
                      end
              end,
    lists:foldl(GetBest, InitAcc, FlippedSols).

%% Random Mutation Hill Climbing
rhmc(Solution) ->
    MaxIterations = 15,
    rhmc(MaxIterations, Solution, energy(Solution)).

rhmc(0, Solution, Evaluation) ->
    {Solution, Evaluation};
rhmc(RemainingSteps, Solution, Evaluation) ->
    {RandomSol, RandomEval} = random_flipped(Solution),
    case RandomEval > Evaluation of
        true -> rhmc(RemainingSteps-1, RandomSol, RandomEval);
        _ -> rhmc(RemainingSteps-1, Solution, Evaluation)
    end.

random_flipped(Solution0) ->
    Solution1 = flip_nth(Solution0, random:uniform(length(Solution0))),
    {Solution1, energy(Solution1)}.

flip_nth(Sol, N) ->
    flip_nth(Sol, [], N).

flip_nth([HS | TS], Acc, 1) ->
    lists:reverse(Acc) ++ [fnot(HS) | TS];
flip_nth([HS | TS], Acc, N) ->
    flip_nth(TS, [HS | Acc], N-1).
