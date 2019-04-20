package graph {
    import flash.geom.Point;

    import generation.Biome;

    import generation.Geography;

    import generation.Settlement;

    public class Cell {
        public var index:int;

        /**
         * For generation only
         */

        public var used:Boolean = false;
        public var biome:String;
        public var biomeType:String;
        public var desirability:Number;
        public var region:String;
        public var regionInfluence:int;

        public var cameFrom:Cell;
        public var costSoFar:int;
        public var cost:int;
        public var priority:int;
        public var road:Boolean;

        /**
         * Static Properties
         */

        public var point:Point;
        public var neighbors:Vector.<Cell>;
        public var edges:Vector.<Edge>;
        public var corners:Vector.<Corner>;

        /**
         * Properties
         */

        public var features:Object;
        public var settlement:Settlement;

        public var realTemperature:Number;
        public var temperature:Number;

        public var realLatitude:Number;
        public var latitude:Number;

        public var moisture:Number;
        public var precipitation:Number;
        public var flux:Number;

        public var realElevation:Number;
        private var _elevation:Number;

        public var terrainColor:uint;
        public var coastal:Boolean;

        public function get elevation():Number {
            return _elevation;
        }

        public function set elevation(value:Number):void {
            _elevation = neighbors.length > 0 ? value : 0;
            var e:Number = _elevation < Map.SEA_LEVEL ? 0 : _elevation - Map.SEA_LEVEL;
            realElevation = Util.round(e * 2000, 2);
        }

        public function Cell() {
            neighbors = new Vector.<Cell>();
            edges = new Vector.<Edge>();
            corners = new Vector.<Corner>();

            reset();
        }

        public function hasFeatureType(featureType:String):Boolean {
            for each (var feature:Object in features) {
                if (feature.type == featureType) {
                    return true;
                }
            }
            return false;
        }

        public function getFeaturesByType(featureType:String):Object {
            var obj:Object = {};
            for each (var feature:Object in features) {
                if (feature.type == featureType) {
                    obj[feature.id] = feature;
                }
            }
            return obj;
        }

        public function reset():void {
            // For Generation Only
            used = false;
            biome = null;
            biomeType = null;
            desirability = 0;
            region = null;
            regionInfluence = 0;
            cameFrom = null;
            costSoFar = 0;
            cost = 1;
            priority = 0;

            // Properties
            features = {};
            settlement = null;
            realTemperature = 0;
            temperature = 0;

            realLatitude = 0;
            latitude = 0;

            moisture = 0;
            precipitation = 0;
            flux = 0;

            realElevation = 0;
            _elevation = 0;

            terrainColor = 0;
            coastal = false;

            // Sort neighbors (by lowest elevation)
            neighbors.sort(Sort.sortByLowestElevation);
        }

        public function determineCost():void {
            // Default is 5 because existing roads must be lower and cannot be 0
            cost = 2;
            // Ocean
            if (hasFeatureType(Geography.OCEAN))
                cost = 30;
            // Lake
            if (hasFeatureType(Geography.LAKE))
                cost = 10;
            // Mountain
            if (hasFeatureType(Biome.MOUNTAIN))
                cost = 15;
            // River
            if (hasFeatureType(Geography.RIVER))
                cost = 10;
            // Forest
            if (hasFeatureType(Biome.BOREAL_FOREST) || hasFeatureType(Biome.TEMPERATE_FOREST) || hasFeatureType(Biome.RAIN_FOREST))
                cost = 5;
        }
    }
}
