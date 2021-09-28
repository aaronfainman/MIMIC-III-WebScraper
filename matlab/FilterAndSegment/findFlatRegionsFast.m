function flat_regions = findFlatRegionsFast(data, deriv_thresh, mean_period, mean_thresh)
%Returns a signals where 1 corresponds to regions that are mostly flat
% Estimated to be approximately 15% faster than findFlatRegions

if (nargin < 1)
    error('Please provide data')
elseif (nargin == 3)
        mean_thresh = 0.4;
elseif(nargin == 2)
        mean_thresh = 0.4;
        mean_period=200;  
elseif(nargin == 1)
        mean_thresh = 0.4;
        mean_period=200;
        deriv_thresh = 1e-3;
end

norm_data = normalize(data);

deriv = [1; abs(diff(norm_data))];
low_grad = deriv < deriv_thresh;
%then find regions with consecutively low variances
flat_regions = movmean(low_grad, mean_period) > mean_thresh;

end

