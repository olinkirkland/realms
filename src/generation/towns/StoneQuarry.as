package generation.towns {
    import generation.*;

    import graph.Cell;

    public class StoneQuarry extends Town {
        public var townType:String = Civilization.townTypeStone;

        public function StoneQuarry(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "stone-" + id.substr(0, id.indexOf("-"));
        }
    }
}
