# TrimRatio ImageMagick Script

Trim and center an image around the highest detail region without changing its aspect ratio.

The script is useful to trim background around the subject, while keeping the same AR and having control on how much
is trimmed.

It has been succesfully tested with catalogue and e-commerce images.

To get the latest version or to contribute, check out out the Github repository:

* <https://github.com/coccoinomane/trim-ratio.>

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
./trim-ratio.sh <image> [<u_pad>] [<h_pad>] [<output folder>]
```

The script takes the following 4 parameters:

* `input image`: image file to be processed.
* `u_pad`: how much background to keep in the 4 directions around the highest detail region. Default: 5px.
* `h_pad`: how much background to keep left and right of the highest detail region. Default: 0px.
* `output folder`: where to save output images. Default: current folder.

Call the script with `u_pad=0` and `h_pad=0` to obtain the trimmed image with just enough background to preserve the AR.

## OUTPUT

The script will output the following images:

1. The image with the highest detail region, padded with `u_pad` pixels in the 4 directions. This file ends with `_upadXX.jpg`.
2. The above image, expanded to match the aspect ratio of the original image. This file ends with `_upadXX_ar.jpg`.
3. The avove image, with `h_pad` pixels of horizontal padding and further expanded to match the AR of the original image. This file ends with `_upadXX_hpadYY_ar.jpg`.

## U_PAD vs H_PAD

Whether to use `u_pad` (uniform padding), `h_pad` (horizontal padding) or both depends on these aspects:

1. The AR of the image.
2. The aspect ratio (AR) of the highest detail region.
3. The position of the highest detail region in the image.
4. How much background space there is around the highest detail region.

If the image is square (AR=1) and is centered with plenty of air, then `u_pad` and `h_pad` are equivalent.

In general, `h_pad` is better suited if it is important that the highest detail regions stays in the center of the image (although it does not make much difference if AR=1).

For more details please refer to the algorithm section above.

## EXAMPLES

The following examples use the images in the `img-test` and `img-test-out` folders.

### Trim an image with no padding

```bash
./trim-ratio.sh img-test/_POD0009.jpg 0 0 img-test-out
```

* INPUT: [img-test-out/_POD0009.jpg](img-test/_POD0009.jpg)
* OUTPUT: [img-test-out/_POD0009_upad5_hpad0.jpg](img-test-out/_POD0009_upad0.jpg)

### Trim an image and add 100px horizontal padding

```bash
./trim-ratio.sh img-test/_POD0009.jpg 0 50 img-test-out
```

* INPUT: [img-test-out/_POD0009.jpg](img-test/_POD0009.jpg)
* OUTPUT: [img-test-out/_POD0009_upad5_hpad50.jpg](img-test-out/_POD0009_upad0_hpad50.jpg)

### Trim an entire folder of images and add 100px horizontal padding

```bash
find img-test -type f -depth 1 -name "*.jpg" -exec ./trim-ratio.sh "{}" 0 50 img-test-out \;
```

Process all images in the `img-test` folder.

* INPUT: [img-test folder](img-test)
* OUTPUT: [img-test-out folder](img-test-out)

## TODO

* Suggestions? [Write an issue in Github](https://github.com/coccoinomane/trim-ratio) :-)

## CREDITS

A huge thank to Fred Weinhaus for suggesting using canny & blur, and to Snibgo from the ImageMagick forums for helping me understand the steps needed to make the algorithm work ([link to the original forum thread](https://imagemagick.org/discourse-server/viewtopic.php?f=1&t=36443)).
