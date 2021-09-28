function valid = validateData(data)

%to check for signal flats will use diff
%find diff that is less than some tolerance. If multiple consecutive
%points less than that tolerance then there is a flat
%ISSUE: THE FLATNESS DETECTOR IS TOO SELECTIVE --  some signals
%   have small portions that are junk but most of the long signal is
%   fine. This signal will still be marked as junk and filtered out
%   ex. see 3000063_0019.txt for the PLETH signal (col 3)

valid = true;
tol = 1e-4;
diff_check = (( diff(data)<tol ) & ( diff(data)>-tol )).*1;
multiple_pts = 30;
if( any( movmean(diff_check, multiple_pts-1)>=1) ) %use moving mean to find multiple non changing pts
    valid = false;
end

end

