classdef CEC20_RWCO53 < Problem
    % <Single> <Constrained>

    %------------------------------- Copyright --------------------------------
    % Copyright (c) 2022 Yanchi Li. You are free to use the MTO-Platform for
    % research purposes. All publications which use this platform or any code
    % in the platform should acknowledge the use of "MTO-Platform" and cite
    % or footnote "https://github.com/intLyc/MTO-Platform"
    %--------------------------------------------------------------------------

    methods
        function obj = CEC20_RWCO53(name)
            obj = obj@Problem(name);
            obj.sub_eva = eva_CEC20_RWCO(53);
        end

        function Tasks = getTasks(obj)
            Tasks(1) = benchmark_CEC20_RWCO(53);
        end
    end
end
