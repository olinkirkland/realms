package generation.towns {
    import generation.*;

    import graph.Cell;

    public class SaltMine extends Town {
        public var townType:String = Civilization.townTypeSalt;

        public function SaltMine(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "salt-" + id.substr(0, id.indexOf("-"));
        }
    }
}
