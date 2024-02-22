function outputImage = create_poke_image(imagePath)

% Start the timer
tic;

BAR = waitbar(0,'Starting image reproduction...', 'Name', 'Image Reproduction');

% Input image, the image which will be reproduced
inputImage = imread('../images-to-reproduce/Small.png');
imshow(inputImage)

% Check if the input image is too small or too large
if size(inputImage, 1) < 50 || size(inputImage, 2) < 50
    warning('Input image is too small. Resizing to a larger size.');
    inputImage = imresize(inputImage, 1.5); % Adjust the desired larger size
elseif size(inputImage, 1) > 500 || size(inputImage, 2) > 500
    warning('Input image is too large. Resizing to a smaller size.');
    inputImage = imresize(inputImage, 0.5); % Adjust the desired smaller size
end

% The data containing all of the smaller images
folder = '../pokemon-images/all-pokemons';
fileList = dir(fullfile(folder, '*.jpg'));

% The images are resized to blocksize x blocksize
images = cell(1, numel(fileList));
resized_images = cell(1, numel(fileList));
blocksize = 32;

% Uses showRGB to display all the average colors from the data 
dataBase_avgColors = zeros(numel(fileList), 3);  % Matrix to store average colors (R, G, B)

for i = 1:numel(fileList)
    filename = fullfile(folder, fileList(i).name);
    images{i} = im2double(imread(filename));
    resized_images{i} = imresize(images{i}, [blocksize, blocksize]);
    
    % Calculate average color for each channel (R, G, B)
    dataBase_avgColors(i, 1) = mean(mean(resized_images{i}(:,:,1)));  % Red channel
    dataBase_avgColors(i, 2) = mean(mean(resized_images{i}(:,:,2)));  % Green channel
    dataBase_avgColors(i, 3) = mean(mean(resized_images{i}(:,:,3)));  % Blue channel
end

figure;
showRGB(dataBase_avgColors);
title('RGB of Average Colors from Data');


% Convert the input image to a matrix of RGB values
inputImageSize = size(inputImage);
inputImageMatrix = im2double(reshape(inputImage, [], 3));

% Perform k-means clustering to find the most common colors with increased iterations
num_colors = 50;
opts = statset('MaxIter', 1000);  % Increase the maximum number of iterations
[idx, inputImage_commonColors] = kmeans(inputImageMatrix, num_colors, 'Options', opts);

% Show RGB of common colors in the input image
figure;
showRGB(inputImage_commonColors);
title('RGB of Common Colors in Input Image');

% Converts to LAB (Device independent format)
dataBase_avgColors_LAB = rgb2lab(dataBase_avgColors);

% Converts to LAB (Device independent format)
inputImage_commonColors_LAB = rgb2lab(inputImage_commonColors);

% Initialize matrices to store the mean and max DeltaE values
meanDeltaE_matrix = zeros(inputImageSize(1), inputImageSize(2));
maxDeltaE_matrix = zeros(inputImageSize(1), inputImageSize(2));

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
    for i = 1:numel(fileList)
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
selectedImages = resized_images(selectedImagesIndices);


% Iterate through each block in the OUTPUTIMAGE
for row = 1:blocksize:outputImageSize(1)
    for col = 1:blocksize:outputImageSize(2)
        % Extract LAB values of the current block from INPUTIMAGE
        inputBlockLab = rgb2lab(reshape(inputImage(ceil(row/blocksize), ceil(col/blocksize), :), 1, 1, 3));

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
        outputImage(row:(row+blocksize-1), col:(col+blocksize-1), :) = resized_images{closestImageIdx};
        
        waitbar(row / outputImageSize(1), BAR, sprintf('Reproduction: %.1f%%', row / outputImageSize(1) * 100));
    end
end
close(BAR);

% Stop the timer
totalRuntime = toc;

% Display the total runtime
disp(['Total runtime: ', num2str(totalRuntime), ' seconds']);

end
