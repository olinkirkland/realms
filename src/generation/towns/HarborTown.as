package generation.towns {
    import graph.Cell;

    public class HarborTown extends Town {
        public function HarborTown(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "harbor-" + id.substr(0, id.indexOf("-"));
        }

        override public function get townType():String {
            return Town.HARBOR;
        }
    }
}
