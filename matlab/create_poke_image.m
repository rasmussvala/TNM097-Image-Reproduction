function outputImage = create_poke_image(imagePath)

BAR = waitbar(0,'Starting image reproduction...', 'Name', 'Image Reproduction');

% Input image, the image which will be reproduced
inputImage = imread(imagePath);

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

% Convert the input image to a matrix of RGB values
inputImageSize = size(inputImage);
inputImageMatrix = im2double(reshape(inputImage, [], 3));

% Perform k-means clustering to find the most common colors with increased iterations
num_colors = 10;
[idx, inputImage_commonColors] = kmeans(inputImageMatrix, num_colors);

% Convert avg colors to LAB
dataBase_avgColors_LAB = rgb2lab(dataBase_avgColors);

% Convert common colors to LAB
inputImage_commonColors_LAB = rgb2lab(inputImage_commonColors);

% Initialize matrices to store the mean and max DeltaE values
meanDeltaE_matrix = zeros(inputImageSize(1), inputImageSize(2));
maxDeltaE_matrix = zeros(inputImageSize(1), inputImageSize(2));

% Calc sizes for output image
outputImageSize = inputImageSize * blocksize;
rows = outputImageSize(1);
cols = outputImageSize(2);

% Initialize the output image
outputImage = zeros(outputImageSize(1), outputImageSize(2), 3);

% Iterate through each block in the OUTPUTIMAGE
for row = 1:blocksize:rows
    for col = 1:blocksize:cols
        % Extract LAB values of the current block from INPUTIMAGE
        inputBlockLab = rgb2lab(reshape(inputImage(ceil(row/blocksize), ceil(col/blocksize), :), 1, 1, 3));

        % Initialize variables to store closest image information
        closestImageIdx = 0;
        minMeanDeltaE = inf;

        % Iterate through each image in the DATABASE
        for i = 1:numel(fileList)
            % Extract LAB values of the current image from DATABASE
            databasePixelLab = dataBase_avgColors_LAB(i, :);

            % Calculate meanDeltaE between the input block and the current image
            [meanDeltaE, ~] = meanAndMaxDeltaE(inputBlockLab, databasePixelLab);

            % Update closest image information if the current image is closer
            if meanDeltaE < minMeanDeltaE
                minMeanDeltaE = meanDeltaE;
                closestImageIdx = i;
            end
        end

        % Replace the block in OUTPUTIMAGE with the corresponding block from the closest image
        outputImage(row:(row+blocksize-1), col:(col+blocksize-1), :) = resized_images{closestImageIdx};

        waitbar(row / outputImageSize(1), BAR, sprintf('Reproduction: %.1f%%', row / outputImageSize(1) * 100));
    end
end
close(BAR);

end
