package labels {
    import flash.display.Bitmap;
    import flash.filters.DropShadowFilter;

    public class IconLabel extends MapLabel {
        public function IconLabel(bitmap:Bitmap, text:String = null) {
            super();

            var filter:DropShadowFilter = new DropShadowFilter();
            filter.quality = 1;
            filter.blurX = 5;
            filter.blurY = 5;
            filter.strength = .3;
            filter.distance = 2;

            filters = [filter];
            cacheAsBitmap = true;

            addChild(bitmap);
            bitmap.x = -bitmap.width / 2;
            bitmap.y = -bitmap.height / 2;
        }
    }
}
