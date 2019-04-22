package generation.towns {
    import generation.*;

    import graph.Cell;

    public class LoggingTown extends Town {
        public var townType:String = Civilization.townTypeTrade;

        public function LoggingTown(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "logging-" + id.substr(0, id.indexOf("-"));
        }
    }
}
