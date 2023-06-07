% Straightening of the arms of the chromosome based on the width of the vertical projection.
function [straightened_arm_bw, straightened_arm, P_rotated, theta] = arms_straightening(img_bw, img, P)
    vertical_projection_length = Inf;
    % the padding is used to preserve the borders of the chromosome during rotation
    padding = max(round(size(img) / 2));
    for angle = -90:10:90
        A = [cosd(angle) sind(angle) 0; -sind(angle) cosd(angle) 0; 0 0 1];
        img_bw_padded = padarray(img_bw, [padding, padding], 0, 'both');
        img_bw_rotated = imwarp(img_bw_padded, affinetform2d(A));
        bounding_box = perfectBoundingBox(img_bw_rotated);
        img_bw_rotated = imcrop(img_bw_rotated, bounding_box);
        vertical_projection_new = sum(img_bw_rotated, 1);

        % here the vertical projection with the smallest width is taken,
        % i.e. where the arm is straight
        if length(vertical_projection_new) < vertical_projection_length
            vertical_projection_length = length(vertical_projection_new);
            straightened_arm_bw = img_bw_rotated;
            theta = angle;
            rotation_mask = affinetform2d(A);
            bounding_mask = bounding_box;
        end
    end

    % the same operation is applied to the grayscale image
    img_padded = padarray(img, [padding, padding], 0, 'both');
    straightened_arm = imwarp(img_padded, rotation_mask);
    straightened_arm = imcrop(straightened_arm, bounding_mask);

    % calculating the coordinates of the points after the rotation
    [P_rotated_1, P_rotated_2] = pointsRotated(img_bw, [P(1), P(2)], [P(3), P(4)], theta);
        
    % updating the coordinates after cropping the image
    img_bw_rotated = imrotate(img_bw, theta);
    boundingBox = perfectBoundingBox(img_bw_rotated);
    P_rotated_1 = [P_rotated_1(1)-boundingBox(1)+0.5, P_rotated_1(2)-boundingBox(2)+0.5];
    P_rotated_2 = [P_rotated_2(1)-boundingBox(1)+0.5, P_rotated_2(2)-boundingBox(2)+0.5];
    
    P_rotated = [P_rotated_1, P_rotated_2]; % [bending_centre, unjoined_point]
end

% Calculate the coordinates of the points (bending_centre and unjoined_point) after the rotation.
function [P_rotated_1, P_rotated_2] = pointsRotated(img_bw, bending_center, unjoined_point, theta)
    P1 = [bending_center(2); bending_center(1)]; % (y;x)
    P2 = [unjoined_point(2); unjoined_point(1)]; % (y;x)
    img_bw_rotated = imrotate(img_bw, theta);
    rotation_matrix = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
    ImCenterA = (size(img_bw) / 2)'; % centre of the input image
    ImCenterB = (size(img_bw_rotated) / 2)'; % centre of the transformed image
    
    P_rotated_1 = rotation_matrix * (P1 - ImCenterA) + ImCenterB;
    P_rotated_2 = rotation_matrix * (P2 - ImCenterA) + ImCenterB;
    P_rotated_1 = [P_rotated_1(2), P_rotated_1(1)]; % (x,y) % bending_centre
    P_rotated_2 = [P_rotated_2(2), P_rotated_2(1)]; % (x,y) % unjoined_point
end