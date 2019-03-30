package geography {
    import graph.Center;

    public class Biome {
        public static var list:Array = [FRESH_WATER, SALT_WATER, TUNDRA, BOREAL_FOREST, GRASSLAND, TEMPERATE_FOREST, SAVANNA, RAIN_FOREST, DESERT, MOUNTAIN];

        // Aquatic
        public static var FRESH_WATER:String = "freshWater";
        public static var SALT_WATER:String = "saltWater";

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
            freshWater: 0x99A29D,
            freshWater_outline: 0x6c7784,
            saltWater: 0x99A29D,
            saltWater_outline: 0x6c7784,
            tundra: 0xEAD6B5,
            borealForest: 0x8ba975,
            borealForest_outline: 0x517743,
            borealForest_bottomOutline: 0x102900,
            grassland: 0xEAD6B5,
            temperateForest: 0xAAAA76,
            temperateForest_outline: 0x787643,
            temperateForest_bottomOutline: 0x292500,
            savanna: 0xEAD6B5,
            rainForest: 0xEAD6B5,
            rainForest_outline: 0xEAD6B5,
            desert: 0xEAD6B5,
            mountain: 0xEAD6B5
        };

        public static function determineBiome(center:Center):String {
            var biome:String;

            // Calculate properties
            var isRiver:Boolean = false;
            var riverAdjacent:Boolean = false;
            var lakeAdjacent:Boolean = false;
            var oceanAdjacent:Boolean = false;
            var mountainAdjacent:Boolean = false;
            for each (var neighbor:Center in center.neighbors) {
                if (center.hasFeatureType(Geography.RIVER))
                    isRiver = true;
                if (neighbor.hasFeatureType(Geography.RIVER))
                    riverAdjacent = true;
                if (neighbor.hasFeatureType(Geography.LAKE))
                    lakeAdjacent = true;
                if (neighbor.hasFeatureType(Geography.OCEAN))
                    oceanAdjacent = true;
                if (neighbor.hasFeatureType(Biome.MOUNTAIN))
                    mountainAdjacent = true;
            }


            /**
             * High Elevation
             */

            if (center.elevation > .9 || (mountainAdjacent && center.elevation > .85))
                biome = MOUNTAIN;

            /**
             * Aquatic
             */

            // Fresh Water
            else if (center.hasFeatureType(Geography.LAKE))
                biome = FRESH_WATER;

            // Salt Water
            else if (center.hasFeatureType(Geography.OCEAN))
                biome = SALT_WATER;

            /**
             * Cold
             */

            else if (center.temperature < .2) {
                if (!isRiver && (center.moisture > .5 || (center.moisture > .3 && (riverAdjacent || lakeAdjacent))))
                    biome = BOREAL_FOREST;
                else
                    biome = TUNDRA;
            }

            /**
             * Temperate
             */

            else if (center.temperature < .6) {
                if (!isRiver && (center.moisture > .5 || (center.moisture > .3 && (riverAdjacent || lakeAdjacent))))
                    biome = TEMPERATE_FOREST;
                else
                    biome = GRASSLAND;
            }

            /**
             * Tropical
             */

            else if (center.temperature <= 1) {
                if (center.moisture > .5)
                    biome = RAIN_FOREST;
                else if (center.moisture > .2)
                    biome = SAVANNA;
                else
                    biome = DESERT;
            }

            return biome;
        }
    }
}
