% Separate the arms of the chromosome according to the bending axis (bending_centre_y)
% and find the coordinates of the bending centre and the unjoined points.
function [img_bw_upper, img_bw_lower, img_upper, img_lower, P_upper, P_lower] = arms_separation(img_bw, img, bending_centre_y)
    % binarized image
    img_bw_upper = img_bw(1:bending_centre_y, 1:size(img_bw,2));
    img_bw_lower = img_bw(bending_centre_y+1:size(img_bw,1), 1:size(img_bw,2));

    % grayscale image
    img_upper = img(1:bending_centre_y, 1:size(img_bw,2));
    img_lower = img(bending_centre_y+1:size(img_bw,1), 1:size(img_bw,2));

    % finding the x coordinate of the bending centre knowing that it is the most outward intersecting point 
    % between the bending axis and the chromosome body. The opposite point is the unjoined point.
    % upper
    x1_upper = find(img_bw_upper(bending_centre_y,:) == 1, 1);
    x2_upper = find(img_bw_upper(bending_centre_y,:) == 1, 1, 'last');
    dist1 = x1_upper - 1;
    dist2 = size(img_bw, 2) - x2_upper;
    if dist1 < dist2
        bending_centre_upper = [x1_upper, bending_centre_y];
        unjoined_point_upper = [x2_upper, bending_centre_y];
    else
        bending_centre_upper = [x2_upper, bending_centre_y];
        unjoined_point_upper = [x1_upper, bending_centre_y];
    end

    % lower
    x1_lower = find(img_bw_lower(1,:) == 1, 1);
    x2_lower = find(img_bw_lower(1,:) == 1, 1, 'last');
    dist1 = x1_lower - 1;
    dist2 = size(img_bw, 2) - x2_lower;
    if dist1 < dist2
        bending_centre_lower = [x1_lower, 1];
        unjoined_point_lower = [x2_lower, 1];
    else
        bending_centre_lower = [x2_lower, 1];
        unjoined_point_lower = [x1_lower, 1];
    end

    P_upper = [bending_centre_upper, unjoined_point_upper];
    P_lower = [bending_centre_lower, unjoined_point_lower];
end