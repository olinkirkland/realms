package generation.towns {
    import generation.*;

    import graph.Cell;

    public class FishingTown extends Town {
        public var townType:String = Civilization.townTypeTrade;

        public function FishingTown(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "fishing-" + id.substr(0, id.indexOf("-"));
        }
    }
}
