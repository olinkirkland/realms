package graph {
    import flash.geom.Point;

    import geography.Geography;

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

        // Unique features
        public var biome:String;
        public var biomeType:String;

        public function hasFeatureType(value:String):Boolean {
            for (var key:String in Geography.getInstance().getFeaturesByType(value)) {
                if (features.indexOf(key) >= 0)
                    return true;
            }
            return false;
        }

        public function getFeaturesByType(value:String):Object {
            var obj:Object = {};
            for (var key:String in Geography.getInstance().getFeaturesByType(value)) {
                if (features.indexOf(key) >= 0) {
                    obj[key] = Geography.getInstance().getFeature(key);
                }
            }
            return obj;
        }

        // Temperature
        public var temperature:Number;

        // Moisture
        public var moisture:Number;

        // Precipitation
        public var flux:Number;

        // Elevation
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
            moisture = 0;
            flux = 0;
            elevation = 0;
            biome = null;
        }
    }
}
