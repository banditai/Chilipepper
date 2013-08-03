classdef ConvDeIntSO < matlab.System
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
        
        FA1
        FB1
        FB2
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
            obj.A1 = [2 ; 2];
            obj.B1 = [1 ; 1];
            obj.B2 = [1 ; 1];
            
            obj.FA1 = fi(uint8(1));
            obj.FB1 = fi(uint8(1));
            obj.FB2 = fi(uint8(1));
        end
        
        function resetImpl(obj)
            % Specify initial values for DiscreteState properties
            obj.Count = 0;
            obj.A1 = [2 ; 2];
            obj.B1 = [1 ; 1];
            obj.B2 = [1 ; 1];
            
            obj.FA1 = fi(uint8(1));
            obj.FB1 = fi(uint8(1));
            obj.FB2 = fi(uint8(1));
        end
        
        function y = stepImpl(obj, u)
            % Implement System algorithm. Calculate y as a function of
            % input u and state.
%%%%%%%%%%%%%%%%%%%MATLAB VERSION with Double as Input%%%%%%%%%%%%%%%%%%%%%
            if (isa(u,'double'))
                if (obj.Count == 0)
                    y = obj.B2;
                    obj.B2 = obj.B1;
                    obj.B1 = u;
                elseif (obj.Count == 1)
                    y = obj.A1;
                    obj.A1 = u;
                else
                    y = u;
                end
                obj.Count = obj.Count + 1;
                if (obj.Count == 3)
                    obj.Count = 0;
                end
            end
            
% %%%%%%%%%%%%%%%%%%HDL VERSION with Embedded.fi as Input%%%%%%%%%%%%%%%%%%%%
            if (isa(u,'embedded.fi'))
              if (obj.Count == 0)
                  y = obj.FB2;
                  obj.FB2 = obj.FB1;
                  obj.FB1 = u;
              elseif (obj.Count == 1)
                  y = obj.FA1;
                  obj.FA1 = u;
              else
                  y = u;
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

