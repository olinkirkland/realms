package generation {
    import flash.geom.Point;

    import graph.Cell;

    public class City {
        // Only for generation
        public var used:Boolean;

        public var cell:Cell;
        public var id:String;
        public var influence:int;
        public var point:Point;
        public var name:String;
        public var neighbors:Array;

        public var analysis:Object;

        public function City(cell:Cell, id:String) {
            this.cell = cell;
            this.id = id;

            this.point = new Point(cell.point.x, cell.point.y);

            influence = cell.desirability;

            neighbors = [];

            determineName();
        }

        public function analyze():void {
            analysis = {};

        }

        public function determineName():void {
            // Pick name
            name = id.substr(0, id.indexOf("-"));

            // Get adjacent biomes
            var biomes:Array = [cell.biome];
            for each (var neighbor:Cell in cell.neighbors)
                if (biomes.indexOf(neighbor.biome) < 0)
                    biomes.push(biomes);
        }
    }
}
