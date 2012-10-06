class GlowFilter extends BitmapFilter
{
  int color;
  num alpha;
  int blurX;
  int blurY;
  num strength;
  int quality;
  bool inner;
  bool knockout;
  bool hideObject;

  GlowFilter([this.color = 0, this.alpha = 1.0, this.blurX = 4, this.blurY = 4, this.strength = 2.0, this.quality = 1, this.inner = false, this.knockout = false, this.hideObject = false]);

  //-------------------------------------------------------------------------------------------------
  //-------------------------------------------------------------------------------------------------

  BitmapFilter clone()
  {
    return new GlowFilter(color, alpha, blurX, blurY, strength, quality, inner, knockout, hideObject);
  }

  //-------------------------------------------------------------------------------------------------

  void apply(BitmapData sourceBitmapData, Rectangle sourceRect, BitmapData destinationBitmapData, Point destinationPoint)
  {
    var sourceContext = sourceBitmapData._getContext();
    var sourceImageData = sourceContext.getImageData(sourceRect.x, sourceRect.y, sourceRect.width, sourceRect.height);
    var sourceData = sourceImageData.data;

    int sourceWidth = sourceRect.width;
    int sourceHeight = sourceRect.height;
    int radiusX = sqrt(5 * blurX * blurX + 1).toInt();
    int radiusY = sqrt(5 * blurY * blurY + 1).toInt();
    int weightX = radiusX * radiusX;
    int weightY = radiusY * radiusY;
    int rx1 = radiusX;
    int rx2 = radiusX * 2;
    int ry1 = radiusY;
    int ry2 = radiusY * 2;
    int destinationWidth = sourceWidth + rx2;
    int destinationHeight = sourceHeight + ry2;
    int sourceWidth4 = sourceWidth * 4;
    int destinationWidth4 = destinationWidth * 4;

    var destinationContext = destinationBitmapData._getContext();
    var destinationImageData = destinationContext.createImageData(destinationWidth, destinationHeight);
    var destinationData = destinationImageData.data;

    List<int> buffer = new List<int>(1024);

    //--------------------------------------------------
    // blur vertical

    for (int x = 0; x < sourceWidth; x++) {
      int dif = 0, sum = weightY >> 1;
      int offsetSource = x * 4 + 3;
      int offsetDestination = (x + rx1) * 4 + 3;

      for (int y = 0; y < destinationHeight; y++) {
        destinationData[offsetDestination] = sum ~/ weightY;
        offsetDestination += destinationWidth4;

        if (y >= ry2) {
          dif -= 2 * buffer[y & 1023] - buffer[(y - ry1) & 1023];
        } else if (y >= ry1) {
          dif -= 2 * buffer[y & 1023];
        }

        int alpha = (y < sourceHeight) ? sourceData[offsetSource] : 0;
        buffer[(y + ry1) & 1023] = alpha;
        sum += dif += alpha;
        offsetSource += sourceWidth4;
      }
    }

    //--------------------------------------------------
    // blur horizontal

    int rColor = (color >> 16) & 0xFF;
    int gColor = (color >>  8) & 0xFF;
    int bColor = (color >>  0) & 0xFF;
    int weightXAlpha = (weightX / (this.alpha + 0.0001)).round().toInt();

    for (int y = 0; y < destinationHeight; y++) {
      int dif = 0, sum = weightX >> 1;
      int offsetSource = y * destinationWidth4 + rx1 * 4 + 3;
      int offsetDestination = y * destinationWidth4;

      for (int x = 0; x < destinationWidth; x++) {
        destinationData[offsetDestination + 0] = rColor;
        destinationData[offsetDestination + 1] = gColor;
        destinationData[offsetDestination + 2] = bColor;
        destinationData[offsetDestination + 3] = sum ~/ weightXAlpha;
        offsetDestination += 4;

        if (x >= rx2) {
          dif -= 2 * buffer[x & 1023] - buffer[(x - rx1) & 1023];
        } else if (x >= rx1) {
          dif -= 2 * buffer[x & 1023];
        }

        int alpha = (x < sourceWidth) ? destinationData[offsetSource] : 0;
        buffer[(x + rx1) & 1023] = alpha;
        sum += dif += alpha;
        offsetSource += 4;
      }
    }

    //--------------------------------------------------

    var sx = destinationPoint.x;
    var sy = destinationPoint.y;
    var dx = destinationPoint.x - rx1;
    var dy = destinationPoint.y - ry1;
    var sRect = new Rectangle(sx, sy, sourceWidth, sourceHeight);
    var dRect = new Rectangle(dx, dy, destinationWidth, destinationHeight);
    var uRect = sRect.union(dRect);

    destinationContext.setTransform(1, 0, 0, 1, 0, 0);
    destinationContext.clearRect(uRect.x, uRect.y, uRect.width, uRect.height);
    destinationContext.putImageData(destinationImageData, dx, dy);

    if (this.hideObject == false)
      destinationContext.drawImage(sourceContext.canvas, sx, sy);
  }
}