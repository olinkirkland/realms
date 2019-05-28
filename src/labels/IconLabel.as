package labels {
    import flash.display.Bitmap;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.filters.DropShadowFilter;

    public class IconLabel extends MapLabel {
        public var icon:MovieClip;

        public function IconLabel(bitmap:Bitmap) {
            super();

            icon = new MovieClip();
            var hitArea:Sprite = new Sprite();
            hitArea.graphics.beginFill(0x000000, 0);
            hitArea.graphics.drawCircle(0, 0, 20);
            icon.addChild(hitArea);
            addChild(icon);

            var filter:DropShadowFilter = new DropShadowFilter();
            filter.quality = 1;
            filter.blurX = 5;
            filter.blurY = 5;
            filter.strength = .3;
            filter.distance = 2;

            filters = [filter];
            cacheAsBitmap = true;

            icon.addChild(bitmap);
            bitmap.x = -bitmap.width / 2;
            bitmap.y = -bitmap.height / 2;
        }
    }
}
