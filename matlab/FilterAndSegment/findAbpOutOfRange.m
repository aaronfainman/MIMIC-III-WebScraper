function invalid_data = findAbpOutOfRange(abp, sbp_range, dbp_range, window_size)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

[~,locsOfMin] = findpeaks(-abp, 'MinPeakDistance',60);

[~,locsOfMax] = findpeaks(abp, 'MinPeakDistance',60);

t = 1:length(abp);
% plot(t, abp);
% hold on;
% scatter(t(locsOfMin), abp(locsOfMin));
% scatter(t(locsOfMax), abp(locsOfMax));
% hold off;

invalid_sbp = (abp(locsOfMax) < sbp_range(1)) | (abp(locsOfMax) > sbp_range(2));
invalid_dbp = (abp(locsOfMin) < dbp_range(1)) | (abp(locsOfMin) > dbp_range(2));

locsOfMax(invalid_sbp == 0) = [];
locsOfMin(invalid_dbp == 0) = [];

% plot(t, abp);
% hold on;
% scatter(t(locsOfMin), abp(locsOfMin));
% scatter(t(locsOfMax), abp(locsOfMax));
% hold off;

invalid_points = zeros(size(abp));
invalid_points(locsOfMax) = 1;
invalid_points(locsOfMin) = 1;


invalid_data = movmax(invalid_points, window_size);

end

