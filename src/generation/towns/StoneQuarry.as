package generation.towns {
    import graph.Cell;

    public class StoneQuarry extends Town {

        public function StoneQuarry(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "stone-" + id.substr(0, id.indexOf("-"));
        }

        override public function get townType():String {
            return Town.STONE;
        }
    }
}
