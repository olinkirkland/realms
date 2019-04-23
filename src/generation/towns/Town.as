package generation.towns {
    import assets.icons.Icons;

    import flash.display.Bitmap;

    import generation.City;

    import graph.Cell;

    public class Town extends City {
        // Town Types
        public static var IRON:String = "iron";
        public static var SALT:String = "salt";
        public static var STONE:String = "stone";
        public static var TRADE:String = "trade";
        public static var WOOD:String = "wood";
        public static var FISH:String = "fish";

        public function Town(cell:Cell, id:String) {
            super(cell, id);
        }

        public function get townType():String {
            return null;
        }
    }
}
