function flat_regions = findFlatRegions(data, variance_period, mean_period)
%Returns a signals where 1 corresponds to regions that are mostly flat

if (nargin < 1)
    error('Please provide data')
elseif (nargin == 1)
        variance_period = 50;
        mean_period = 200;
elseif(nargin ==2)
        mean_period=2;       
end

norm_data = normalize(data);


%flat regions will have a variance of approx 0
moving_variance = movvar(norm_data, variance_period);
tol = 1e-2;
low_variance = moving_variance < tol;
%then find regions with consecutively low variances
flat_regions = movmean(low_variance, mean_period) > 0.4;

end

