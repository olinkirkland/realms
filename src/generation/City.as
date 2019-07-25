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
            // Creates an analysis object containing true/false properties about the city
            // The analysis object is used for naming cities and towns
            // todo temporarily set building to true
            analysis = {city: true, generic: true, building: true};

            // Region
            var region:Region = civ.regions[cell.region];

            // Get the land that this city is on
            var lands:Object = cell.getFeaturesByType(Geography.LAND);
            for each (var land:Object in lands)
                break;

            // Is it on a tiny island?
            if (land.cells.length < 3)
                analysis.island = true;

            // Low
            if (cell.elevation < .4)
                analysis.low = true;

            // High
            else if (cell.elevation > .6)
                analysis.high = true;

            // Cold
            if (cell.temperature < .3)
                analysis.cold = true;

            // Hot
            else if (cell.temperature > .5)
                analysis.warm = true;

            // Is the city on the coast?
            for each(var neighbor:Cell in cell.neighbors) {
                if (!neighbor.region) {
                    analysis.coast = true;
                    break;
                }
            }

            // River
            var rivers:Object = cell.getFeaturesByType(Geography.RIVER);
            for each (var river:Object in rivers)
                break;
            if (river) {
                analysis.river = river;
                // Is it on a tributary?
                if (river.tributary)
                    analysis.tributary = true;
            }

            // Estuary
            if (cell.hasFeatureType(Geography.ESTUARY))
                analysis.estuary = true;

            // Determine this cell's biome type
            analysis[cell.biomeType] = cell.biome;
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
