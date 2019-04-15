package generation {
    import graph.Cell;

    public class Names {
        private static var _instance:Names;
        private var featureManager:Geography;

        /**
         * Biomes
         */

        [Embed(source="../assets/names/tundra.json", mimeType="application/octet-stream")]
        private static const tundra_json:Class;

        [Embed(source="../assets/names/borealForest.json", mimeType="application/octet-stream")]
        private static const borealForest_json:Class;

        [Embed(source="../assets/names/grassland.json", mimeType="application/octet-stream")]
        private static const grassland_json:Class;

        [Embed(source="../assets/names/temperateForest.json", mimeType="application/octet-stream")]
        private static const temperateForest_json:Class;

        [Embed(source="../assets/names/savanna.json", mimeType="application/octet-stream")]
        private static const savanna_json:Class;

        [Embed(source="../assets/names/rainForest.json", mimeType="application/octet-stream")]
        private static const rainForest_json:Class;

        [Embed(source="../assets/names/mountain.json", mimeType="application/octet-stream")]
        private static const mountain_json:Class;

        [Embed(source="../assets/names/desert.json", mimeType="application/octet-stream")]
        private static const desert_json:Class;

        [Embed(source="../assets/names/saltWater.json", mimeType="application/octet-stream")]
        private static const saltWater_json:Class;

        [Embed(source="../assets/names/freshWater.json", mimeType="application/octet-stream")]
        private static const freshWater_json:Class;

        public var tundra:Object;
        public var borealForest:Object;
        public var grassland:Object;
        public var temperateForest:Object;
        public var savanna:Object;
        public var rainForest:Object;
        public var mountain:Object;
        public var desert:Object;
        public var freshWater:Object;
        public var saltWater:Object;

        /**
         * Features
         */

        [Embed(source="../assets/names/regions.json", mimeType="application/octet-stream")]
        private static const regions_json:Class;

        public var regionDictionary:Object;

        public static function getInstance():Names {
            if (!_instance)
                new Names();
            return _instance;
        }

        public function Names() {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;

            featureManager = Geography.getInstance();

            // Biomes
            tundra = JSON.parse(new tundra_json());
            borealForest = JSON.parse(new borealForest_json());
            grassland = JSON.parse(new grassland_json());
            temperateForest = JSON.parse(new temperateForest_json());
            savanna = JSON.parse(new savanna_json());
            rainForest = JSON.parse(new rainForest_json());
            mountain = JSON.parse(new mountain_json());
            desert = JSON.parse(new desert_json());
            freshWater = JSON.parse(new freshWater_json());
            saltWater = JSON.parse(new saltWater_json());

            // Features
            regionDictionary = JSON.parse(new regions_json());
        }

        public function analyzeArea(cells:Vector.<Cell>):Object {
            // Bounds
            var analysis:Object = {};

            // Size
            analysis.size = cells.length;

            // Array of biomes and their percent of cells
            var regionalBiomesObject:Object = {};
            for each (var cell:Cell in cells) {
                if (regionalBiomesObject[cell.biomeType])
                    regionalBiomesObject[cell.biomeType].count++;
                else if (cell.biomeType)
                    regionalBiomesObject[cell.biomeType] = {type: cell.biomeType, count: 1};
            }
            var regionalBiomes:Array = [];
            for each (var regionalBiome:Object in regionalBiomesObject) {
                if (regionalBiome.count > 0) {
                    regionalBiomes.push(regionalBiome);
                    regionalBiome.percent = int((regionalBiome.count / cells.length) * 100);
                }
            }
            regionalBiomes.sortOn("count");
            if (regionalBiomes[0].percent > 60) {
                analysis.primaryBiomeType = regionalBiomes[0].type;
                if (regionalBiomes[1] && regionalBiomes[1].percent > 20)
                    analysis.secondaryBiomeType = regionalBiomes[1].type;
            }

            // Percent of river cells in region
            // Percent of coastal cells
            // Average elevation
            var riverCount:int = 0;
            var coastalCount:int = 0;
            var averageElevation:Number = 0;
            var averageTemperature:Number = 0;
            for each (cell in cells) {
                if (cell.hasFeatureType(Geography.RIVER))
                    riverCount++;

                if (cell.coastal)
                    coastalCount++;

                averageElevation += cell.elevation;
                averageTemperature += cell.temperature;
            }

            var riverRating:Number = int((riverCount / cells.length) * 100);
            if (riverRating > 10)
                analysis.highRiverRating = true;

            var coastalRating:Number = int((coastalCount / cells.length) * 100);
            if (coastalRating > 40)
                analysis.highCoastalRating = true;

            averageElevation = averageElevation / cells.length;
            averageTemperature = averageTemperature / cells.length;

            if (averageElevation < .3)
                analysis.lowElevation = true;
            else if (averageElevation > .7)
                analysis.highElevation = true;

            if (averageTemperature < .3)
                analysis.lowTemperature = true;
            else if (averageTemperature > .7)
                analysis.highTemperature = true;

            // Analyze land (regions cannot span more than one land)
            var lands:Object = cells[0].getFeaturesByType(Geography.LAND);
            for each (var land:Object in lands)
                break;
            if (land.cells.length < 3) {
                // Tiny island
                analysis.tinyIsland = true;
            } else if (land.cells.length < 100) {
                // Small island
                analysis.smallIsland = true;
            } else if (land.cells.length < 400) {
                // Large island
                analysis.largeIsland = true;
            } else {
                // Continent
                analysis.continent = true;
            }

            return analysis;
        }

        public function nameRegions(regions:Object):void {
            var rand:Rand = new Rand(1);
            var regionsArray:Array = [];
            for each (var region:Object in regions)
                regionsArray.push(region);
            regionsArray.sort(Sort.sortBySettlementCellIndex);

            for each (region in regionsArray) {
                region.analysis = analyzeArea(region.cells);
                region.name = generatePlaceName(region.analysis, rand, regionDictionary).name;
            }
        }

        public function nameLands(lands:Object):void {
            var rand:Rand = new Rand(1);
            for each (var land:Object in lands) {
                land.analysis = analyzeArea(land.cells);
                // Name land
                land.name = land.analysis["tinyIsland"] || land.analysis["smallIsland"] ? "Island" : "Land";
            }
        }

        public function generatePlaceName(analysis:Object, rand:Rand, dictionary:Object):Object {
            var prefix:String;
            var suffix:String;

            return {prefix: prefix, suffix: suffix, name: prefix + suffix}
        }
    }
}
