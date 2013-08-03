classdef ConvIntSO < matlab.System
    %Counter Count values above a threshold
    %
    % This is an example of a discrete-time System object with state
    % variables
    %
    % For more examples refer to the documentation.
    % web('http://www.mathworks.com/help/dsp/define-new-system-objects.html', '-browser')
    
    properties
        Threshold = 1
    end
    
    properties (DiscreteState)
        % Define any discrete-time states
        Count
        A1
        B1
        B2
        C1
        C2
        C3
        
        FA1
        FB1
        FB2
        FC1
        FC2
        FC3
    end
    
    methods
        %function obj = Counter(varargin)
            % Support name-value pair arguments
        %    setProperties(obj,nargin,varargin{:});
        %end
    end
    
    methods (Access=protected)
        function setupImpl(obj, u)
            % Implement any tasks that need to be performed only once, such
            % as computation of constants or creation of child System objects
            obj.Count = 0;
            obj.A1 = [uint8(1) ; uint8(1)];
            obj.B1 = [uint8(2) ; uint8(2)];
            obj.B2 = [uint8(2) ; uint8(2)];
            obj.C1 = [uint8(3) ; uint8(3)];
            obj.C2 = [uint8(3) ; uint8(3)];
            obj.C3 = [uint8(3) ; uint8(3)];
            
            obj.FA1 = fi(uint8(1));
            obj.FB1 = fi(uint8(2));
            obj.FB2 = fi(uint8(2));
            obj.FC1 = fi(uint8(3));
            obj.FC2 = fi(uint8(3));
            obj.FC3 = fi(uint8(3));
        end
        
        function resetImpl(obj)
            % Specify initial values for DiscreteState properties
            obj.Count = 0;
            obj.A1 = [uint8(1) ; uint8(1)];
            obj.B1 = [uint8(2) ; uint8(2)];
            obj.B2 = [uint8(2) ; uint8(2)];
            obj.C1 = [uint8(3) ; uint8(3)];
            obj.C2 = [uint8(3) ; uint8(3)];
            obj.C3 = [uint8(3) ; uint8(3)];
            
            obj.FA1 = fi(uint8(1));
            obj.FB1 = fi(uint8(2));
            obj.FB2 = fi(uint8(2));
            obj.FC1 = fi(uint8(3));
            obj.FC2 = fi(uint8(3));
            obj.FC3 = fi(uint8(3));
        end
        
        function y = stepImpl(obj, u)
            % Implement System algorithm. Calculate y as a function of
            % input u and state.
%%%%%%%%%%%%%%%%%%%MATLAB VERSION with uint8 as Input%%%%%%%%%%%%%%%%%%%%%
            if (isa(u,'uint8'))
                
                if (obj.Count == 0)
                    y = obj.A1;
                    obj.A1 = u;
                elseif (obj.Count == 1)
                    y = obj.B2;
                    obj.B2 = obj.B1;
                    obj.B1 = u;
                else
                    y = obj.C3;
                    obj.C3 = obj.C2;
                    obj.C2 = obj.C1;
                    obj.C1 = u;
                end
                obj.Count = obj.Count + 1;
                if (obj.Count == 3)
                    obj.Count = 0;
                end
            end
            
% %%%%%%%%%%%%%%%%%%HDL VERSION with Embedded.fi as Input%%%%%%%%%%%%%%%%%%%%
           if (isa(u,'embedded.fi'))
              if (obj.Count == 0)
                   y = obj.FA1;
                   obj.FA1 = u;
               elseif (obj.Count == 1)
                   y = obj.FB2;
                   obj.FB2 = obj.FB1;
                   obj.FB1 = u;
               else
                   y = obj.FC3;
                   obj.FC3 = obj.FC2;
                  obj.FC2 = obj.FC1;
                   obj.FC1 = u;
               end
               obj.Count = obj.Count + 1;
               if (obj.Count == 3)
                   obj.Count = 0;
               end
           end
        end
        
        function N = getNumInputsImpl(obj)
            % Specify number of System inputs
            N = 1; % Because stepImpl has one argument beyond obj
        end
        
        function N = getNumOutputsImpl(obj)
            % Specify number of System outputs
            N = 1; % Because stepImpl has one output
        end
    end
end


