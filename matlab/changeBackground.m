% A function that changes the lightness of a Pokémon's background 
% depending on the other image lightness.  

function outputImage = changeBackground(pokemonImage, image)
gray_pokemon = rgb2gray(pokemonImage);
gray_image = rgb2gray(image);

lightness = mean(gray_image, 'all')

threshold_value = 247;
binary_mask = gray_pokemon < threshold_value;

filled_mask = imfill(binary_mask, 'holes');
filled_mask = uint8(filled_mask);

imshow(filled_mask)

outputImage = pokemonImage .* repmat(filled_mask, [1, 1, size(pokemonImage, 3)]);

end
