package generation {

    public class NameController {
        private static var _instance:NameController;
        private var geo:Geography;
        private var civ:Civilization;
        private var rand:Rand;

        [Embed(source="../assets/language/english/biomes.json", mimeType="application/octet-stream")]
        private static const biomes_json:Class;

        [Embed(source="../assets/language/german/places.json", mimeType="application/octet-stream")]
        private static const places_json:Class;

        public var places:Object;

        private var existingNames:Array = [];

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

        public static function getInstance():NameController {
            if (!_instance)
                new NameController();
            return _instance;
        }

        public function NameController() {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;

            geo = Geography.getInstance();
            civ = Civilization.getInstance();

            // Biomes
            var biomes:Object = JSON.parse(new biomes_json());
            tundra = biomes.tundra;
            borealForest = biomes.borealForest;
            grassland = biomes.grassland;
            temperateForest = biomes.temperateForest;
            savanna = biomes.savanna;
            rainForest = biomes.rainForest;
            mountain = biomes.mountain;
            desert = biomes.desert;
            freshWater = biomes.freshWater;
            saltWater = biomes.saltWater;

            // Places
            places = JSON.parse(new places_json());
        }

        public function nameRegions(regions:Object):void {
            rand = new Rand(1);

            // Turn the regions object into an array so it can be sorted
            var regionsArray:Array = [];
            for each (var region:Region in regions)
                regionsArray.push(region);
            regionsArray.sort(Sort.sortByCellCountAndCityCellIndex);

            for each (region in regionsArray)
                region.analyze();

            for each (region in regionsArray)
                region.analyzeContext();

            for each (region in regionsArray)
                region.nameObject = generatePrefixAndSuffix(region.analysis, new Rand(int(rand.next() * 9999)));

            for each (region in regionsArray) {
                // If it has a child, 70% chance it will receive a nameBoundQualifier, causing a pair like North Dakota/South Dakota
                // Alternatively, 30% chance it will not receive a nameBoundQualifier, causing a pair like Virginia/West Virginia
                if (region.nameBoundChild && rand.next() < .7)
                    region.nameObject.nameBoundQualifier = namingDictionary.associations[region.nameBoundChildCompassDirection];

                // If it has a parent, name it the same as its parent
                if (region.nameBoundParent) {
                    region.nameObject.nameBoundQualifier = namingDictionary.associations[region.nameBoundParentCompassDirection];
                    region.nameObject.prefix = region.nameBoundParent.nameObject.prefix;
                    region.nameObject.suffix = region.nameBoundParent.nameObject.suffix;
                }
            }

            for each (region in regionsArray) {
                var n:Object = region.nameObject;
                region.name = n.prefix + n.suffix;
                if (n.hasOwnProperty("nameBoundQualifier"))
                    region.name = n.nameBoundQualifier + " " + region.name;
            }
        }

        public function generatePrefixAndSuffix(analysis:Object, rand:Rand):Object {
            var prefixes:Object = namingDictionary.prefixes;
            var suffixes:Object = namingDictionary.suffixes;

            var prefix:String;
            var suffix:String;

            // Analysis keys
            var analysisKeys:Array = [];
            for (var key:String in analysis)
                analysisKeys.push(key);
            analysisKeys.sort();

            // Prefix keys
            var prefixKeys:Array = [];
            for (key in prefixes)
                prefixKeys.push(key);
            prefixKeys.sort();

            // Suffix keys
            var suffixKeys:Array = [];
            for (key in suffixes)
                suffixKeys.push(key);
            suffixKeys.sort();

            // Possible keys
            var possiblePrefixKeys:Array = Util.sharedPropertiesBetweenArrays(analysisKeys, prefixKeys);
            var possibleSuffixKeys:Array = Util.sharedPropertiesBetweenArrays(analysisKeys, suffixKeys);

            var possibleCombinations:Array = [];

            for each (var possiblePrefixKey:String in possiblePrefixKeys) {
                var px:Array = prefixes[possiblePrefixKey];
                if (px) {
                    for each (var possiblePrefix:String in px) {
                        for each (var possibleSuffixKey:String in possibleSuffixKeys) {
                            var sx:Array = suffixes[possibleSuffixKey];
                            if (sx) {
                                for each (var possibleSuffix:String in sx) {
                                    possibleCombinations.push({
                                        prefix: possiblePrefix,
                                        suffix: possibleSuffix,
                                        name: possiblePrefix + possibleSuffix
                                    });
                                }
                            }
                        }
                    }
                }
            }

            //todo strip possible combinations that aren't "allowed combinations"

            // Choose from possible combinations
            possibleCombinations = Util.removeDuplicatesFromArray(possibleCombinations);
            possibleCombinations.sortOn("name");

            var choice:Object = {};
            do {
                if (possibleCombinations.length > 0) {
                    choice = possibleCombinations.removeAt(rand.between(0, possibleCombinations.length - 1));
                } else {
                    var prePrefix:String = "New ";
                    choice.prefix = prePrefix + choice.prefix;
                    break;
                }
            } while (choice && existingNames.indexOf(choice.prefix + choice.suffix) > -1);

            prefix = choice.prefix;
            suffix = choice.suffix;

            if (choice)
                existingNames.push(choice.prefix + choice.suffix);

            return {prefix: prefix, suffix: suffix};
        }

        public function nameCities(cities:Object):void {
            // Turn the cities object into an array so it can be sorted
            var citiesArray:Array = [];
            for each (var city:City in cities)
                citiesArray.push(city);
            citiesArray.sort(Sort.sortByCellIndex);

            for each (city in citiesArray)
                city.analyze();

            for each (city in citiesArray)
                city.nameObject = generatePrefixAndSuffix(city.analysis, new Rand(int(rand.next() * 9999)));

            for each (city in citiesArray) {
                var n:Object = city.nameObject;
                city.name = n.prefix + n.suffix;
            }
        }


        public function nameTowns(towns:Object):void {
            // Just use the nameCities function since towns extend cities
            nameCities(towns);
        }

        public function reset():void {
            existingNames = [];
        }
    }
}
