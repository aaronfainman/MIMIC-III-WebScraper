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

            % Calculate MAE.
            meanPearsonCoeff = mean(pearsonCoeff(Y,T), 3);
    
            % Take mean over mini-batch
            loss = 1 - mean(meanPearsonCoeff);
        end
        
        function p = pearsonCoeff(x, y)
            % Computes the pearson correlation coefficient for x and y, assuming all
            % (x,y) values are paired. This provides a measure of how similarly
            % correlated the two signals are.
            % See Harfiya et al. and the wikipedia page on Pearson's correlation
            % coefficient for more.

            n = length(x);

            sumxy = sum(x.*y);

            sumx = sum(x);
            sumy = sum(y);

            sumx2 = sum(x.^2);
            sumy2 = sum(y.^2);

            p = (n*sumxy - sumx.*sumy)./(sqrt(n*sumx2 - sumx.^2).*sqrt(n*sumy2 - sumy.^2));
        end
    end
end