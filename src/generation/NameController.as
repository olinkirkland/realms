package generation {

    public class NameController {
        private static var _instance:NameController;
        private var geo:Geography;
        private var civ:Civilization;
        private var rand:Rand;

        [Embed(source="../assets/language/english/biomes.json", mimeType="application/octet-stream")]
        private static const biomes_json:Class;

        [Embed(source="../assets/language/english/regions/prefixes.json", mimeType="application/octet-stream")]
        private static const regions_prefixesByContext_json:Class;

        [Embed(source="../assets/language/english/regions/suffixes.json", mimeType="application/octet-stream")]
        private static const regions_suffixesByContext_json:Class;

        [Embed(source="../assets/language/english/regions/suffixesByNamingGroup.json", mimeType="application/octet-stream")]
        private static const regions_suffixesByNamingGroup_json:Class;

        [Embed(source="../assets/language/english/cityNameParts.json", mimeType="application/octet-stream")]
        private static const citiesAndTowns_namePartsByContext_json:Class;

        // Directions
        [Embed(source="../assets/language/english/compassDirections.json", mimeType="application/octet-stream")]
        private static const compassDirections_json:Class;

        public var compassDirections:Object;

        public var regionsNamingDictionary:Object;
        public var citiesAndTownsNamingDictionary:Object;

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
            rand = new Rand(1);

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
            regionsNamingDictionary = {
                prefixes: JSON.parse(new regions_prefixesByContext_json()),
                suffixesByContext: JSON.parse(new regions_suffixesByContext_json()),
                suffixesByNamingGroup: JSON.parse(new regions_suffixesByNamingGroup_json())
            };

            var namePartsByContext:Object = JSON.parse(new citiesAndTowns_namePartsByContext_json());
            citiesAndTownsNamingDictionary = {
                prefixes: namePartsByContext.prefixes,
                suffixes: namePartsByContext.suffixes,
                descriptions: namePartsByContext.descriptions,
                standalone: namePartsByContext.standalone
            };

            compassDirections = JSON.parse(new compassDirections_json());
        }

        public function nameRegions(regions:Object):void {
            // Turn the regions object into an array so it can be sorted
            var regionsArray:Array = [];
            for each (var region:Region in regions)
                regionsArray.push(region);
            regionsArray.sort(Sort.sortByCellCountAndSettlementCellIndex);

            for each (region in regionsArray)
                region.analyze();

            for each (region in regionsArray)
                region.analyzeContext();

            for each (region in regionsArray)
                region.nameObject = generateRegionPrefixAndSuffix(region, new Rand(int(rand.next() * 9999)));

            for each (region in regionsArray) {
                if (region.nameBoundChild && rand.next() < .7)
                    region.nameObject.nameBoundQualifier = compassDirections[region.nameBoundChildCompassDirection];

                if (region.nameBoundParent) {
                    region.nameObject.nameBoundQualifier = compassDirections[region.nameBoundParentCompassDirection];
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

        public function generateRegionPrefixAndSuffix(region:Object, rand:Rand):Object {
            return generatePrefixAndSuffix(region.analysis, rand, regionsNamingDictionary);
        }

        public function generatePrefixAndSuffix(analysis:Object, rand:Rand, namingDictionary:Object):Object {
            var prefixesByContext:Object = namingDictionary.prefixes;
            var suffixesByContext:Object = namingDictionary.suffixesByContext;
            var suffixesByNamingGroup:Array = namingDictionary.suffixesByNamingGroup;

            var prefix:String;
            var suffix:String;

            // Analysis keys
            var analysisKeys:Array = [];
            for (var key:String in analysis)
                analysisKeys.push(key);

            // Prefix keys
            var prefixKeys:Array = [];
            for (key in prefixesByContext)
                prefixKeys.push(key);

            // Suffix keys
            var suffixKeys:Array = [];
            for (key in suffixesByContext)
                suffixKeys.push(key);

            // Possible keys
            var possiblePrefixKeys:Array = Util.sharedPropertiesBetweenArrays(analysisKeys, prefixKeys);
            var possibleSuffixKeys:Array = Util.sharedPropertiesBetweenArrays(analysisKeys, suffixKeys);

            // Possible prefixes
            var possiblePrefixes:Array = [];
            for each (var possiblePrefixKey:String in possiblePrefixKeys) {
                if (prefixesByContext[possiblePrefixKey] && prefixesByContext[possiblePrefixKey].length > 0) {
                    var possiblePrefixVariations:Array = prefixesByContext[possiblePrefixKey];
                    for each (var possiblePrefix:Object in possiblePrefixVariations) {
                        possiblePrefixes.push(possiblePrefix);
                        possiblePrefix.context = possiblePrefixKey;
                    }
                }
            }

            // Possible suffixes
            var possibleSuffixes:Array = [];
            for each (var possibleSuffixKey:String in possibleSuffixKeys)
                possibleSuffixes = possibleSuffixes.concat(suffixesByContext[possibleSuffixKey]);

            // Possible combinations
            var possibleCombinations:Array = [];
            for each (possiblePrefix in possiblePrefixes) {
                for each (var namingGroupIndex:int in possiblePrefix.suffixNamingGroups) {
                    var possibleSuffixesForPrefix:Array = Util.sharedPropertiesBetweenArrays(possibleSuffixes, suffixesByNamingGroup[namingGroupIndex]);
                    if (possibleSuffixesForPrefix.length > 0) {
                        var vettedSuffixesForPrefix:Array = [];

                        for each (var unvettedSuffix:String in possibleSuffixesForPrefix) {
                            if (isValidPlaceName(possiblePrefix.name, unvettedSuffix))
                                vettedSuffixesForPrefix.push(unvettedSuffix);
                        }

                        for each (var vettedSuffix:String in vettedSuffixesForPrefix) {
                            if (possiblePrefix.name == "[trees]" || possiblePrefix.name == "[plants]" || possiblePrefix.name == "[smallAnimals]") {
                                var biome:Object = analysis[possiblePrefix.context];
                                // Remove the brackets
                                var category:String = possiblePrefix.name.substr(1, possiblePrefix.name.length - 2);
                                for each (var detail:String in biome.ecosystem[category]) {
                                    possibleCombinations.push({
                                        prefix: Util.capitalizeFirstLetter(detail),
                                        suffix: vettedSuffix
                                    });
                                }
                            } else {
                                // Remove the last letter of the prefix if the prefix's last letter is the same as the first letter of the suffix
                                var workablePrefix:String = possiblePrefix.name;
                                if (workablePrefix.charAt(workablePrefix.length - 1) == vettedSuffix.charAt(0))
                                    workablePrefix = workablePrefix.substr(0, workablePrefix.length - 1);

                                possibleCombinations.push({prefix: workablePrefix, suffix: vettedSuffix});
                            }
                        }
                    }
                }
            }

            // Choose from possible combinations
            possibleCombinations = Util.removeDuplicatesFromArray(possibleCombinations);

            var str:String = "Analysis: " + analysisKeys.join(",") + "\nCombinations: ";
            for each (var p:Object in possibleCombinations)
                str += p.prefix + p.suffix + ",";

            trace("================");
            trace(str);

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
            trace("Choice: " + choice.prefix + choice.suffix);

            prefix = choice.prefix;
            suffix = choice.suffix;

            if (choice)
                existingNames.push(choice.prefix + choice.suffix);

            return {prefix: prefix, suffix: suffix};
        }


        public function nameCities(cities:Object):void {
            for each (var city:City in cities) {
                city.name = civ.regions[city.cell.region].name;
            }
        }


        public function nameTowns(towns:Object):void {
            // Just use the nameCities function since towns extend cities
            nameCities(towns);
        }

        private function isValidPlaceName(prefix:String,
                                          suffix:String):Boolean {
            var vowels:String = "aeiouyw";
            if ((isVowel(prefix.charAt(prefix.length - 1)) && isVowel(suffix.charAt(0)))) {
                return false;
            }

            if (hasThreeConsecutiveCharacters(prefix + suffix)) {
                return false;
            }

            if (prefix.charAt(prefix.length - 1) == "t" && suffix.charAt(0) == "h") {
                return false;
            }

            return true;

            function hasThreeConsecutiveCharacters(s:String):Boolean {
                return s.match(/([a-z])\1\1+/g).length > 0;
            }


            function isVowel(c:String):Boolean {
                return vowels.indexOf(c) >= 0;
            }
        }

        public function reset():void {
            existingNames = [];
        }
    }
}
