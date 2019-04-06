package geography {
    import graph.Cell;

    public class Biome {
        public static var list:Array = [FRESH_WATER, SALT_WATER, TUNDRA, BOREAL_FOREST, GRASSLAND, TEMPERATE_FOREST, SAVANNA, RAIN_FOREST, DESERT, MOUNTAIN];

        // Aquatic
        public static var FRESH_WATER:String = "freshWater";
        public static var SALT_WATER:String = "saltWater";

        // Cold
        public static var TUNDRA:String = "tundra.json";
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
            freshWater_stroke: 0x6c7784,
            saltWater: 0x99A29D,
            saltWater_stroke: 0x6c7784,
            tundra: 0xEAD6B5,
            borealForest: 0x8ba975,
            borealForest_stroke: 0x517743,
            borealForest_bottomStroke: 0x102900,
            grassland: 0xEAD6B5,
            temperateForest: 0xAAAA76,
            temperateForest_stroke: 0x787643,
            temperateForest_bottomStroke: 0x292500,
            savanna: 0xEAD6B5,
            rainForest: 0xEAD6B5,
            rainForest_stroke: 0xEAD6B5,
            desert: 0xEAD6B5,
            mountain: 0x383838
        };

        public static function determineBiome(cell:Cell):String {
            var biome:String;

            // Calculate properties
            var isRiver:Boolean = false;
            var riverAdjacent:Boolean = false;
            var lakeAdjacent:Boolean = false;
            var oceanAdjacent:Boolean = false;
            var mountainAdjacent:Boolean = false;
            for each (var neighbor:Cell in cell.neighbors) {
                if (cell.hasFeatureType(Geography.RIVER))
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

            if (cell.elevation > Map.MOUNTAIN_ELEVATION || (mountainAdjacent && cell.elevation > Map.MOUNTAIN_ELEVATION_ADJACENT))
                biome = MOUNTAIN;

            /**
             * Aquatic
             */

            // Fresh Water
            else if (cell.hasFeatureType(Geography.LAKE))
                biome = FRESH_WATER;

            // Salt Water
            else if (cell.hasFeatureType(Geography.OCEAN))
                biome = SALT_WATER;

            /**
             * Cold
             */

            else if (cell.temperature < .2) {
                if (!isRiver && (cell.moisture > .5 || (cell.moisture > .3 && (riverAdjacent || lakeAdjacent))))
                    biome = BOREAL_FOREST;
                else
                    biome = TUNDRA;
            }

            /**
             * Temperate
             */

            else if (cell.temperature < .6) {
                if (!isRiver && (cell.moisture > .5 || (cell.moisture > .3 && (riverAdjacent || lakeAdjacent))))
                    biome = TEMPERATE_FOREST;
                else
                    biome = GRASSLAND;
            }

            /**
             * Tropical
             */

            else if (cell.temperature <= 1) {
                if (cell.moisture > .5)
                    biome = RAIN_FOREST;
                else if (cell.moisture > .2)
                    biome = SAVANNA;
                else
                    biome = DESERT;
            }

            return biome;
        }
    }
}
