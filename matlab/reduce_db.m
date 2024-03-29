function [] = reduce_db(read_folder, write_folder, num_reduced_images)

% array of all filepaths
filepaths = dir(fullfile(read_folder, '*.jpg'));
num_files = numel(filepaths);

% init
images = cell(1, num_files);
db_avg = zeros(num_files, 3);
delta_e = zeros(num_files, num_files);

% calc avg colors for the pokemons
for i = 1:num_files
    filename = fullfile(read_folder, filepaths(i).name);
    images{i} = im2double(imread(filename));

    % reshape image to a 2D array
    reshaped_images = reshape(images{i}, [], 3);

    db_avg(i, :) = mean(reshaped_images);
end


% find all deltas in colorspace

db_avg_lab = rgb2lab(db_avg);

for i=1:num_files
    for j=1:num_files
        if i == j
            continue
        end
        delta_l = db_avg_lab(i, 1) - db_avg_lab(j, 1);
        delta_a = db_avg_lab(i, 2) - db_avg_lab(j, 2);
        delta_b = db_avg_lab(i, 3) - db_avg_lab(j, 3);

        delta_e(i, j) = sqrt(delta_l.^2 + delta_a.^2 + delta_b.^2);
    end
end

% filter images with threshold
similarity_threshold = 5;
similar_images = cell(1, num_files);
for i = 1:num_files
    similar_images{i} = find(delta_e(i, :) < similarity_threshold);
end

% sorted indexes from most unique image to most common image
[~, sorted_idx] = sort(cellfun('length', similar_images));

% ceate a new folder for the reduced database
newFolderPath = fullfile(write_folder);
if ~exist(newFolderPath, 'dir')
    mkdir(newFolderPath);
end

% save the reduced database to the new folder
for i = 1:num_reduced_images
    [~, filename, ext] = fileparts(filepaths(sorted_idx(i)).name);
    imwrite(images{sorted_idx(i)}, fullfile(newFolderPath, [filename, ext]))
end