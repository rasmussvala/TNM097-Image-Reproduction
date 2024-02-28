function outputImage = create_poke_image(img_path, db_path)

BAR = waitbar(0,'Starting image reproduction...', 'Name', 'Image Reproduction');

% Read img and resize if to small or big
img = imread(img_path);
img = resize_input_image(img);

% Load and resize database images to a smallar and more approachable size
blocksize = 32;
file_paths = dir(fullfile(db_path, '*.jpg'));
[resized_db, db_avg_colors] = load_db(db_path, blocksize, file_paths);

% Perform color clustering on input image to find the most common colors
num_clusters = 50;
color_clusters = perform_color_clustering(img, num_clusters);

% Covert to LAB
db_avg_lab = rgb2lab(db_avg_colors);
clusters_lab = rgb2lab(color_clusters);

% Find the closest colors and create an new array with them 
closest_colors_idx = find_closest_colors_idx(clusters_lab, db_avg_lab);
closest_colors = resized_db(closest_colors_idx);

% --------------------------------------------------------

% Initialize the OUTPUTIMAGE
inputImageSize = size(img);
outputImageSize = inputImageSize * blocksize;
outputImage = zeros(outputImageSize(1), outputImageSize(2), 3);

% Iterate through each block in the OUTPUTIMAGE
for row = 1:blocksize:outputImageSize(1)
    for col = 1:blocksize:outputImageSize(2)
        % Extract LAB values of the current block from INPUTIMAGE
        inputBlockLab = rgb2lab(reshape(img(ceil(row/blocksize), ceil(col/blocksize), :), 1, 1, 3));

        % Initialize variables to store closest image information
        closestImageIdx = 0;
        minMeanDeltaE = inf;

        % Iterate through each image in the DATABASE
        for i = 1:numel(closest_colors)
            % Extract LAB values of the current image from DATABASE
            databasePixelLab = db_avg_lab(closest_colors_idx(i), :);

            % Calculate meanDeltaE between the input block and the current image
            [meanDeltaE, ~] = meanAndMaxDeltaE(inputBlockLab, databasePixelLab);

            % Update closest image information if the current image is closer
            if meanDeltaE < minMeanDeltaE
                minMeanDeltaE = meanDeltaE;
                closestImageIdx = closest_colors_idx(i);
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

% -----------------------------------------

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

% -----------------------------------------

function color_clusters = perform_color_clustering(img, num_clusters)
opts = statset('MaxIter', 1000);
inputImageMatrix = im2double(reshape(img, [], 3));
[~, color_clusters] = kmeans(inputImageMatrix, num_clusters, 'Options', opts);
end

% -----------------------------------------

function closest_colors_idx = find_closest_colors_idx(clusters, db_avg)
num_clusters = size(clusters, 1);
closest_colors_idx = zeros(num_clusters, 1);

for cluster_idx = 1:num_clusters
    color = clusters(cluster_idx, :);
    num_db = size(db_avg, 1);
    minMeanDeltaE = inf;

    for db_idx = 1:num_db
        db_color = db_avg(db_idx, :);
        [meanDeltaE, ~] = meanAndMaxDeltaE(color, db_color);

        if meanDeltaE < minMeanDeltaE
            minMeanDeltaE = meanDeltaE;
            closest_idx = db_idx;
        end
    end
    closest_colors_idx(cluster_idx) = closest_idx;
end

% Remove duplicates
closest_colors_idx = unique(closest_colors_idx);
end
