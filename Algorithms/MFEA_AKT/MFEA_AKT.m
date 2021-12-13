classdef MFEA_AKT < Algorithm
    % @Article{Zhou2021MFEA-AKT,
    %   author     = {Zhou, Lei and Feng, Liang and Tan, Kay Chen and Zhong, Jinghui and Zhu, Zexuan and Liu, Kai and Chen, Chao},
    %   journal    = {IEEE Transactions on Cybernetics},
    %   title      = {Toward Adaptive Knowledge Transfer in Multifactorial Evolutionary Computation},
    %   year       = {2021},
    %   number     = {5},
    %   pages      = {2563-2576},
    %   volume     = {51},
    %   doi        = {10.1109/TCYB.2020.2974100},
    % }

    properties (SetAccess = private)
        rmp = 0.3
        ginterval = 20;
        mu = 2; % index of Simulated Binary Crossover (tunable)
        mum = 5; % index of polynomial mutation
    end

    methods
        function parameter = getParameter(obj)
            parameter = {'rmp: Random Mating Probability', num2str(obj.rmp), ...
                        'ginterval', num2str(obj.ginterval), ...
                        'mu: index of Simulated Binary Crossover (tunable)', num2str(obj.mu), ...
                        'mum: index of polynomial mutation', num2str(obj.mum)};
        end

        function obj = setParameter(obj, parameter_cell)
            count = 1;
            obj.rmp = str2double(parameter_cell{count}); count = count + 1;
            obj.ginterval = str2double(parameter_cell{count}); count = count + 1;
            obj.mu = str2double(parameter_cell{count}); count = count + 1;
            obj.mum = str2double(parameter_cell{count}); count = count + 1;
        end

        function data = run(obj, Tasks, run_parameter_list)
            pop_size = run_parameter_list(1);
            iter_num = run_parameter_list(2);
            eva_num = run_parameter_list(3);
            pop_size = fixPopSize(pop_size, length(Tasks));
            tic

            % initialize
            [population, fnceval_calls, bestobj, data.bestX] = initializeMF(IndividualAKT, pop_size, Tasks, length(Tasks));
            data.convergence(:, 1) = bestobj;
            % initialize akt
            cfb_record = [];
            for i = 1:pop_size
                population(i).isTran = 0;
                population(i).cx_factor = randi(6);
                population(i).parNum = 0;
            end

            generation = 1;
            while generation < iter_num && fnceval_calls < eva_num
                generation = generation + 1;

                % generation
                [offspring, calls] = OperatorGA_AKT.generateMF(1, population, Tasks, obj.rmp, obj.mu, obj.mum);
                fnceval_calls = fnceval_calls + calls;

                % calculate best cx_factor
                imp_num = zeros(1, 6);
                for i = 1:length(offspring)
                    if offspring(i).parNum ~= 0
                        cfc = offspring(i).factorial_costs(offspring(i).skill_factor);
                        pfc = population(offspring(i).parNum).factorial_costs(population(offspring(i).parNum).skill_factor);
                        if (pfc - cfc) / pfc > imp_num(offspring(i).cx_factor)
                            imp_num(offspring(i).cx_factor) = (pfc - cfc) / pfc;
                        end
                    end
                end
                % ginterval
                prcfb_count = zeros(1, 6);
                if any(imp_num)
                    [max_num, max_idx] = max(imp_num);
                else % have not better cx_factor
                    if generation <= obj.ginterval + 1 % former generation
                        prcfb_count(cfb_record(2:generation - 1)) = prcfb_count(cfb_record(2:generation - 1)) + 1;
                    else
                        prcfb_count(cfb_record(generation - obj.ginterval:generation - 1)) = prcfb_count(cfb_record(generation - obj.ginterval:generation - 1)) + 1;
                    end
                    [max_num, max_idx] = max(prcfb_count);
                end
                cfb_record(generation) = max_idx;
                % adaptive cx_factor
                for i = 1:length(offspring)
                    if offspring(i).parNum ~= 0
                        cfc = offspring(i).factorial_costs(offspring(i).skill_factor);
                        pfc = population(offspring(i).parNum).factorial_costs(population(offspring(i).parNum).skill_factor);
                        if (pfc - cfc) / pfc < 0
                            offspring(i).cx_factor = max_idx;
                        end
                    else
                        p = [max_idx, randi(6)];
                        offspring(i).cx_factor = p(randi(2));
                    end
                end

                % selection
                [population, bestobj, data.bestX] = selectMF(population, offspring, Tasks, pop_size, bestobj, data.bestX);
                data.convergence(:, generation) = bestobj;
            end
            data.bestX = bin2real(data.bestX, Tasks);
            data.clock_time = toc;
        end
    end
end
