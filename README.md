# TNM097-Image-Reproduction
This project is part of the course TNM097 - Image Reproduction at LiU. It is implemented in MATLAB and transforms any input image into an image composed of Pokémon characters using k-means clustering to determine the appropriate Pokémon for each pixel. To view samples in full resolution, visit the **/reproduced-images** folder.

## How to Run
To try it out yourself, follow these steps:

1. Clone this repository.
2. Open it in MATLAB.
3. Make sure the **/matlab** folder is on the MATLAB path (right-click the folder to add it to path).
4. Open the Command Window.
5. Call the create_poke_image function with the appropriate arguments:
```MATLAB
create_poke_image("./path/to/image.png", "./pokemon-images/genX");
```
You need to provide the path to an input image and the path to a Pokémon database folder. Currently, only **.png** files are supported for input images. Multiple database options are available within the **/pokemon-images** folder. Note that more Pokémon images in the database will increase the loading time. To reduce the number of similar Pokémon images, use the **reduce_db.m** MATLAB function to create a new folder with fewer Pokémon. For more details, refer to the function.
 
![Pokémons](https://github.com/rasmussvala/TNM097-Image-Reproduction/assets/91534734/38ee59b0-db84-4e66-a887-c20163f90849)
