package graph {
    import flash.geom.Point;

    public class Cell {
        public var index:int;

        /**
         * For generation only
         */

        public var used:Boolean = false;
        public var biome:String;
        public var biomeType:String;
        /**
         * Properties
         */

        public var point:Point;

        // A set of adjacent polygons
        public var neighbors:Vector.<Cell>;

        // A set of bordering edges
        public var edges:Vector.<Edge>;

        // A set of polygon corners
        public var corners:Vector.<Corner>;

        // A set feature references
        public var features:Object;

        // Settlement placement desirability
        public var desirability:int;

        public function hasFeatureType(type:String):Boolean {
            for each (var feature:Object in features) {
                if (feature.type == type) {
                    return true;
                }
            }
            return false;
        }

        public function getFeaturesByType(type:String):Object {
            var obj:Object = {};
            for each (var feature:Object in features) {
                if (feature.type == type) {
                    obj[feature.id] = feature;
                }
            }
            return obj;
        }

        // Temperature
        public var realTemperature:Number;
        public var temperature:Number;

        // Latitude
        public var realLatitude:Number;
        public var latitude:Number;

        // Moisture
        public var moisture:Number;
        public var precipitation:Number;

        // Flux
        public var flux:Number;

        // Elevation
        private var _elevation:Number;

        public function get elevation():Number {
            return _elevation;
        }

        public function set elevation(value:Number):void {
            _elevation = neighbors.length > 0 ? value : 0;
            var e:Number = _elevation < Map.SEA_LEVEL ? 0 : _elevation - Map.SEA_LEVEL;
            realElevation = Util.round(e * 2000, 2);
        }

        public var realElevation:Number;

        public function Cell() {
            neighbors = new Vector.<Cell>();
            edges = new Vector.<Edge>();
            corners = new Vector.<Corner>();

            reset();
        }

        public function reset():void {
            // Generation
            used = false;

            // Properties
            features = {};
            realTemperature = 0;
            moisture = 0;
            flux = 0;
            elevation = 0;
            biome = null;
            desirability = 0;
        }
    }
}
