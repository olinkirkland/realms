package generation {
    import generation.Enumerators.LandType;

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

        [Embed(source="../assets/names/rivers.json", mimeType="application/octet-stream")]
        private static const rivers_json:Class;

        [Embed(source="../assets/names/regions.json", mimeType="application/octet-stream")]
        private static const regions_json:Class;

        public var riverNameDictionary:Object;
        public var regionNameDictionary:Object;

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
            riverNameDictionary = JSON.parse(new rivers_json());
            regionNameDictionary = JSON.parse(new regions_json());
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
            analysis.regionalBiomes = regionalBiomes;

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

            analysis.riverRating = int((riverCount / cells.length) * 100);
            analysis.coastalRating = int((coastalCount / cells.length) * 100);
            analysis.averageElevation = averageElevation / cells.length;
            analysis.averageTemperature = averageTemperature / cells.length;

            var lands:Object = cells[0].getFeaturesByType(Geography.LAND);
            for each (var land:Object in lands)
                break;

            analysis.landType = LandType.continent;
            if (analysis.coastalRating == 100 && land.cells.length < 3) {
                // Tiny island
                analysis.landType = LandType.tinyIsland;
            } else if (land.cells.length < 100) {
                // Small island
                analysis.landType = LandType.smallIsland;
            } else if (land.cells.length < 400) {
                // Large island
                analysis.landType = LandType.largeIsland;
            }

            return analysis;
        }

        public function nameRegions(regions:Object):void {
            var rand:Rand = new Rand(1);
            var regionsArray:Array = [];
            for each (var region:Object in regions)
                regionsArray.push(region);
            regionsArray.sortOn("centroid.x");

            for each (region in regionsArray) {
                region.analysis = analyzeArea(region.cells);
                region.name = nameArea(region.analysis, rand, regionNameDictionary);
            }
        }

        public function nameLands(lands:Object):void {
            var rand:Rand = new Rand(1);
            for each (var land:Object in lands) {
                land.analysis = analyzeArea(land.cells);
                land.name = nameArea(land.analysis, rand, regionNameDictionary);
            }
        }

        public function nameArea(analysis:Object, rand:Rand, dictionary:Object):String {
            var prefixes:Object = dictionary.subjectPrefix;
            var prefixKeys:Array = Util.keysFromObject(dictionary.subjectPrefix);
            var suffixes:Object = dictionary.subjectSuffix;

            var prefixKey:String = Util.randomElementFromArray(prefixKeys, rand) as String;

            var possiblePrefixes:Array = prefixes[prefixKey];
            var prefixObject:Object = Util.randomElementFromArray(possiblePrefixes, rand);
            var prefix:String = Util.randomElementFromArray(prefixObject.names, rand) as String;

            var suffixKey:String = Util.randomElementFromArray(prefixObject.uses, rand) as String;

            var possibleSuffixes:Array = suffixes[suffixKey];
            var suffix:String = possibleSuffixes ? Util.randomElementFromArray(possibleSuffixes, rand) as String : "";

            return prefix + suffix;
        }
    }
}
