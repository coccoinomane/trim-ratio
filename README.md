# TrimRatio - Trim an image keeping same Aspect Ratio

Trim an image around the highest detail region without changing its aspect ratio.

Requires bash with the bc library and [ImageMagick](https://imagemagick.org/) v7.

## USAGE

Run the script as:

```bash
./trim-ratio.sh <input image> [<padding (default 0px)>] [<output folder (default current folder)>] [<blur (default 5px)>]
```

The script will output two files:

* One containing only the highest detail region; this file ends with `_trim.jpg`.
* One with the highest detail region expanded to match the aspect ratio of the original image, plus any optional padding. This file ends either with `_pad0.jpg` if no padding is requested, or with `_padXX.jpg` if padding is requested.

Only the first parameter is required, and that is the input image file; the other parameters are:

* `padding`: how many background pixels to leave around the highest detail region; default is 0 pixels. This is the horizontal padding; the vertical padding will be determined automatically to be the value that keeps the aspect ratio of the output image unchanged.
* `output folder`: folder where to store the two output images; default is the current working directory.
* `blur`: pixel parameter to the -blur command, default is 5 pixels.

## EXAMPLES

The following examples use the images in the `img-test` and `img-test-out` folders.

### Trim an image with no padding

```bash
./trim-ratio.sh img-test/_POD0009.jpg 0 img-test-out
```

Will process the image img-test/_POD0009.jpg ([link](img-test/_POD0009.jpg)) and generate two images:

* *img-test-out/_POD0009_blur5_trim.jpg* with the highest detail region ([link](img-test-out/_POD0009_blur5_trim.jpg)).

* *img-test-out/_POD0009_blur5_pad0.jpg* with the highest detail region plus enough background to maintain the original aspect ratio ([link](img-test-out/_POD0009_blur5_pad0.jpg)).

### Trim an image and add 200px padding

```bash
./trim-ratio.sh img-test/_POD0009.jpg 200 img-test-out
```

Will process the image img-test/_POD0009.jpg ([link](img-test/_POD0009.jpg)) and generate two images:

* *img-test-out/_POD0009_blur5_trim.jpg* with the highest detail region ([link](img-test-out/_POD0009_blur5_trim.jpg)).
* *img-test-out/_POD0009_blur5_pad200.jpg* with the highest detail region plus enough background to maintain the original aspect ratio plus 200px padding in all directions, where the padding is taken from the background of the original image ([link](img-test-out/_POD0009_blur5_pad200.jpg)).

### Trim an entire folder of images with 200px padding

```bash
find img-test -type f -depth 1 -name "*.jpg" | xargs -I {} ./trim-ratio.sh {} 200 img-test-out
```

For each image in the `img-test` folder ([link](img-test)), two files will be generated: one with the highest detail region (_trim.jpg), and one with the 200px padding (_pad200.jpg) ([link to the output folder](img-test-out)).
