# TrimRatio - Trim an image keeping same Aspect Ratio

Trim an image around the highest detail region without changing its aspect ratio.

Requires bash with the bc library and [ImageMagick](https://imagemagick.org/) v7.

## Examples

The following examples use the images in the `img-test` and `img-test-out` folders.

### Trim an image with no padding

```bash
./trim-ratio.sh img-test/_POD0009.jpg 0 img-test-out
```

Will generate two images:

* *img-test-out/_POD0009_blur5_trim.jpg* with the highest detail region.
* *img-test-out/_POD0009_blur5_pad0.jpg* with the highest detail region plus enough background to maintain the original aspect ratio.

### Trim an image and add 200px padding

```bash
./trim-ratio.sh img-test/_POD0009.jpg 200 img-test-out
```

Will generate two images:

* *img-test-out/_POD0009_blur5_trim.jpg* with the highest detail region.
* *img-test-out/_POD0009_blur5_pad200.jpg* with the highest detail region plus enough background to maintain the original aspect ratio plus 200px padding in all directions, where the padding is taken from the background of the original image.

### Trim an entire folder of images with 200px padding

```bash
find img-test -type f -depth 1 -name "*.jpg" | xargs -I {} ./trim-ratio.sh {} 200 img-test-out
```

For each image in the `img-test` folder, two files will be generated: one with the highest detail region (_trim.jpg), and one with the 200px padding (_pad200.jpg).
