package generation.towns {
    import graph.Cell;

    public class SaltMine extends Town {

        public function SaltMine(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "salt-" + id.substr(0, id.indexOf("-"));
        }

        override public function get townType():String {
            return Town.SALT;
        }
    }
}
