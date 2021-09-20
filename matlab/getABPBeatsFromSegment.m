function segmentBeatLocs = getABPBeatsFromSegment(segmentTime, originalTime, locOfAbpBeats)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
start_idx = find(originalTime == segmentTime(1),1);
end_idx = find(originalTime == segmentTime(end),1);

shifted_beats = locOfAbpBeats - start_idx;
beat_start_idx = find(shifted_beats>0, 1);
beat_end_idx = find(shifted_beats>=(end_idx-start_idx), 1) -1 ;

segmentBeatLocs = shifted_beats(beat_start_idx:beat_end_idx);
end

