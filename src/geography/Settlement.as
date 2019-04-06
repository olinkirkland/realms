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

        public function Settlement(cell:Cell, id:String) {
            this.cell = cell;
            this.id = id;

            influence = cell.desirability;

            //setup();
        }
    }
}
