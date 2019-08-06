package generation {

    public class NameController {
        private static var _instance:NameController;
        private var geo:Geography;
        private var civ:Civilization;
        private var rand:Rand;

        [Embed(source="../assets/language/biomes.json", mimeType="application/octet-stream")]
        private static const biomes_json:Class;

        [Embed(source="../assets/language/placeNameParts.json", mimeType="application/octet-stream")]
        private static const placeNameParts_json:Class;

        public var placeNameParts:Object;

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
            placeNameParts = JSON.parse(new placeNameParts_json());
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
                region.nameObject = generateName(region.analysis, new Rand(int(rand.next() * 9999)));

            for each (region in regionsArray) {
                // If it has a child, 70% chance it will receive a nameBoundQualifier, causing a pair like North Dakota/South Dakota
                // Alternatively, 30% chance it will not receive a nameBoundQualifier, causing a pair like Virginia/West Virginia
                if (region.nameBoundChild && rand.next() < .7)
                    region.nameObject.nameBoundQualifier = getPlaceNamePartsByTag(region.nameBoundChildCompassDirection)[0].name;

                // If it has a parent, name it the same as its parent
                if (region.nameBoundParent) {
                    region.nameObject.nameBoundQualifier = getPlaceNamePartsByTag(region.nameBoundParentCompassDirection)[0].name;
                    region.nameObject.prefix = region.nameBoundParent.nameObject.prefix;
                    region.nameObject.suffix = region.nameBoundParent.nameObject.suffix;
                }
            }

            for each (region in regionsArray) {
                var n:Object = region.nameObject;
                region.name = n.prefix + n.suffix;
                if (n.hasOwnProperty("nameBoundQualifier"))
                    region.name = n.nameBoundQualifier + region.name.toLowerCase();
            }
        }

        public function generateName(analysis:Object, rand:Rand):Object {
            // Analysis keys
            var analysisKeys:Array = [];
            for (var key:String in analysis)
                analysisKeys.push(key);
            analysisKeys.sort();


            var validPlaceNameParts:Array = [];
            for each (var analysisKey:String in analysisKeys)
                validPlaceNameParts = Util.removeDuplicatesFromArray(validPlaceNameParts.concat(getPlaceNamePartsByTag(analysisKey)));

            var prefix:String = "";
            var suffix:String = "";

            do {
                prefix = getProperty(validPlaceNameParts, "countPrefix",
                        rand.next());
                suffix = getProperty(validPlaceNameParts, "countSuffix",
                        rand.next());
            } while (!validateName(prefix,
                    suffix));

            return validateName(prefix, suffix);
        }

        private function getProperty(properties:Array,
                                     type:String,
                                     chance:Number):String {
            var total:int = 0;
            for each (var p:Object in properties)
                total += p[type];

            chance *= total;

            var count:int = 0;
            for each (p in properties) {
                count += p[type];
                if (count >= chance)
                    break;
            }

            var s:String = p.name;
            var addons:Array = p.nameAddons.concat("");
            if (addons.length > 0) {
                var addon:String = addons[int(Math.random() * addons.length)];
                s += addon;
            }

            return s;
        }

        public function getPlaceNamePartsByTag(tag:String):Array {
            var arr:Array = [];
            for each (var placeName:Object in placeNameParts) {
                if (placeName.tags.indexOf(tag) >= 0)
                    arr.push(placeName);
            }
            return arr;
        }

        private function validateName(prefix:String,
                                      suffix:String):Object {
            suffix = suffix.toLowerCase();

            // Prefix can't be the same as suffix
            if (prefix.toLowerCase() == suffix)
                return null;

            // Prefix can't end with a vowel if suffix starts with one
            if (endsWithAVowel(prefix) && startsWithAVowel(suffix)) {
                if (suffix == "ing" || suffix == "ingen") {
                    prefix += "s";
                } else if (suffix == "au") {
                    prefix += "n";
                } else {
                    return null;
                }
            }

            // Proceed as normal
            return {prefix: prefix, suffix: suffix};
        }

        private function startsWithAVowel(str:String):Boolean {
            var regex:RegExp = /^[aeiou]\w+/;
            return regex.test(str.toLowerCase());
        }


        private function endsWithAVowel(str:String):Boolean {
            var regex:RegExp = /\w+[aeiou]$/;
            return regex.test(str.toLowerCase());
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
                city.nameObject = generateName(city.analysis, new Rand(int(rand.next() * 9999)));

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
