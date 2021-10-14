classdef pearsonRegressionLayer < nnet.layer.RegressionLayer
    % Example custom regression layer with mean-absolute-error loss.
    
    methods
        function layer = pearsonRegressionLayer(name)
            % layer = maeRegressionLayer(name) creates a
            % mean-absolute-error regression layer and specifies the layer
            % name.
			
            % Set layer name.
            layer.Name = name;

            % Set layer description.
            layer.Description = 'Pearson Correlation Error';
        end
        
        function loss = forwardLoss(layer, Y, T)
            % loss = forwardLoss(layer, Y, T) returns the MAE loss between
            % the predictions Y and the training targets T.

            % Calculate Pearson coeff.

	    n = length(Y);

            sumYT = sum(Y.*T);

            sumY = sum(Y);
            sumT = sum(T);

            sumY2 = sum(Y.^2);
            sumT2 = sum(T.^2);

            p = (n*sumYT - sumY.*sumT)./(sqrt(n*sumY2 - sumY.^2).*sqrt(n*sumT2 - sumT.^2));

            meanPearsonCoeff = mean(p, 3);
    
            % Take mean over mini-batch
            loss = 1 - mean(meanPearsonCoeff);
        end
        
    end
end
