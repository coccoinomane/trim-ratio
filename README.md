# TrimRatio ImageMagick Script

Trim and center an image around the highest detail region without changing its aspect ratio.

The script is useful to trim background around the subject, while keeping the same AR and having control on how much
is trimmed.

It has been succesfully tested with catalogue and e-commerce images.

## ALGORITHM

The algorithm works in four steps:

1. Find the rectangle around the highest detail region using the [-canny option](https://imagemagick.org/discourse-server/viewtopic.php?t=25405) of ImageMagick.
2. Optionally expand the rectangle uniformly in the 4 directions by `u_pad` pixels.
3. Expand the rectangle to retain the aspect ratio of the original image.
4. Optionally expand the rectangle of `h_pad` pixels, ensuring the expansion does not alter the aspect ratio or exceed the image boundaries.

The algorithm works best with images depicting an high detail object on a low detail background, such as the picture of a product on a limbo background.

## REQUIREMENTS

Requires bash with the bc library and [ImageMagick](https://imagemagick.org/) v7.

## USAGE

Make sure the two .sh files are in the same folder, then run the script as:

```bash
./trim-ratio.sh <image> [<h_pad>] [<u_pad>] [<output folder>]
```

The script takes the following 4 parameters:

* `input image`: image file to be processed.
* `h_pad`: how much background to keep left and right of the highest detail region. Default: 0px.
* `u_pad`: how much background to keep in the 4 directions around the highest detail region. Default: 5px.
* `output folder`: where to save output images. Ddefault: current folder.

## H_PAD vs U_PAD

Whether to use `h_pad`, `u_pad` or both depends on two aspects:

1. The aspect ratio (AR) of the highest detail region compared to the AR of the image.
2. The position of the highest detail region in the image.

In general, `h_pad` is better suited if it is important that the highest detail regions stays in the center of the image (although it does not make much difference if AR=1).

For more details please refer to the algorithm section above.

## OUTPUT

The script will output the following images:

1. The image with the highest detail region, padded with `u_pad` pixels in the 4 directions. This file ends with `_upadXX_trim.jpg`.
2. Image 1, expanded to match the aspect ratio of the original image. This file ends with `_upadXX_hpad0.jpg`.
3. Image 2, expanded with `h_pad` pixels of left & right padding and with `h_pad/AR` pixels of top & botton padding. This file ends with `_upadXX_hadYY.jpg`.

If the `h_pad` parameter is zero or not set, only 2 images will be produced because image 2 and 3 are identical.

## EXAMPLES

The following examples use the images in the `img-test` and `img-test-out` folders.

### Trim an image with no padding

```bash
./trim-ratio.sh img-test/_POD0009.jpg 0 5 img-test-out
```

* INPUT: [img-test-out/_POD0009.jpg](img-test/_POD0009.jpg)
* OUTPUT: [img-test-out/_POD0009_upad5_hpad0.jpg](img-test-out/_POD0009_upad5_hpad0.jpg)

### Trim an image and add 200px padding

```bash
./trim-ratio.sh img-test/_POD0009.jpg 200 5 img-test-out
```

* INPUT: [img-test-out/_POD0009.jpg](img-test/_POD0009.jpg)
* OUTPUT: [img-test-out/_POD0009_upad5_hpad200.jpg](img-test-out/_POD0009_upad5_hpad200.jpg)

### Trim an entire folder of images with 200px padding

```bash
find img-test -type f -depth 1 -name "*.jpg" | xargs -I {} ./trim-ratio.sh {} 200 5 img-test-out
```

Process all images in the `img-test` folder.

* INPUT: [img-test folder](img-test)
* OUTPUT: [img-test-out folder](img-test-out)

## TODO

* Get rid of the `u_pad` parameter, which is confusing.
* Instead of just giving `h_pad` the user should be able to specify either horizontal padding (both `left_pad` and `right_pad`) or vertical padding (both `top_pad` and `bottom_pad`). The `smarttrim` script by Fred should provide inspiration on how to parse these arguments.
* Use `printf` instead of `echo` to print floating points to screen so that you can round them.

## CREDITS

A huge thank to Fred Weinhaus for suggesting using canny & blur, and to Snibgo from the ImageMagick forums for helping me understand the steps needed to make the algorithm work ([link to the original forum thread](https://imagemagick.org/discourse-server/viewtopic.php?f=1&t=36443)).
