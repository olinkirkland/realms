package labels {
    import flash.display.Bitmap;

    public class IconLabel extends MapLabel {
        public function IconLabel(bitmap:Bitmap, color:uint = 0xffffff) {
            super();

            addChild(bitmap);
            bitmap.x = -bitmap.width / 2;
            bitmap.y = -bitmap.height / 2;
        }
    }
}
