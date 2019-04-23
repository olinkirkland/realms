package generation.towns {
    import graph.Cell;

    public class TradeTown extends Town {

        public function TradeTown(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "trade-" + id.substr(0, id.indexOf("-"));
        }

        override public function get townType():String {
            return Town.TRADE;
        }
    }
}
