package generation.towns {
    import generation.City;

    import graph.Cell;

    public class Town extends City {
        // Town Types
        public static var IRON:String = "iron";
        public static var SALT:String = "salt";
        public static var STONE:String = "stone";
        public static var TRADE:String = "trade";
        public static var WOOD:String = "wood";
        public static var HARBOR:String = "harbor";

        public function Town(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function analyze():void {
            super.analyze();
            analysis.town = true;
        }

        public function get townType():String {
            return null;
        }
    }
}
