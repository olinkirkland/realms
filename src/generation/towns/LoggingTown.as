package generation.towns {
    import graph.Cell;

    public class LoggingTown extends Town {

        public function LoggingTown(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "logging-" + id.substr(0, id.indexOf("-"));
        }

        override public function get townType():String {
            return Town.WOOD;
        }
    }
}
