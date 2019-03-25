package geography {
    public class Biome {
        public static var list:Array = [RAIN_FOREST, SAVANNA, DESERT, TEMPERATE_FOREST, GRASSLAND, TAIGA, TUNDRA];

        // Biome Names
        public static var RAIN_FOREST:String = "rainForest";
        public static var SAVANNA:String = "savanna";
        public static var DESERT:String = "desert";
        public static var TEMPERATE_FOREST:String = "temperateForest";
        public static var GRASSLAND:String = "grassland";
        public static var TAIGA:String = "taiga";
        public static var TUNDRA:String = "tundra";

        public static var colors:Object = {temperateForest: 0x568454, grassland: 0x99aa6f}

        public static function determineBiome(moisture:Number, temperature:Number):String {
            if (moisture > 1)
                moisture = 1;
            if (temperature > 1)
                temperature = 1;

            var biome:String;

            if (moisture > .5) {
                biome = TEMPERATE_FOREST;
            } else {
                biome = GRASSLAND;
            }

            return biome;
        }
    }
}
