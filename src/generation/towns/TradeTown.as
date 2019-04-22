package generation.towns {
    import generation.*;

    import graph.Cell;

    public class TradeTown extends Town {
        public var townType:String = Civilization.townTypeTrade;

        public function TradeTown(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "trade-" + id.substr(0, id.indexOf("-"));
        }
    }
}
