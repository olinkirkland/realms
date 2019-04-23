package generation.towns {
    import graph.Cell;

    public class FishingTown extends Town {
        public function FishingTown(cell:Cell, id:String) {
            super(cell, id);
        }

        override public function determineName():void {
            // Pick name
            name = "fishing-" + id.substr(0, id.indexOf("-"));
        }

        override public function get townType():String {
            return Town.FISH;
        }
    }
}
