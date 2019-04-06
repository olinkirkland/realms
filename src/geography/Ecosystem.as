package geography {
    public class Ecosystem {
        public var _instance:Ecosystem;

        [Embed(source="../assets/naming/tundra.json", mimeType="application/octet-stream")]
        private static const tundra_json:Class;

        [Embed(source="../assets/naming/tundra.json", mimeType="application/octet-stream")]
        private static const borealForest_json:Class;

        [Embed(source="../assets/naming/tundra.json", mimeType="application/octet-stream")]
        private static const grassland_json:Class;

        [Embed(source="../assets/naming/tundra.json", mimeType="application/octet-stream")]
        private static const temperateForest_json:Class;

        [Embed(source="../assets/naming/tundra.json", mimeType="application/octet-stream")]
        private static const savanna_json:Class;

        [Embed(source="../assets/naming/tundra.json", mimeType="application/octet-stream")]
        private static const jungle_json:Class;

        [Embed(source="../assets/naming/tundra.json", mimeType="application/octet-stream")]
        private static const mountain_json:Class;

        [Embed(source="../assets/naming/tundra.json", mimeType="application/octet-stream")]
        private static const desert_json:Class;

        [Embed(source="../assets/naming/tundra.json", mimeType="application/octet-stream")]
        private static const saltWater_json:Class;

        [Embed(source="../assets/naming/tundra.json", mimeType="application/octet-stream")]
        private static const freshWater_json:Class;

        public var tundra:Object;
        public var borealForest:Object;
        public var grassland:Object;
        public var temperateForest:Object;
        public var savanna:Object;
        public var jungle:Object;
        public var mountain:Object;
        public var desert:Object;
        public var freshWater:Object;
        public var saltWater:Object;

        public function Ecosystem() {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;

            // Setup
            tundra = JSON.parse(new tundra_json());
            borealForest = JSON.parse(new borealForest_json());
            grassland = JSON.parse(new grassland_json());
            temperateForest = JSON.parse(new temperateForest_json());
            savanna = JSON.parse(new savanna_json());
            jungle = JSON.parse(new jungle_json());
            mountain = JSON.parse(new mountain_json());
            desert = JSON.parse(new desert_json());
            freshWater = JSON.parse(new freshWater_json());
            saltWater = JSON.parse(new saltWater_json());
        }
    }
}
