package geography {
    import graph.Center;

    public class Biome {
        public static var list:Array = [FRESH_WATER, SALT_WATER, ICE_SHEET, TUNDRA, BOREAL_FOREST, GRASSLAND, TEMPERATE_FOREST, MARSH, SAVANNA, RAIN_FOREST, DESERT, MOUNTAIN];

        // Aquatic
        public static var FRESH_WATER:String = "freshWater";
        public static var SALT_WATER:String = "saltWater";

        // Frigid
        public static var ICE_SHEET:String = "iceSheet";

        // Cold
        public static var TUNDRA:String = "tundra";
        public static var BOREAL_FOREST:String = "borealForest";

        // Temperate
        public static var GRASSLAND:String = "grassland";
        public static var TEMPERATE_FOREST:String = "temperateForest";

        // Tropical
        public static var SAVANNA:String = "savanna";
        public static var RAIN_FOREST:String = "rainForest";

        // Arid
        public static var DESERT:String = "desert";

        // High Elevation
        public static var MOUNTAIN:String = "mountain";

        public static var colors:Object = {
            freshWater: 0x4890B1,
            saltWater: 0x4890B1,
            iceSheet: 0xffffff,
            tundra: 0x93b1e2,
            borealForest: 0x4e7053,
            grassland: 0x99aa6f,
            temperateForest: 0x568454,
            marsh: 0x374046,
            savanna: 0xb0ba6a,
            rainForest: 0x3da334,
            desert: 0xefbc7a,
            mountain: 0xa0a0a0
        };

        public static function determinePrimaryBiome(center:Center):String {
            var biome:String;

            // Calculate properties
            var riverAdjacent:Boolean = false;
            var lakeAdjacent:Boolean = false;
            var oceanAdjacent:Boolean = false;
            for each (var neighbor:Center in center.neighbors) {
                if (neighbor.hasFeatureType(Geography.RIVER))
                    riverAdjacent = true;
                if (neighbor.hasFeatureType(Geography.LAKE))
                    lakeAdjacent = true;
                if (neighbor.hasFeatureType(Geography.OCEAN))
                    oceanAdjacent = true;
            }

            /**
             * Aquatic
             */

            // Fresh Water
            if (center.hasFeatureType(Geography.LAKE)) {
                biome = FRESH_WATER;
            }

            // Salt Water
            if (center.hasFeatureType(Geography.OCEAN)) {
                biome = SALT_WATER;
            }

            /**
             * Frigid
             */

            if (center.temperature < .05) {
                biome = ICE_SHEET;
            }

            /**
             * Cold
             */

            else if (center.temperature < .2) {
                if (center.moisture > .5 || (center.moisture > .3 && (riverAdjacent || lakeAdjacent)))
                    biome = BOREAL_FOREST;
                else
                    biome = TUNDRA;
            }

            /**
             * Temperate
             */

            else if (center.temperature < .6) {
                if (center.moisture > .5 || (center.moisture > .3 && (riverAdjacent || lakeAdjacent)))
                    biome = TEMPERATE_FOREST;
                else
                    biome = GRASSLAND;
            }

            /**
             * Tropical
             */

            else if (center.temperature <= 1) {
                if (center.moisture > .5)
                    biome = RAIN_FOREST
                else if (center.moisture > .2)
                    biome = SAVANNA;
                else
                    biome = DESERT;
            }

            return biome;
        }

        public static function determineSecondaryBiome(center:Center):String {
            var biome:String;

            /**
             * High Elevation
             */

            if (center.elevation > .9)
                biome = MOUNTAIN;

            return biome;
        }
    }
}
