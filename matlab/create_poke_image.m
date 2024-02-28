function outputImage = create_poke_image(img_path, db_path)

BAR = waitbar(0,'Starting image reproduction...', 'Name', 'Image Reproduction');

% Read img and resize to proper size
img = imread(img_path);
img = resize_input_image(img);

% Load and preprocess database images
blocksize = 32;
file_paths = dir(fullfile(db_path, '*.jpg'));
[resized_db, db_avg_colors] = load_db(db_path, blocksize, file_paths);

% Convert the input image to a matrix of RGB values
inputImageSize = size(img);
inputImageMatrix = im2double(reshape(img, [], 3));

% Perform k-means clustering to find the most common colors with increased iterations
num_colors = 50;
opts = statset('MaxIter', 1000);  % Increase the maximum number of iterations
[~, inputImage_commonColors] = kmeans(inputImageMatrix, num_colors, 'Options', opts);

% Converts to LAB (Device independent format)
dataBase_avgColors_LAB = rgb2lab(db_avg_colors);

% Converts to LAB (Device independent format)
inputImage_commonColors_LAB = rgb2lab(inputImage_commonColors);

% Initialize the OUTPUTIMAGE
outputImageSize = inputImageSize * blocksize;
outputImage = zeros(outputImageSize(1), outputImageSize(2), 3);

% Initialize a matrix to store the indices of selected images for each color
selectedImagesIndices = zeros(num_colors, 1);

% Iterate through each color in "inputImage_commonColors"
for colorIndex = 1:num_colors
    % Extract LAB values of the current color from INPUTIMAGE_COMMONCOLORS
    inputColorLab = inputImage_commonColors_LAB(colorIndex, :);

    % Initialize variables to store closest image information for the current color
    closestImageIdx = 0;
    minMeanDeltaE = inf;

    % Iterate through each image in the DATABASE
    for i = 1:numel(file_paths)
        % Extract LAB values of the current image from DATABASE
        databasePixelLab = dataBase_avgColors_LAB(i, :);

        % Calculate meanDeltaE between the input color and the current image
        [meanDeltaE, ~] = meanAndMaxDeltaE(inputColorLab, databasePixelLab);

        % Update closest image information if the current image is closer
        if meanDeltaE < minMeanDeltaE
            minMeanDeltaE = meanDeltaE;
            closestImageIdx = i;
        end
    end

    % Store the index of the closest image for the current color
    selectedImagesIndices(colorIndex) = closestImageIdx;
end

% Check for duplicates in selected images and remove them
selectedImagesIndices = unique(selectedImagesIndices);

% Create a new matrix containing 50 unique images of Pokemon based on the selected indices
selectedImages = resized_db(selectedImagesIndices);

% Iterate through each block in the OUTPUTIMAGE
for row = 1:blocksize:outputImageSize(1)
    for col = 1:blocksize:outputImageSize(2)
        % Extract LAB values of the current block from INPUTIMAGE
        inputBlockLab = rgb2lab(reshape(img(ceil(row/blocksize), ceil(col/blocksize), :), 1, 1, 3));

        % Initialize variables to store closest image information
        closestImageIdx = 0;
        minMeanDeltaE = inf;

        % Iterate through each image in the DATABASE
        for i = 1:numel(selectedImages)
            % Extract LAB values of the current image from DATABASE
            databasePixelLab = dataBase_avgColors_LAB(selectedImagesIndices(i), :);

            % Calculate meanDeltaE between the input block and the current image
            [meanDeltaE, ~] = meanAndMaxDeltaE(inputBlockLab, databasePixelLab);

            % Update closest image information if the current image is closer
            if meanDeltaE < minMeanDeltaE
                minMeanDeltaE = meanDeltaE;
                closestImageIdx = selectedImagesIndices(i);
            end
        end

        % Replace the block in OUTPUTIMAGE with the corresponding block from the closest image
        outputImage(row:(row+blocksize-1), col:(col+blocksize-1), :) = resized_db{closestImageIdx};

        waitbar(row / outputImageSize(1), BAR, sprintf('Reproduction: %.1f%%', row / outputImageSize(1) * 100));
    end
end
close(BAR);

end

% --------------- Functions ---------------

function img = resize_input_image(img)
if size(img, 1) < 50 || size(img, 2) < 50
    warning('Input image is too small (under 50 pixels in height or width). Resizing to 150%.');
    img = imresize(img, 1.5);
elseif size(img, 1) > 500 || size(img, 2) > 500
    warning('Input image is too large (over 500 pixels in height or width). Resizing to 50%.');
    img = imresize(img, 0.5);
end
end

function [resized_db, db_avg_colors] = load_db(db_path, blocksize, file_paths)
num_files = numel(file_paths);
resized_db = cell(1, num_files);
db_avg_colors = zeros(num_files, 3);

for i = 1:num_files
    filename = fullfile(db_path, file_paths(i).name);
    image = im2double(imread(filename));
    resized_db{i} = imresize(image, [blocksize, blocksize]);

    db_avg_colors(i, 1) = mean(mean(resized_db{i}(:,:,1)));
    db_avg_colors(i, 2) = mean(mean(resized_db{i}(:,:,2)));
    db_avg_colors(i, 3) = mean(mean(resized_db{i}(:,:,3)));
end
end
