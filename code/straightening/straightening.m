% Main function to perform the straightening operation.
% In input a grayscale image or its RGB version, in output the straightened grayscale image or the
% input image if the straightening is not successfull. 
% The input RGB image is converted to a grayscale image.
function straightened_chromosome = straightening(target_img)
    original_img = target_img;
    target_img = im2gray(target_img); % ensures input image to be grayscale

    % the tuning parameters to control the weight of each term in the rotation score S
    % w1 < 1, w2 < 1 and w1 + w2 = 1
    w1 = 0.67;
    w2 = 0.33;
    
    % the threshold used to determine whether a chromosome is bent or straight
    threshold = 0.667;

    % find background color
    [counts, bins] = imhist(target_img);
    [~, max_index] = max(counts);
    color = bins(max_index);

    % binarization
    if color == 255
        target_img = 255 - target_img;
    end
    img_bw = target_img > 0;    
    
    if ~isBent(img_bw, threshold) % if the chromosome is not bent, the input image is returned
        straightened_chromosome = original_img;
        return
    end

    % Calculating the rotation score S
    S = Inf;
    for angle = 0:10:180
        [Score, global_min_index, rm, bb] = rotation_score(w1, w2, img_bw, angle);
        
        % the bending centre of the chromosome is obtained with the smallest score S
        if Score < S
            S = Score;
            theta = angle;
            bending_centre_y = global_min_index;
            rotation_mask = rm;
            bounding_mask = bb;
        end
    end
    if S == Inf
        straightened_chromosome = original_img;
        return
    end

    % rotating and cropping binarized and grayscale images.
    % the padding is used to preserve the borders of the chromosome during rotation
    padding = max(round(size(img_bw) / 2));

    % binarized image
    img_bw = padarray(img_bw, [padding, padding], 0, 'both');
    img_bw = imwarp(img_bw, rotation_mask);
    img_bw = imcrop(img_bw, bounding_mask);

    % grayscale image
    target_img = padarray(target_img, [padding, padding], 0, 'both');
    target_img = imwarp(target_img, rotation_mask);
    target_img = imcrop(target_img, bounding_mask);

    % separation of the arms of the chromosome and calculation of the bending centre point and the unjoined points.
    % P_upper/P_lower is a row vector of four elements containing bending centre x, bending centre y, unjoined point x, unjoined point y
    [img_bw_upper, img_bw_lower, img_upper, img_lower, P_upper, P_lower] = arms_separation(img_bw, target_img, bending_centre_y);

    % straightening of the arms of the chromosome and updating of points coordinates after rotation.
    % upper arm
    [img_bw_upper_straightened, img_upper_straightened, P_upper] = arms_straightening(img_bw_upper, img_upper, P_upper);
           
    % checking if the straightening was successfull
    if P_upper(4) > P_upper(2) || P_upper(2) < size(img_bw_upper_straightened,1) / 2 || P_upper(4) < size(img_bw_upper_straightened,1) / 2
        straightened_chromosome = original_img;
        return
    end

    % lower arm
    [img_bw_lower_straightened, img_lower_straightened, P_lower] = arms_straightening(img_bw_lower, img_lower, P_lower);
    
    % checking if the straightening was successfull
    if P_lower(4) < P_lower(2) || P_lower(2) > size(img_bw_lower_straightened,1) / 2 || P_lower(4) > size(img_bw_lower_straightened,1) / 2
        straightened_chromosome = original_img;
        return
    end

    % arms alignment and creation of the straightened image
    straightened_chromosome = arms_connection(img_bw_upper_straightened, img_bw_lower_straightened, img_upper_straightened, img_lower_straightened, P_upper, P_lower);
        
    % the straightened image is resized to the size of the input image
    sizeDiff = size(original_img, 1:2) - size(straightened_chromosome);
    padding = floor(sizeDiff / 2);
    straightened_chromosome = padarray(straightened_chromosome, abs(padding), 0, 'both');
    
    % adjusting the padding if necessary to ensure that the output image
    % size matches the input image size
    verticalDiff = size(original_img, 1) - size(straightened_chromosome, 1);
    horizontalDiff = size(original_img, 2) - size(straightened_chromosome, 2);
    if verticalDiff > 0
        straightened_chromosome = padarray(straightened_chromosome, [verticalDiff, 0], 0, 'post');
    end
    if horizontalDiff > 0
        straightened_chromosome = padarray(straightened_chromosome, [0, horizontalDiff], 0, 'post');
    end
    if sizeDiff(1) < 0 || sizeDiff(2) < 0
        straightened_chromosome = imcrop(straightened_chromosome, centerCropWindow2d(size(straightened_chromosome), size(original_img, 1:2)));
    end

    % restore image colors if original background was white
    if color == 255
        straightened_chromosome = 255 - straightened_chromosome;
    end
end

% Calculate whether a chromosome is bent or straight: the ratio between the number of white
% pixels in the binarized image and the area of the upright tight fitting
% rectangle containing the chromosome is compared to the whiteness
% threshold "W_threshold".
function bent = isBent(img_bw, W_threshold)
    bb = findBoundingBox(img_bw);
    bb = [bb(1), bb(2), bb(3), bb(4)];

    img_bw = imcrop(img_bw, bb);

    nWhitePixels = sum(img_bw, "all");
    rectArea = bb(3) * bb(4);
    W = nWhitePixels / rectArea;

    bent = W < W_threshold;
end