% Find bounding box
% In input a grayscale image, in output the coordinates of the bounding box
function max_bb = findBoundingBox(img)
    s = regionprops(img, "BoundingBox"); % calculates all the chromosome bounding boxes
    if size(img,3) == 3 % if 3-D image
        for i = 1:size(s)
            s(i).BoundingBox = s(i).BoundingBox([1:2,4:5]);
        end
    end
    bb = reshape([s.BoundingBox], 4, []).'; 

    % finding largest bounding box (this is done because some chromosome images present "overflowing" pixels)
    max_bb = bb(1, :);
    j = size(bb, 1);
    for i = 2:j
        if(max_bb(3) < bb(i,3) && max_bb(4) <  bb(i,4))
            max_bb = bb(i, :);
        end
    end
end