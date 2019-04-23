package generation.towns {
    import graph.Cell;

    public class IronMine extends Town {

        public function IronMine(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "iron-" + id.substr(0, id.indexOf("-"));
        }

        override public function get townType():String {
            return Town.IRON;
        }
    }
}
