% Calculate the rotation score based on the global minimum point between two locally maxima points with almost equal amplitude.
% In input the tuning parameters, the binarized image and the rotation angle, in output the score, the bending axis (global_min_index), 
% and masks for rotation and bounding box.
function [Score, global_min_index, rotation_mask, bounding_box] = rotation_score(w1, w2, img, angle)
    % the padding is used to preserve the borders of the chromosome during rotation
    padding = max(round(size(img) / 2));
    A = [cosd(angle) sind(angle) 0; -sind(angle) cosd(angle) 0; 0 0 1]; % rotation matrix - (counterclockwise rotation)
    bw_padded = padarray(img, [padding, padding], 0, 'both');
    rotation_mask = affinetform2d(A);
    bw_rotated = imwarp(bw_padded, affinetform2d(A));
    bounding_box = perfectBoundingBox(bw_rotated);
    bw_rotated = imcrop(bw_rotated, bounding_box);    

    % horizontal projection
    horizontal_projection = sum(bw_rotated, 2);
    
    % a Savitzky-Golay filter smoothes out the horizontal projection to ignore small deflections
    hp_smoothed = sgolayfilt(horizontal_projection, 3, 11); 

    % calculation of minima and maxima points
    inverted_hp_smoothed = max(hp_smoothed) - hp_smoothed;
    [local_minima, local_minima_indexes] = findpeaks(inverted_hp_smoothed);
    local_minima = max(hp_smoothed) - local_minima;

    if isempty(local_minima)
        Score = Inf;
        global_min_index = -1;
        return
    end
    
    [global_min, index] = min(local_minima); % global minimum
    global_min_index = local_minima_indexes(index); % index of global minimum inside the horizontal projection

    hp_sx = hp_smoothed(1:global_min_index-1); % points before the global minimum
    if length(hp_sx) < 3
        local_maxima_sx = [];
    else
        [local_maxima_sx, ~] = findpeaks(hp_sx);        
        [global_max_sx, ~] = max(local_maxima_sx);
    end

    hp_dx = hp_smoothed(global_min_index+1:length(hp_smoothed)); % points after the global minimum
    if length(hp_dx) < 3
        local_maxima_dx = [];
    else
        [local_maxima_dx, ~] = findpeaks(hp_dx);
        [global_max_dx, ~] = max(local_maxima_dx);
    end

    if isempty(local_maxima_sx) || isempty(local_maxima_dx)
        Score = Inf;
        return
    end

    % calculation of the rotation score
    P1 = global_max_sx; % amplitude of the largest locally global maximum (sx)
    P2 = global_max_dx; % amplitude of the largest locally global maximum (dx)
    P3 = global_min; % amplitude of the global minimum residing in between P1 and P2
    R1 = abs(P1 - P2) / (P1 + P2); % represents how much P1 and P2 have similar amplitudes
    R2 = P3 / (P1 + P2); % represents the amplitude of the global minimum relatively to the two global maxima
    Score = w1 * R1 + w2 * R2;
end