% Support function to perform data augmentation
% In input a 4-D array containing RGB version of grayscale images and their labels, in output the augmented version
function [images, labels] = training_augmentation(images, labels)
    nRotations = 23; % number of rotations performed on each image (just for preallocation and loops; it doesn't change the actual number of rotations performed)
    new_images = repmat(uint8(0),[size(images,1),size(images,2),size(images,3),size(images,4)*nRotations]);
    new_labels = zeros(1,size(images,4)*nRotations);
    for i = 1:size(images,4)
        augmented_images = chromosome_augmentation(images(:,:,:,i));
        for j = 1:size(augmented_images,2)
            new_images(:,:,:,nRotations*(i-1)+j) = augmented_images{j};
            new_labels(nRotations*(i-1)+j) = labels(i);
        end
    end
    images = cat(4,images,new_images);
    labels = [labels,new_labels];
end