package generation.towns {
    import generation.*;

    import graph.Cell;

    public class IronMine extends Town {
        public var townType:String = Civilization.townTypeIron;

        public function IronMine(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "iron-" + id.substr(0, id.indexOf("-"));
        }
    }
}
