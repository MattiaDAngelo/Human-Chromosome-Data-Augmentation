% Perform data augmentation
% In input a RGB version of a grayscale image or just a grayscale image, in output the 23 augmented images
function [augmented_images] = chromosome_augmentation(img)
    % find background color
    [counts, bins] = imhist(img);
    [~, max_index] = max(counts);
    color = bins(max_index);

    augmented_images = cell(1, 345/15);
    i = 1;    
    for theta = 15:15:345 % theta is increased by 15 from 15 to 345
        A = [cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0; 0 0 1]; % rotation matrix
        rotation = imwarp(img, affinetform2d(A));

        % if background color is white, set any pixels that were transformed
        % outside the original image bounds to white
        if color == 255
            mask = ~imwarp(true(size(img)), affinetform2d(A));
            rotation(mask & ~imclearborder(mask)) = color;
        end

        cropped = imcrop(rotation, centerCropWindow2d(size(rotation), size(img))); % the rotated image is cropped to the size of the original image
        b = randomVector(cropped, color); % [y offest, x offset]
        augmented_images{i} = circshift(cropped, b);
        i = i+1;
    end
end

% Calculate random offset vector
function b = randomVector(img, color)
    % binarization
    if color == 255
        img = 255 - img;
    end    
    bw = img > 0;

    bb = findBoundingBox(bw);

    % calculating coordinates of bounding box vertices
    minX = bb(1);
    maxX = minX + bb(3);
    minY = bb(2);
    maxY = minY + bb(4);

    % creating random offsets bounded to image size
    x_offset = randi([0.5-minX, size(img, 2)+0.5-maxX], 1, 1);
    y_offset = randi([0.5-minY, size(img, 1)+0.5-maxY], 1, 1);
    
    b = [y_offset, x_offset];
end