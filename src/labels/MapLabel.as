package labels {
    import flash.display.MovieClip;
    import flash.geom.Point;

    public class MapLabel extends MovieClip {
        public var point:Point = new Point(0, 0);

        public function MapLabel() {
            cacheAsBitmap = true;
        }
    }
}
