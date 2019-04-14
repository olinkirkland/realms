package generation {
    public class Ecosystem {
        public var biome:Object;

        public var trees:Array = [];
        public var plants:Array = [];
        public var smallAnimals:Array = [];
        public var bigAnimals:Array = [];

        public var size:String;

        private var names:Names;

        public function Ecosystem(biome:Object) {
            this.biome = biome;
            names = Names.getInstance();
            var content:Object = names[biome.type] ? names[biome.type] : null;

            if (content) {
                // Size of ecosystem determines diversity
                var treeDiversity:int = content.treeDiversity;
                var plantDiversity:int = content.plantDiversity;
                var smallAnimalDiversity:int = content.smallAnimalDiversity;
                var bigAnimalDiversity:int = content.bigAnimalDiversity;

                if (biome.cells.length < 3) {
                    // Tiny
                    size = "tiny";
                    treeDiversity = 0;
                    plantDiversity *= .5;
                    smallAnimalDiversity *= .5;
                    bigAnimalDiversity = 0;
                }
                if (biome.cells.length < 10) {
                    // Small
                    size = "small";
                    treeDiversity *= .5;
                    plantDiversity *= .5;
                    smallAnimalDiversity *= .5;
                    bigAnimalDiversity *= .5;
                } else if (biome.cells.length < 50) {
                    // Medium
                    size = "medium";
                } else {
                    // Large
                    size = "large";
                    treeDiversity *= 1.5;
                    plantDiversity *= 1.5;
                    smallAnimalDiversity *= 1.5;
                    bigAnimalDiversity *= 1.5;
                }

                // Random generator seeded from location
                var r:Rand = new Rand(biome.cells[0].index);
                for (var i:int = 0; i < treeDiversity; i++)
                    trees.push(content.trees[int(r.between(0, content.trees.length))]);
                for (i = 0; i < plantDiversity; i++)
                    plants.push(content.plants[int(r.between(0, content.plants.length))]);
                for (i = 0; i < smallAnimalDiversity; i++)
                    smallAnimals.push(content.smallAnimals[int(r.between(0, content.smallAnimals.length))]);
                for (i = 0; i < bigAnimalDiversity; i++)
                    bigAnimals.push(content.bigAnimals[int(r.between(0, content.bigAnimals.length))]);

                removeDuplicates();
            }
        }

        public function removeDuplicates():void {
            // Remove duplicates
            trees = Util.removeDuplicatesFromArray(trees);
            plants = Util.removeDuplicatesFromArray(plants);
            smallAnimals = Util.removeDuplicatesFromArray(smallAnimals);
            bigAnimals = Util.removeDuplicatesFromArray(bigAnimals);
        }

        public function spreadProperties():void {
            // Spread properties to linked biomes
            biome.linked.sort(Sort.sortByCellCount);
            for each (var linkedBiome:Object in biome.linked) {
                // Replace
                linkedBiome.ecosystem.trees = trees.concat();
                linkedBiome.ecosystem.plants = plants.concat();
                linkedBiome.ecosystem.smallAnimals = smallAnimals.concat();
                linkedBiome.ecosystem.bigAnimals = bigAnimals.concat();

                linkedBiome.ecosystem.removeDuplicates();
            }
        }
    }
}
