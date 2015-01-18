-module (labs_ops).
-behaviour (emas_genetic_ops).
-export ([solution/1, evaluation/2, mutation/2, recombination/3]).
-export ([sdls/2, rhmc/2, default_mem/2]).

-include_lib("emas/include/emas.hrl").

-type sim_params() :: emas:sim_params().
-type solution() :: emas:solution([0 | 1]).

-define(AVAILABLE_MEMETICS, [default_mem, rhmc, sdls]).
-define(DEFAULT_MEMETICS, default_mem).

%% @doc Generates a random solution.
-spec solution(sim_params()) -> solution().
solution(SP) ->
    check_memetics(SP#sim_params.genetic_ops_opts),
    [random:uniform(2)-1 || _ <- lists:seq(1, SP#sim_params.problem_size)].


%% @doc Evaluates a given solution. Higher is better.
-spec evaluation(solution(), sim_params()) -> float().
evaluation(Solution, SP) ->
    {_Sol, Eval} = apply_memetic(mem_evaluation, Solution, SP),
    Eval.

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
    {Sol, _Eval} = apply_memetic(mem_mutation, Solution, SP),
    Sol.

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

check_memetics(GeneticOpsOpts) ->
    [begin
         Mem = proplists:get_value(Type, GeneticOpsOpts, ?DEFAULT_MEMETICS),
         case lists:member(Mem, ?AVAILABLE_MEMETICS) of
             false ->
                 erlang:error({unknown_memetic, Type, Mem});
             true ->
                 ok
         end
     end || Type <- [mem_evaluation, mem_mutation]].

apply_memetic(Type, Solution, SP) ->
    EvalMem = proplists:get_value(Type, SP#sim_params.genetic_ops_opts,
                                  ?DEFAULT_MEMETICS),
    ?MODULE:EvalMem(Solution, SP).

default_mem(Solution0, #sim_params{mutation_rate = Rate}) ->
    Solution1 = lists:map(fun(X) ->
                                  case random:uniform() < Rate of
                                      true -> fnot(X);
                                      _ -> X
                                  end
                          end, Solution0),
    {Solution1, energy(Solution1)}.

%% Steepest Descent Local Search
-spec sdls(solution(), sim_params()) -> float().
sdls(Solution, _SP) ->
    MaxIterations = 15,
    sdls(MaxIterations, Solution, energy(Solution)).

-spec sdls(integer(), solution(), float()) -> {solution(), float()}.
sdls(0, Solution, Evaluation) ->
    {Solution, Evaluation};
sdls(RemainingSteps, Solution, Evaluation) ->
    {BestSol, BestEval} = best_flipped(Solution),
    case BestEval > Evaluation of
        true -> sdls(RemainingSteps-1, BestSol, BestEval);
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
rhmc(Solution, _SP) ->
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
