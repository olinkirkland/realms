package geography {
    import graph.Cell;

    public class Names {
        private static var _instance:Names;
        private var featureManager:Geography;
        private static var riverNames:Array = [];

        /**
         * Biomes
         */

        [Embed(source="../assets/names/borealForest.json", mimeType="application/octet-stream")]
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

        [Embed(source="../assets/names/temperateForest.json", mimeType="application/octet-stream")]
        private static const mountain_json:Class;

        [Embed(source="../assets/names/temperateForest.json", mimeType="application/octet-stream")]
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

        public var rivers:Object;

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
            rivers = JSON.parse(new rivers_json());
        }

        public function getNewRiverName(river:Object):String {
            var r:Rand = new Rand(int(river.cells[0].point.x + river.cells[0].point.y));

            var trees:Array = [];
            var plants:Array = [];
            var smallAnimals:Array = [];
            var bigAnimals:Array = [];

            var cell:Cell = river.cells[int(river.cells.length / 2)];
            var features:Array = [featureManager.getFeature(cell.biome)];
            for each (var neighbor:Cell in cell.neighbors)
                if (features.indexOf(neighbor.biome) < 0)
                    features.push(featureManager.getFeature(neighbor.biome));

            for each (var biome:Object in features) {
                if (biome && biome.ecosystem) {
                    trees = trees.concat(biome.ecosystem.trees);
                    plants = plants.concat(biome.ecosystem.plants);
                    smallAnimals = smallAnimals.concat(biome.ecosystem.smallAnimals);
                    bigAnimals = bigAnimals.concat(biome.ecosystem.bigAnimals);
                }
            }

            var suffix:String;
            var prefix:String;
            var subject:String;
            var subjectInspirations:Array;

            if (river.cells.length > 8) {
                /**
                 * Long
                 */

                if (r.next() < .2)
                    prefix = rivers.longPrefix[int(r.between(0, rivers.longPrefix.length))];
                if (r.next() < .6) {
                    suffix = rivers.longSuffix[int(r.between(0, rivers.longSuffix.length))];
                } else {
                    prefix = "The";
                }

                // Name river after trees or big animals
                subjectInspirations = trees.concat(bigAnimals);
                subject = subjectInspirations[int(r.between(0, subjectInspirations.length))];

            } else {
                /**
                 * Short
                 */

                if (r.next() < .2)
                    prefix = rivers.shortPrefix[int(r.between(0, rivers.shortPrefix.length))];
                if (r.next() < 1)
                    suffix = rivers.shortSuffix[int(r.between(0, rivers.shortSuffix.length))];

                // Name river after trees, plants, or small animals
                subjectInspirations = trees.concat(plants, smallAnimals);
                subject = subjectInspirations[int(r.between(0, subjectInspirations.length))];
            }

            var str:String = "";
            if (prefix)
                str += prefix + " ";
            str += Util.capitalizeFirstLetter(subject);
            if (suffix)
                str += " " + suffix;

            return str;
        }
    }
}
