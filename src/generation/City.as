package generation {
    import flash.geom.Point;

    import graph.Cell;

    public class City {
        // Only for generation
        public var used:Boolean;

        // Singleton
        private var civ:Civilization;

        // City Properties
        public var cell:Cell;
        public var id:String;
        public var influence:int;
        public var point:Point;
        public var neighbors:Array;
        public var analysis:Object;

        // Naming
        public var nameObject:Object;
        public var name:String;

        public function City(cell:Cell, id:String) {
            civ = Civilization.getInstance();

            this.cell = cell;
            this.id = id;

            this.point = new Point(cell.point.x, cell.point.y);

            influence = cell.desirability;

            neighbors = [];

            determineName();
        }

        public function analyze():void {
            // Creates an analysis object containing descriptive flags about the city
            // The analysis object is used for naming cities and towns
            analysis = {all: true, townOrCity: true};
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
