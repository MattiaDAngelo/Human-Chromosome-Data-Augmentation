% Return the final and straightened grayscale image.
% In the function, some operations are also performed on the binarized image;
% this can be useful when debugging.
function img_str = arms_connection(img_bw_upper_straightened, img_bw_lower_straightened, img_upper_straightened, img_lower_straightened, P_upper, P_lower)
    P_upper = round(P_upper); % (x,y)
    P_lower = round(P_lower); % (x,y)

    % limiting the coordinates of the points within the dimensions of the image
    P_upper(1) = max(1, min(P_upper(1), size(img_bw_upper_straightened, 2)));
    P_upper(2) = max(1, min(P_upper(2), size(img_bw_upper_straightened, 1)));
    P_upper(3) = max(1, min(P_upper(3), size(img_bw_upper_straightened, 2)));
    P_upper(4) = max(1, min(P_upper(4), size(img_bw_upper_straightened, 1)));

    P_lower(1) = max(1, min(P_lower(1), size(img_bw_lower_straightened, 2)));
    P_lower(2) = max(1, min(P_lower(2), size(img_bw_lower_straightened, 1)));
    P_lower(3) = max(1, min(P_lower(3), size(img_bw_lower_straightened, 2)));
    P_lower(4) = max(1, min(P_lower(4), size(img_bw_lower_straightened, 1)));

    bending_centre_upper = [P_upper(1), P_upper(2)];
    unjoined_point_upper = [P_upper(3), P_upper(4)];
    bending_centre_lower = [P_lower(1), P_lower(2)];
    unjoined_point_lower = [P_lower(3), P_lower(4)];

    % determine the horizontal shift required to align the known points in the two images
    shift_x = bending_centre_upper(1) - bending_centre_lower(1);

    if shift_x > 0 % the lower arm must be moved to the right
        % the image is firstly padded with black pixels to the right and then
        % shifted to the right by shift_x; this preserves the non-black pixels (chromosome).
        % binarized image
        img_bw_lower_straightened = padarray(img_bw_lower_straightened, [0 shift_x], 'post');
        img_bw_lower_straightened = circshift(img_bw_lower_straightened, [0, shift_x]);

        % grayscale image
        img_lower_straightened = padarray(img_lower_straightened, [0 shift_x], 'post');
        img_lower_straightened = circshift(img_lower_straightened, [0, shift_x]);

        % updating the x coordinates
        bending_centre_lower = [bending_centre_lower(1)+shift_x, bending_centre_lower(2)];
        unjoined_point_lower = [unjoined_point_lower(1)+shift_x, unjoined_point_lower(2)];
    else % the upper arm must be moved to the right (or not moved at all)
        shift_x = -shift_x;
    
        % binarized image
        img_bw_upper_straightened = padarray(img_bw_upper_straightened, [0 shift_x], 'post');
        img_bw_upper_straightened = circshift(img_bw_upper_straightened, [0, shift_x]);
    
        % grayscale image
        img_upper_straightened = padarray(img_upper_straightened, [0 shift_x], 'post');
        img_upper_straightened = circshift(img_upper_straightened, [0, shift_x]);
    
        % updating the x coordinates
        bending_centre_upper = [bending_centre_upper(1)+shift_x, bending_centre_upper(2)];
        unjoined_point_upper = [unjoined_point_upper(1)+shift_x, unjoined_point_upper(2)];
    end

    % creating the base of the straightened image. The image will have the
    % width of the largest image between the upper arm and the lower arm and
    % the length of the sum of the lengths of the two arms
    width = size(img_bw_upper_straightened,2) - size(img_bw_lower_straightened,2);
    if width > 0
        % binarized image
        img_bw_str = zeros(size(img_bw_upper_straightened,1) + size(img_bw_lower_straightened,1), size(img_bw_upper_straightened,2), "logical");

        % grayscale image
        img_str = zeros(size(img_upper_straightened,1) + size(img_lower_straightened,1), size(img_upper_straightened,2), "uint8");
    else
        % binarized image
        img_bw_str = zeros(size(img_bw_upper_straightened,1) + size(img_bw_lower_straightened,1), size(img_bw_lower_straightened,2), "logical");

        % grayscale image
        img_str = zeros(size(img_upper_straightened,1) + size(img_lower_straightened,1), size(img_lower_straightened,2), "uint8");
    end

    % the image is filled with the pixels of the two arms.
    % binarized image
    img_bw_str(1:size(img_bw_upper_straightened,1), 1:size(img_bw_upper_straightened,2)) = img_bw_upper_straightened;
    img_bw_str(size(img_bw_upper_straightened,1)+1:size(img_bw_upper_straightened,1)+size(img_bw_lower_straightened,1), 1:size(img_bw_lower_straightened,2)) = img_bw_lower_straightened;

    % grayscale image
    img_str(1:size(img_upper_straightened,1), 1:size(img_upper_straightened,2)) = img_upper_straightened;
    img_str(size(img_upper_straightened,1)+1:size(img_upper_straightened,1)+size(img_lower_straightened,1), 1:size(img_lower_straightened,2)) = img_lower_straightened;

    % updating the y coordinates
    bending_centre_lower = [bending_centre_lower(1), bending_centre_lower(2)+size(img_upper_straightened,1)];
    unjoined_point_lower = [unjoined_point_lower(1), unjoined_point_lower(2)+size(img_upper_straightened,1)];

    % The area enclosed by bending_centre_upper, bending_centre_lower,
    % unjoined_point_upper, unjoined_point_lower is modified as follow: 
    % for each pixel, the values of the surrounding non-black pixels (using a radius of 1) 
    % are averaged and this value replaces the value of the current pixel.
    % This operation is performed on the grayscale image only.
    y_upper = min(bending_centre_upper(2), unjoined_point_upper(2));
    y_lower = max(bending_centre_lower(2), unjoined_point_lower(2));    
    if unjoined_point_upper(1) - unjoined_point_lower(1) == 0 % this handle the case where the unjoined points have the same abscissa
        if unjoined_point_upper(1) < bending_centre_upper(1)
            column_range = unjoined_point_upper(1):bending_centre_upper(1);
        else
            column_range = bending_centre_upper(1):unjoined_point_upper(1);
        end
        img_str = pixelReconstruction(img_str, y_upper:y_lower, column_range);
    else % the unjoined points have a different abscissa, so the equation of the straight line through them can be calculated
        m = (unjoined_point_upper(2) - unjoined_point_lower(2)) / (unjoined_point_upper(1) - unjoined_point_lower(1)); % slope
        b = unjoined_point_lower(2) - m * unjoined_point_lower(1); % y-intercept    
        if unjoined_point_upper(1) < bending_centre_upper(1)     
            for r = y_upper:y_lower
                x_line = (r - b) / m; % expected x-value of line at pixel's y-coordinate
                img_str = pixelReconstruction(img_str, r, ceil(x_line):bending_centre_upper(1));
            end
        else        
            for r = y_upper:y_lower
                x_line = (r - b) / m; % expected x-value of line at pixel's y-coordinate
                img_str = pixelReconstruction(img_str, r, bending_centre_upper(1):floor(x_line));
            end
        end
    end
end

% Help function to perform reconstruction of missing pixels.
function img = pixelReconstruction(img, row_range, column_range)    
    for r = row_range
        for c = column_range
            non_black_surrounding_pixels = getSurroundingPixels(img, r, c);
            img(r,c) = mean(non_black_surrounding_pixels);
        end
    end
end

% Return values of non-black surrounding pixels of given pixel (r,c).
function non_black_surrounding_pixels = getSurroundingPixels(img, r, c)
    % radius of the surrounding pixels
    radius = 1;

    % indices of pixels within circular neighborhood
    [columns, rows] = meshgrid(max(1, c-radius) : min(size(img, 2), c+radius), max(1, r-radius) : min(size(img, 1), r+radius));
    idx = sub2ind(size(img), rows(:), columns(:));
    
    % excluding the central pixel
    centre_idx = sub2ind(size(img), r, c);
    idx = idx(idx ~= centre_idx);

    % extracting values of pixels within circular neighborhood
    pixels = img(idx);

    % extracting only the non-black pixels
    non_black_surrounding_pixels = pixels(pixels ~= 0);
end