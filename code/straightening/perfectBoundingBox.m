% Return pixel perfect bounding box
% (sometimes the bounding box keeps a blank row at the bottom of the chromosome and 
% a blank column at the right of the chromosome; this function removes them).
function bb = perfectBoundingBox(img)
    bb = findBoundingBox(img);
    cropped_img = imcrop(img, bb);

    row_pixels = cropped_img(size(cropped_img,1), :); % extract the pixels in the bottom row
    if sum(row_pixels > 0) == 0
        % removing the bottom blank row
        bb = [bb(1), bb(2), bb(3), bb(4)-1];
    end
    column_pixels = cropped_img(:, size(cropped_img,2)); % extract the pixels in the rightmost column
    if sum(column_pixels > 0) == 0
        % removing the rightmost blank column
        bb = [bb(1), bb(2), bb(3)-1, bb(4)];
    end
end