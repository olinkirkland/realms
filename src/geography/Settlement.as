package geography {
    import flash.geom.Point;

    import graph.Cell;

    public class Settlement {
        // Only for generation
        public var used:Boolean;

        public var cell:Cell;
        public var id:String;
        public var influence:int;
        public var point:Point;
        public var name:String;

        public function Settlement(cell:Cell, id:String) {
            this.cell = cell;
            this.id = id;

            // todo precise settlement placement
            this.point = cell.point;

            influence = cell.desirability;

            setup();
        }

        public function setup():void {
            // Pick name
            name = id.substr(0, id.indexOf("-"));
        }
    }
}
