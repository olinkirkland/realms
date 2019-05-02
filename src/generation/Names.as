package generation {
    import graph.*;

    public class Names {
        private static var _instance:Names;
        private var geo:Geography;
        private var civ:Civilization;

        [Embed(source="../assets/language/english/biomes.json", mimeType="application/octet-stream")]
        private static const biomes_json:Class;

        [Embed(source="../assets/language/english/regions/prefixesByContext.json", mimeType="application/octet-stream")]
        private static const regions_prefixesByContext_json:Class;

        [Embed(source="../assets/language/english/regions/suffixesByContext.json", mimeType="application/octet-stream")]
        private static const regions_suffixesByContext_json:Class;

        [Embed(source="../assets/language/english/regions/suffixesByNamingGroup.json", mimeType="application/octet-stream")]
        private static const regions_suffixesByNamingGroup_json:Class;

        [Embed(source="../assets/language/english/namePartsByContext.json", mimeType="application/octet-stream")]
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

        public static function getInstance():Names {
            if (!_instance)
                new Names();
            return _instance;
        }

        public function Names() {
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

        public function analyzeLand(cells:Vector.<Cell>):Object {
            var analysis:Object = {};

            // Size
            analysis.size = cells.length;

            if (cells.length < 3) {
                // Tiny island
                analysis.tinyIsland = true;
            } else if (cells.length < 100) {
                // Small island
                analysis.smallIsland = true;
            } else if (cells.length < 400) {
                // Large island
                analysis.largeIsland = true;
            } else {
                // Continent
                analysis.continent = true;
            }

            return analysis;
        }

        public function analyzeRegionProperties(cells:Vector.<Cell>):Object {
            var analysis:Object = {};

            // Analyze land (regions cannot span more than one land so don't worry about it)
            var lands:Object = cells[0].getFeaturesByType(Geography.LAND);
            for each (var land:Object in lands)
                break;
            if (land.cells.length < 3) {
                // Tiny island
                analysis.island = true;
            } else {
                // Continent
                analysis.land = true;
            }

            if (cells.length > 120)
                analysis.large = true;

            // Percent of river cells
            // Percent of lake cells
            // Percent of coastal cells
            // Average elevation
            var riverCount:int = 0;
            var lakeCount:int = 0;
            var coastalCount:int = 0;
            var averageElevation:Number = 0;
            var averageTemperature:Number = 0;
            for each (var cell:Cell in cells) {
                if (cell.hasFeatureType(Geography.RIVER))
                    riverCount++;

                if (cell.hasFeatureType(Geography.LAKE))
                    lakeCount++;

                if (cell.coastal)
                    coastalCount++;

                averageElevation += cell.elevation;
                averageTemperature += cell.temperature;
            }

            if (riverCount > 4 || riverCount / cells.length > .2)
                analysis.highRiverRating = true;

            if (lakeCount > 4 || lakeCount / cells.length > .2)
                analysis.highLakeRating = true;

            if (coastalCount / cells.length > .3)
                analysis.highCoastalRating = true;

            averageElevation = averageElevation / cells.length;
            averageTemperature = averageTemperature / cells.length;

            if (averageElevation < .4)
                analysis.lowElevation = true;
            else if (averageElevation > .6)
                analysis.highElevation = true;

            if (averageTemperature < .3)
                analysis.lowTemperature = true;
            else if (averageTemperature > .5)
                analysis.highTemperature = true;

            // If it's an island, don't bother with biomes
            if (analysis.island)
                return analysis;

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
            if (regionalBiomes[0].percent > .4)
                analysis[regionalBiomes[0].type] = regionalBiomes[0].biome;

            return analysis;
        }

        private function analyzeRegionContext(region:Object):Object {
            var analysis:Object = region.analysis;

            // Get references to neighboring regions
            var coastalRegion:Boolean = false;
            var neighborRegions:Object = {};
            for each (var cell:Cell in region.cells) {
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

            if (coastalRegion && region.land.cells.length > 1000) {
                // Find a compass direction between the region and the centroid of the land it's on, but only if it's on a big land
                var angleToLandCentroid:Number = Util.getAngleBetweenTwoPoints(region.centroid, region.land.centroid);
                var compassDirectionToLandCentroid:String = Util.getCompassDirectionFromDegrees(angleToLandCentroid + 90);
                region.analysis[compassDirectionToLandCentroid] = true;
            }

            var keys:Array = [];
            for (var key:String in analysis)
                keys.push(key);

            for each (var neighborRegion:Object in neighborRegions) {
                var neighborKeys:Array = [];
                for (key in neighborRegion.region.analysis)
                    neighborKeys.push(key);
                // Compare the two key sets
                var shared:Array = Util.sharedPropertiesBetweenArrays(keys, neighborKeys);
                neighborRegion.compare = shared.length / keys.length;

                // Add the degrees between the two regions
                neighborRegion.degrees = Util.getAngleBetweenTwoPoints(neighborRegion.region.centroid, region.centroid);

                // Compass direction from angle
                neighborRegion.compassDirection = Util.getCompassDirectionFromDegrees(neighborRegion.degrees + 90);
            }

            var neighborRegionsArray:Array = [];
            for each (neighborRegion in neighborRegions)
                neighborRegionsArray.push(neighborRegion);
            neighborRegionsArray.sort(Sort.sortByCompareValueAndSettlementCellIndex);

            analysis.neighborRegions = neighborRegionsArray;

            var rand:Rand = new Rand(region.city.cell.index);
            if (neighborRegionsArray.length > 0) {
                neighborRegion = neighborRegionsArray[0];
                if (neighborRegionsArray[0].compare == 1 && !region.nameBinding && !neighborRegion.region.nameBinding) {
                    if (rand.next() < .08) {
                        // Name-bind the regions
                        region.nameBinding = true;
                        neighborRegion.region.nameBinding = true;
                        region.nameBoundChild = neighborRegion.region;
                        neighborRegion.region.nameBoundParent = region;
                        region.nameBoundChildCompassDirection = Util.oppositeCompassDirection(neighborRegion.compassDirection);
                        neighborRegion.region.nameBoundParentCompassDirection = neighborRegion.compassDirection;
                    }
                }
            }

            return analysis;
        }

        public function nameRegions(regions:Object):void {
            var rand:Rand = new Rand(1);
            var regionsArray:Array = [];
            for each (var region:Object in regions)
                regionsArray.push(region);
            regionsArray.sort(Sort.sortByCellCountAndSettlementCellIndex);

            for each (region in regionsArray)
                region.analysis = analyzeRegionProperties(region.cells);

            for each (region in regionsArray)
                region.analysis = analyzeRegionContext(region);

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
