classdef DE < Algorithm
    % <Single> <None/Constrained>

    %------------------------------- Copyright --------------------------------
    % Copyright (c) 2022 Yanchi Li. You are free to use the MTO-Platform for
    % research purposes. All publications which use this platform or any code
    % in the platform should acknowledge the use of "MTO-Platform" and cite
    % or footnote "https://github.com/intLyc/MTO-Platform"
    %--------------------------------------------------------------------------

    properties (SetAccess = private)
        F = 0.5
        CR = 0.9
    end

    methods
        function parameter = getParameter(obj)
            parameter = {'F: Mutation Factor', num2str(obj.F), ...
                        'CR: Crossover Probability', num2str(obj.CR)};
        end

        function obj = setParameter(obj, parameter_cell)
            count = 1;
            obj.F = str2double(parameter_cell{count}); count = count + 1;
            obj.CR = str2double(parameter_cell{count}); count = count + 1;
        end

        function data = run(obj, Tasks, run_parameter_list)
            sub_pop = run_parameter_list(1);
            sub_eva = run_parameter_list(2);

            convergence = [];
            convergence_cv = [];
            bestX = {};

            for sub_task = 1:length(Tasks)
                Task = Tasks(sub_task);

                % initialize
                [population, fnceval_calls] = initialize(Individual, sub_pop, Task, Task.dims);
                [bestobj, bestCV, best_idx] = min_FP([population.factorial_costs], [population.constraint_violation]);
                bestX_temp = population(best_idx).rnvec;
                converge_temp(1) = bestobj;
                converge_cv_temp(1) = bestCV;

                generation = 1;
                while fnceval_calls < sub_eva
                    generation = generation + 1;

                    % generation
                    [offspring, calls] = OperatorDE.generate(1, population, Task, obj.F, obj.CR);
                    fnceval_calls = fnceval_calls + calls;

                    % selection
                    replace_cv = [population.constraint_violation] > [offspring.constraint_violation];
                    equal_cv = [population.constraint_violation] <= 0 & [offspring.constraint_violation] <= 0;
                    replace_f = [population.factorial_costs] > [offspring.factorial_costs];
                    replace = (equal_cv & replace_f) | replace_cv;

                    population(replace) = offspring(replace);

                    [bestobj_now, bestCV_now, best_idx] = min_FP([population.factorial_costs], [population.constraint_violation]);
                    if bestCV_now <= bestCV && bestobj_now <= bestobj
                        bestobj = bestobj_now;
                        bestCV = bestCV_now;
                        bestX_temp = population(best_idx).rnvec;
                    end
                    converge_temp(generation) = bestobj;
                    converge_cv_temp(generation) = bestCV;
                end
                convergence = [convergence; converge_temp];
                convergence_cv = [convergence_cv; converge_cv_temp];
                bestX = [bestX, bestX_temp];
            end
            data.convergence = gen2eva(convergence);
            data.convergence_cv = gen2eva(convergence_cv);
            data.bestX = uni2real(bestX, Tasks);
        end
    end
end
