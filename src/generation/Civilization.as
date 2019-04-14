package generation {
    import flash.geom.Point;

    import graph.Cell;

    import mx.utils.UIDUtil;

    public class Civilization {
        private static var _instance:Civilization;

        // Generation
        public var settlementsById:Object = {};
        public var settlementsByCell:Object = {};
        public var regions:Object = {};

        public function Civilization() {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;
        }

        public static function getInstance():Civilization {
            if (!_instance)
                new Civilization();
            return _instance;
        }

        public function get settlements():Object {
            return settlementsById;
        }

        public function reset():void {
            regions = {};
            settlementsById = {};
            settlementsByCell = {};
        }

        public function registerSettlement(cell:Cell):String {
            var id:String = UIDUtil.createUID();
            var settlement:Settlement = new Settlement(cell, id);
            cell.settlement = settlement;

            settlementsById[id] = settlement;
            settlementsByCell[cell] = settlement;

            return id;
        }

        public function registerRegion():String {
            var id:String = UIDUtil.createUID();

            regions[id] = {id: id, cells: new Vector.<Cell>()};

            return id;
        }

        public function addCellToRegion(cell:Cell, region:String, influence:int):void {
            if (cell.region) {
                var cells:Vector.<Cell> = regions[cell.region].cells;
                cells.removeAt(cells.indexOf(cell));
            }

            cell.region = regions[region].id;
            cell.regionInfluence = influence;
            regions[region].cells.push(cell);
        }

        public function analyzeRegions():void {
            for each (var region:Object in regions) {
                // Bounds
                // First, determine the center point of the biome
                var avgX:Number = 0;
                var avgY:Number = 0;

                for each (var cell:Cell in region.cells) {
                    avgX += cell.point.x;
                    avgY += cell.point.y;
                }

                region.centroid = new Point(avgX /= region.cells.length, avgY /= region.cells.length);

                var analysis:Object = {};
                // Region size
                analysis.size = region.cells.length < 50 ? "normal" : "large";

                // Array of biomes and their percent of cells
                var regionalBiomesObject:Object = {};
                for each (cell in region.cells) {
                    if (regionalBiomesObject[cell.biomeType])
                        regionalBiomesObject[cell.biomeType].count++;
                    else if (cell.biomeType)
                        regionalBiomesObject[cell.biomeType] = {type: cell.biomeType, count: 1};
                }
                var regionalBiomes:Array = [];
                for each (var regionalBiome:Object in regionalBiomesObject) {
                    if (regionalBiome.count > 0) {
                        regionalBiomes.push(regionalBiome);
                        regionalBiome.percent = int((regionalBiome.count / region.cells.length) * 100);
                    }
                }
                regionalBiomes.sortOn("count");
                analysis.regionalBiomes = regionalBiomes;

                // Percent of river cells in region
                // Percent of coastal cells
                // Average elevation
                var riverCount:int = 0;
                var coastalCount:int = 0;
                var averageElevation:Number = 0;
                for each (cell in region.cells) {
                    if (cell.hasFeatureType(Geography.RIVER))
                        riverCount++;

                    if (cell.coastal)
                        coastalCount++;

                    averageElevation += cell.elevation;
                }

                averageElevation /= region.cells.length;

                analysis.riverRating = int((riverCount / region.cells.length) * 100);
                analysis.coastalRating = int((coastalCount / region.cells.length) * 100);
                analysis.averageElevation = averageElevation;

                region.analysis = analysis;
            }
        }

        public function nameRegions():void {
            for each (var region:Object in regions) {
                region.name = "Hello world";
            }
        }
    }
}