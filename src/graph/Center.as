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

        // A set of unique feature ids
        public var features:Vector.<String>;

        // Temperature
        public var temperature:Number;

        // Wind
        public var windDirection:Number;
        public var windSpeed:Number;

        // Moisture
        public var moisture:Number;

        // Elevation (0 to 1)
        private var _elevation:Number;
        public function get elevation():Number {
            return _elevation;
        }

        public function set elevation(value:Number):void {
            _elevation = neighbors.length > 0 ? value : 0;
        }

        public function Center() {
            neighbors = new Vector.<Center>();
            borders = new Vector.<Edge>();
            corners = new Vector.<Corner>();
            features = new Vector.<String>;

            reset();
        }

        public function reset():void {
            // Generation
            used = false;

            // Properties
            features = new Vector.<String>();
            temperature = 0;
            windDirection = 0;
            windSpeed = 0;
            moisture = 0;
            elevation = 0;
        }
    }
}
