package generation {
    import flash.geom.Point;

    import graph.Cell;

    import mx.collections.ArrayList;

    public class Region {
        // Only for generation
        public var used:Boolean;
        public var color:uint;

        // Singleton
        private var civ:Civilization;

        // Naming
        public var nameObject:Object;
        public var name:String;
        public var nameBinding:Boolean;
        public var nameBoundChild:Region;
        public var nameBoundParent:Region;
        public var nameBoundChildCompassDirection:String;
        public var nameBoundParentCompassDirection:String;

        // Region properties
        public var id:String;
        public var cells:Vector.<Cell>;
        public var analysis:Object;
        public var centroid:Point;
        public var land:Object;
        public var city:City;
        public var towns:Array;
        public var borderPoints:Array;
        public var simpleBorderPoints:Array;

        public function Region(id:String, cells:Vector.<Cell>) {
            civ = Civilization.getInstance();

            this.cells = cells;
            this.id = id;
        }

        public function analyze():void {
            // Creates an analysis object containing descriptive flags about the region
            // The analysis object is used for naming regions
            analysis = {generic: true, region: true};

            // Get the land that this region's city is on
            var lands:Object = city.cell.getFeaturesByType(Geography.LAND);
            for each (var land:Object in lands)
                break;

            // Is it a tiny island?
            if (land.cells.length < 3)
                analysis.island = true;

            // Is it a large region?
            if (cells.length > 120)
                analysis.large = true;

            // Do a loop of all the cells and add up different feature counts
            // River, lake, high, low, hot, and cold
            var riverCount:int = 0;
            var lakeCount:int = 0;
            var averageElevation:Number = 0;
            var averageTemperature:Number = 0;
            for each (var cell:Cell in cells) {
                if (cell.hasFeatureType(Geography.RIVER))
                    riverCount++;

                if (cell.hasFeatureType(Geography.LAKE))
                    lakeCount++;

                averageElevation += cell.elevation;
                averageTemperature += cell.temperature;
            }

            // Does it contain a lot of rivers?
            if (riverCount > 4 || riverCount / cells.length > .2)
                analysis.river = true;

            // Does it contain a lot of lakes?
            if (lakeCount > 4 || lakeCount / cells.length > .2)
                analysis.lake = true;

            // Elevation
            averageElevation = averageElevation / cells.length;
            averageTemperature = averageTemperature / cells.length;

            // Low
            if (averageElevation < .4)
                analysis.low = true;

            // High
            else if (averageElevation > .6)
                analysis.high = true;

            // Cold
            if (averageTemperature < .3)
                analysis.cold = true;

            // Hot
            else if (averageTemperature > .5)
                analysis.hot = true;

            // If it's an island, don't bother with biomes (islands shouldn't be named after their biomes)
            if (analysis.island)
                return;

            // Array of biomes and their percent of cells
            var regionalBiomesObject:Object = {};
            for each (cell in cells) {
                if (regionalBiomesObject[cell.biomeType]) {
                    regionalBiomesObject[cell.biomeType].count++;
                } else if (cell.biomeType) {
                    regionalBiomesObject[cell.biomeType] = {
                        type: cell.biomeType,
                        count: 1
                    };

                    var biomes:Array = [];
                    for each (var biome:Object in cell.getFeaturesByType(cell.biomeType))
                        biomes.push(biome);

                    if (biomes.length > 1)
                        biomes = biomes.sortOn("influence");

                    regionalBiomesObject[cell.biomeType].biome = biome;
                }
            }

            var regionalBiomes:Array = [];
            for each (var regionalBiome:Object in regionalBiomesObject) {
                if (regionalBiome.count > 0) {
                    regionalBiomes.push(regionalBiome);
                    regionalBiome.percent = regionalBiome.count / cells.length;
                }
            }

            regionalBiomes.sortOn("count");

            // Add most common biome
            var biomeType:String = regionalBiomes[0].type;
            analysis[biomeType] = regionalBiomes[0].biome;
        }

        public function analyzeContext():void {
            // This function determines if the region will be "name-bound" to another region to create North Foo and South Foo variations
            // The analyze() function must be run first on all regions for this function to work

            // Get references to neighboring regions
            var coastalRegion:Boolean = false;
            var neighborRegions:Object = {};
            for each (var cell:Cell in cells) {
                for each(var neighbor:Cell in cell.neighbors) {
                    if (neighbor.region != cell.region) {
                        // Cell is a border cell
                        // Only add neighbor's region if it's not null (ocean)
                        if (neighbor.region)
                            neighborRegions[neighbor.region] = {region: civ.regions[neighbor.region]};
                        else
                            coastalRegion = true;
                    }
                }
            }

            if (coastalRegion && land.cells.length > 1000) {
                // Find a compass direction between the region and the centroid of the land it's on, but only if it's on a big land
                var angleToLandCentroid:Number = Util.getAngleBetweenTwoPoints(centroid, land.centroid);
                var compassDirectionToLandCentroid:String = Util.getCompassDirectionFromDegrees(angleToLandCentroid + 90);
                analysis[compassDirectionToLandCentroid] = true;
            }

            var keys:Array = [];
            for (var key:String in analysis)
                keys.push(key);

            for each (var neighborRegion:Object in neighborRegions) {
                var neighborKeys:Array = [];
                for (key in neighborRegion.region.analysis)
                    neighborKeys.push(key);

                // Compare the two regions' analysis key sets
                var shared:Array = Util.sharedPropertiesBetweenArrays(keys, neighborKeys);
                neighborRegion.compare = shared.length / keys.length;

                // Add the degrees between the two regions
                neighborRegion.degrees = Util.getAngleBetweenTwoPoints(neighborRegion.region.centroid, centroid);

                // Compass direction from angle
                neighborRegion.compassDirection = Util.getCompassDirectionFromDegrees(neighborRegion.degrees + 90);
            }

            var neighborRegionsArray:Array = [];
            for each (neighborRegion in neighborRegions)
                neighborRegionsArray.push(neighborRegion);
            neighborRegionsArray.sort(Sort.sortByCompareValueAndSettlementCellIndex);

            analysis.neighborRegions = neighborRegionsArray;

            var rand:Rand = new Rand(city.cell.index);
            if (neighborRegionsArray.length > 0) {
                neighborRegion = neighborRegionsArray[0];
                if (neighborRegionsArray[0].compare == 1 && !nameBinding && !neighborRegion.region.nameBinding) {
                    if (rand.next() < .08) {
                        // 80% chance to name-bind the regions
                        nameBinding = true;
                        neighborRegion.region.nameBinding = true;
                        nameBoundChild = neighborRegion.region;
                        neighborRegion.region.nameBoundParent = this;
                        nameBoundChildCompassDirection = Util.oppositeCompassDirection(neighborRegion.compassDirection);
                        neighborRegion.region.nameBoundParentCompassDirection = neighborRegion.compassDirection;
                    }
                }
            }
        }
    }
}
