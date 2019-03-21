package graph {
    import flash.geom.Point;

    public class Center {
        public var index:int;

        /**
         * For generation only
         */

        public var used:Boolean = false;

        /**
         * Properties
         */

        public var point:Point;

        // A set of adjacent polygons
        public var neighbors:Vector.<Center>;

        // A set of bordering edges
        public var borders:Vector.<Edge>;

        // A set of polygon corners
        public var corners:Vector.<Corner>;

        // Elevation (0 to 1)
        public var elevation:Number = 0;

        public function Center() {
            neighbors = new Vector.<Center>();
            borders = new Vector.<Edge>();
            corners = new Vector.<Corner>();
        }
    }
}
