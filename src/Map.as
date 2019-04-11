package {
    import com.nodename.Delaunay.Voronoi;
    import com.nodename.geom.LineSegment;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Graphics;
    import flash.display.Shape;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
    import flash.utils.setTimeout;

    import generation.Biome;
    import generation.Ecosystem;
    import generation.Geography;
    import generation.Names;
    import generation.Settlement;
    import generation.Civilization;

    import graph.Cell;
    import graph.Corner;
    import graph.Edge;

    import mx.core.UIComponent;
    import mx.events.FlexEvent;

    public class Map extends UIComponent {
        public static var NUM_POINTS:int = 24000;
        public static var SEA_LEVEL:Number = .2;
        public static var MOUNTAIN_ELEVATION:Number = .9;
        public static var MOUNTAIN_ELEVATION_ADJACENT:Number = .85;

        public var seed:int;

        // Map Storage
        public var points:Vector.<Point>;
        public var cells:Vector.<Cell>;
        public var corners:Vector.<Corner>;
        public var edges:Vector.<Edge>;
        public var borders:Vector.<Cell>;

        // Managers
        private var geo:Geography;
        private var civ:Civilization;
        private var names:Names;

        // Layers
        private var layers:Array;

        private var oceanLayer:Shape;
        private var coastlinesLayer:Shape;
        private var terrainLayer:Shape;
        private var riversLayer:Shape;
        private var forestsLayer:Shape;
        private var mountainsLayer:Shape;
        private var settlementsLayer:Shape;
        private var regionsLayer:Shape;
        private var elevationLayer:Shape;
        private var temperatureLayer:Shape;
        private var desirabilityLayer:Shape;
        private var outlinesLayer:Shape;

        // Draw Toggles
        public var showOutlines:Boolean = false;
        public var showTerrain:Boolean = false;
        public var showRivers:Boolean = true;
        public var showBiomes:Boolean = true;
        public var showTemperature:Boolean = false;
        public var showForests:Boolean = true;
        public var showMountains:Boolean = false;
        public var showDesirability:Boolean = false;
        public var showSettlements:Boolean = true;
        public var showBiomeLinkage:Boolean = false;
        public var showRegions:Boolean = false;

        // Miscellaneous
        private var staticMode:Bitmap;
        public static var MAP_PROGRESS:String = "mapProgress";

        public function Map() {
            // Initialize Singletons
            geo = Geography.getInstance();
            civ = Civilization.getInstance();
            names = Names.getInstance();

            addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }

        private function onCreationComplete(event:FlexEvent):void {
            progress(0, "Preparing points");

            setTimeout(tryToLoadPoints, 500);

            addEventListener(MouseEvent.CLICK, onClick);
            addEventListener(MouseEvent.RIGHT_CLICK, onRightClick);
        }

        override protected function createChildren():void {
            super.createChildren();

            // Add layers
            layers = [
                oceanLayer,
                coastlinesLayer,
                terrainLayer,
                riversLayer,
                forestsLayer,
                mountainsLayer,
                settlementsLayer,
                regionsLayer,
                elevationLayer,
                temperatureLayer,
                desirabilityLayer,
                outlinesLayer
            ];

            for each (var layer:Shape in layers) {
                layer = new Shape();
                addChild(layer);
            }


            staticMode = new Bitmap();
            addChild(staticMode);
        }

        private function tryToLoadPoints():void {
            // Determine if points file exists
            if (Util.isAir()) {
                points = AirOnlyUtil.loadPointsFromFile();

                if (!points)
                    generatePoints();

                build();
            } else {
                // Running in web
                generatePoints();
            }

            start();
        }

        private function generatePoints():void {
            // Generate points and save them
            trace("Generating new points ...");
            pickRandomPoints();
            build();
            trace("Relaxing (1/3)");
            relaxPoints();
            trace("Relaxing (2/3)");
            relaxPoints();
            trace("Relaxing (3/3)");
            relaxPoints();
            trace("Points generated!");

            if (Util.isAir()) {
                AirOnlyUtil.savePointsToFile(points);
            }
        }

        private function progress(percent:Number, message:String):void {
            this.dispatchEvent(new PayloadEvent(MAP_PROGRESS, {percent: percent, message: message}, true));
        }

        public function start(seed:Number = 1):void {
            // Set map seed - the whole map uses this seed for any random decision making
            this.seed = seed;

            var tasks:Array = [{f: generateHeightMap, m: "Generating height map"},
                {f: resolveDepressions, m: "Smoothing"},
                {f: determineOceanLandsAndLakes, m: "Determining coastlines"},
                {f: calculateTemperature, m: "Calculating temperature"},
                {f: calculateMoisture, m: "Calculating moisture"},
                {f: calculateRivers, m: "Calculating rivers"},
                {f: determineGeographicFeatures, m: "Determining biomes"},
                {f: determineFloraAndFauna, m: "Populating biomes"},
                {f: placeSettlements, m: "Placing settlements"},
                {f: determineRegions, m: "Determining region boundaries"},
                {f: determineNames, m: "Choosing names"},
                {f: draw, m: "Drawing"}];

            progress(0, tasks[0].m);
            setTimeout(performTask, 200, 0);

            function performTask(i:int):void {
                tasks[i].f();

                i++;

                if (i > tasks.length - 1) {
                    progress(1, "");
                } else {
                    progress(i / tasks.length, tasks[i].m);
                    setTimeout(performTask, 200, i);
                }
            }
        }

        private function determineRegions():void {
            // Check all reasonably sized land masses for settlements
            // If there are no settlements on the land mass, add one to a haven or a random place
            var cell:Cell;
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                if (land.cells.length > 5) {
                    var hasSettlement:Boolean = false;
                    for each (var cell:Cell in land.cells) {
                        if (cell.settlement) {
                            hasSettlement = true;
                            break;
                        }
                    }

                    if (!hasSettlement) {
                        // Add a settlement to the landmass
                        for each (cell in land.cells) {
                            var haven:Cell = land.cells[0];
                            if (cell.hasFeatureType(Geography.HAVEN)) {
                                haven = cell;
                                break;
                            }
                        }

                        civ.registerSettlement(haven);
                    }
                }
            }


            // Determine regions
            var settlements:Array = [];
            for each (var s:Settlement in civ.settlements)
                settlements.push(s);
            // Sort by a unique value - point should do
            settlements.sort(Sort.sortByPointY);

            for each (var settlement:Settlement in settlements) {
                var start:Cell = settlement.cell;
                // Define region
                var region:String = civ.registerRegion();

                var r:Rand = new Rand(1);
                civ.addCellToRegion(start, region, 200 + int(r.next() * 5) * 4);
                start.used = true;

                var queue:Array = [start];

                while (queue.length > 0) {
                    cell = queue.shift();

                    if (cell.regionInfluence > 0) {
                        for each (var neighbor:Cell in cell.neighbors) {
                            // What's the cost of adding this cell to the region?
                            var cost:int = 1;
                            if (neighbor.hasFeatureType(Geography.OCEAN) || neighbor.hasFeatureType(Biome.MOUNTAIN))
                                cost = 20;
                            if ((cell.hasFeatureType(Biome.TUNDRA) || cell.hasFeatureType(Biome.GRASSLAND) || cell.hasFeatureType(Biome.SAVANNA)) && (neighbor.hasFeatureType(Biome.BOREAL_FOREST) || neighbor.hasFeatureType(Biome.TEMPERATE_FOREST) || neighbor.hasFeatureType(Biome.RAIN_FOREST)))
                                cost = 10;
                            if (neighbor.hasFeatureType(Geography.RIVER) || neighbor.hasFeatureType(Geography.LAKE))
                                cost = 20;

                            var influence:int = cell.regionInfluence - cost;

                            if (!neighbor.used && neighbor.regionInfluence < influence) {
                                // Use ocean tiles, but don't add them to the region
                                if (!neighbor.hasFeatureType(Geography.OCEAN))
                                    civ.addCellToRegion(neighbor, region, influence);
                                else
                                    neighbor.regionInfluence = influence;

                                queue.push(neighbor);
                                neighbor.used = true;
                            }
                        }
                    }
                }

                unuseCells();
            }
        }

        private function determineNames():void {
            // Rivers
            // Sort rivers by length
            var rivers:Array = [];
            for each (var river:Object in geo.getFeaturesByType(Geography.RIVER))
                rivers.push(river);
            rivers.sortOn(Sort.sortByCellCount);
            for each (river in rivers)
                river.name = names.getNewRiverName(river);
        }

        private function determineFloraAndFauna():void {
            // Link biomes that are nearby and similar type
            for each (var biomeType:String in Biome.list) {
                for each (var biome:Object in geo.getFeaturesByType(biomeType)) {
                    // First, determine the center point of the biome
                    var avgX:Number = 0;
                    var avgY:Number = 0;

                    for each (var cell:Cell in biome.cells) {
                        avgX += cell.point.x;
                        avgY += cell.point.y;
                    }

                    biome.centroid = new Point(avgX /= biome.cells.length, avgY /= biome.cells.length);
                    biome.influence = Math.min(biome.cells.length, 300);
                    biome.linked = [];
                }

                var biomes:Array = [];
                for each (biome in geo.getFeaturesByType(biomeType))
                    biomes.push(biome);
                biomes.sort(Sort.sortByCellCount);

                for each (biome in biomes) {
                    for each (var targetBiome:Object in geo.getFeaturesByType(biomeType)) {
                        // Non-tiny biomes (> 10 cells) can link to other biomes of the same type to share flora/fauna
                        // Linked biomes must be near each other - the permitted distance is calculated using the biomes' relative sizes
                        if (biome != targetBiome && Util.getDistanceBetweenTwoPoints(biome.centroid, targetBiome.centroid) < biome.influence && biome.cells.length > 10 && biome.linked.indexOf(targetBiome) < 0 && biome.cells.length > targetBiome.cells.length) {
                            biome.linked.push(targetBiome);
                        }
                    }
                }

                for each (biome in biomes)
                    biome.ecosystem = new Ecosystem(biome);

                for each (biome in biomes)
                    biome.ecosystem.spread();
            }
        }

        private function placeSettlements():void {
            determineStaticDesirability();

            var i:int = 0;
            do {
                determineDesirability();

                civ.registerSettlement(cells[0]);
                i++;
            } while (i < 100);
        }

        private function determineStaticDesirability():void {
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                for each (var cell:Cell in land.cells) {
                    cell.desirability = 1;

                    // Biome desirability
                    if (cell.hasFeatureType(Biome.GRASSLAND))
                        cell.desirability += 4;
                    if (cell.hasFeatureType(Biome.TEMPERATE_FOREST))
                        cell.desirability += 3;
                    if (cell.hasFeatureType(Biome.BOREAL_FOREST))
                        cell.desirability += 2;
                    if (cell.hasFeatureType(Biome.TUNDRA))
                        cell.desirability += 1;
                    if (cell.hasFeatureType(Biome.MOUNTAIN))
                        cell.desirability += 1;

                    // River desirability
                    if (cell.hasFeatureType(Geography.ESTUARY) || cell.hasFeatureType(Geography.CONFLUENCE)) {
                        var d:int = Math.sqrt(cell.flux);
                        cell.desirability += 4 + int(d);
                    } else if (cell.hasFeatureType(Geography.RIVER)) {
                        d = Math.sqrt(cell.flux);
                        cell.desirability += int(d);
                    }

                    // Coast desirability
                    if (cell.hasFeatureType(Geography.HAVEN))
                        cell.desirability += 2;
                }
            }

            determineDesirability();
        }

        private function determineDesirability():void {
            for each (var settlement:Settlement in civ.settlements) {
                if (!settlement.used) {
                    var queue:Array = [];
                    var undesirability:Number = 20;
                    var radius:Number = .8;

                    settlement.cell.used = true;
                    settlement.cell.desirability = 0;
                    queue.push(settlement.cell);

                    for (var i:int = 0; i < queue.length && undesirability > 0.01; i++) {
                        undesirability *= radius;
                        for each (var neighbor:Cell in (queue[i] as Cell).neighbors) {
                            if (!neighbor.used) {
                                neighbor.desirability -= undesirability;
                                if (neighbor.desirability < 0)
                                    neighbor.desirability = 0;

                                neighbor.used = true;
                                queue.push(neighbor);
                            }
                        }
                    }

                    unuseCells();
                    settlement.used = true;
                }
            }

            cells.sort(Sort.sortByDesirability);
        }

        private function determineGeographicFeatures():void {
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                var landCells:Vector.<Cell> = land.cells.concat();
                var queue:Array = [];
                while (landCells.length > 0) {
                    var start:Cell = landCells[0];
                    start.used = true;

                    // Pick a starting biome
                    var currentBiome:String = Biome.determineBiome(start);
                    var currentFeature:String = geo.registerFeature(currentBiome);
                    geo.addCellToFeature(start, currentFeature);
                    start.biome = currentFeature;
                    start.biomeType = currentBiome;

                    // Fill touching cells
                    queue.push(start);
                    var cell:Cell;
                    while (queue.length > 0) {
                        cell = queue[0];
                        queue.shift();
                        for each (var neighbor:Cell in cell.neighbors) {
                            var d:Boolean = Biome.determineBiome(neighbor) == currentBiome;
                            if (!neighbor.used && land.cells.indexOf(neighbor) >= 0 && d) {
                                geo.addCellToFeature(neighbor, currentFeature);
                                neighbor.biome = currentFeature;
                                neighbor.biomeType = currentBiome;
                                queue.push(neighbor);
                                neighbor.used = true;
                            }
                        }
                    }

                    landCells = new Vector.<Cell>();
                    for each (cell in land.cells)
                        if (!cell.used)
                            landCells.push(cell);
                }
            }

            unuseCells();

            // Determine glades
            for each (var grassland:Object in geo.getFeaturesByType(Biome.GRASSLAND)) {
                // isGlade is positive for grasslands as long as they are small and entirely surrounded by forest
                var isGlade:Boolean = grassland.cells.length < 10;
                for each (cell in grassland.cells) {
                    for each (neighbor in cell.neighbors)
                        if (!neighbor.hasFeatureType(Biome.GRASSLAND) && !neighbor.hasFeatureType(Biome.TEMPERATE_FOREST))
                            isGlade = false;
                }
                if (isGlade) {
                    var glade:String = geo.registerFeature(Geography.GLADE);
                    for each (cell in grassland.cells)
                        geo.addCellToFeature(cell, glade);
                }
            }

            // Determine sheltered havens
            for each(land in geo.getFeaturesByType(Geography.LAND)) {
                // Get coastal cells
                for each (cell in land.cells) {
                    for each (var edge:Edge in cell.edges) {
                        if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                            if (!edge.d0.hasFeatureType(Geography.LAND) || !edge.d1.hasFeatureType(Geography.LAND)) {
                                // It's coastal
                                var coastal:Cell = !edge.d0.hasFeatureType(Geography.LAND) ? edge.d1 : edge.d0;
                                var oceanNeighborCount:int = 0;
                                for each (neighbor in coastal.neighbors) {
                                    if (neighbor.hasFeatureType(Geography.OCEAN))
                                        oceanNeighborCount++;
                                }

                                if (oceanNeighborCount == 1) {
                                    var haven:String = geo.registerFeature(Geography.HAVEN);
                                    geo.addCellToFeature(coastal, haven);
                                }
                            }
                        }
                    }
                }
            }
        }


        private function calculateRivers():void {
            // Sort list cells neighbors by their elevation from lowest to highest
            for each (var cell:Cell in cells) {
                if (cell.neighbors.length > 0) {
                    cell.neighbors.sort(Sort.sortByLowestElevation);
                }
            }

            // Create rivers
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                for each (cell in land.cells) {
                    cell.flux = cell.moisture;
                }

                land.cells.sort(Sort.sortByHighestElevation);
                for each (cell in land.cells) {
                    pour(cell, cell.neighbors[0]);
                }
            }

            function pour(c:Cell, t:Cell):void {
                t.flux += c.flux;
                if (c.flux > 10) {
                    var river:String;
                    if (c.hasFeatureType(Geography.RIVER)) {
                        // Extend river
                        var rivers:Object = c.getFeaturesByType(Geography.RIVER);
                        var riverCount:int = 0;
                        for (var v:String in rivers) {
                            riverCount++;
                            // Pick the longest river to continue
                            if (!river || rivers[v].cells.length > rivers[river].cells.length)
                                river = v;
                        }

                        geo.addCellToFeature(t, river);

                        if (!t.hasFeatureType(Geography.OCEAN) && !t.hasFeatureType(Geography.LAKE) && riverCount > 1) {
                            var confluence:String = geo.registerFeature(Geography.CONFLUENCE);
                            geo.addCellToFeature(t, confluence);
                        }
                    } else {
                        // Start new river
                        river = geo.registerFeature(Geography.RIVER);
                        geo.addCellToFeature(c, river);
                        geo.addCellToFeature(t, river);
                    }

                    if (t.hasFeatureType(Geography.OCEAN) || t.hasFeatureType(Geography.LAKE)) {
                        var estuary:String = geo.registerFeature(Geography.ESTUARY);
                        geo.addCellToFeature(c, estuary);
                        var water:Object = {};
                        // An estuary can empty into an ocean or a lake, but not into both
                        if (t.hasFeatureType(Geography.OCEAN))
                            water = t.getFeaturesByType(Geography.OCEAN);
                        if (t.hasFeatureType(Geography.LAKE))
                            water = t.getFeaturesByType(Geography.LAKE);

                        // There can only be one lake or ocean feature referenced in the estuary's target
                        for each (var target:String in water)
                            break;

                        var feature:Object = geo.features[estuary];
                        feature.target = target;
                    }
                }
            }

            for each (var river:Object in geo.getFeaturesByType(Geography.RIVER)) {
                river.centroid = river.cells[int(river.cells.length / 2)].point;
                var freshWater:String = geo.registerFeature(Biome.FRESH_WATER);
                for each (cell in river.cells)
                    geo.addCellToFeature(cell, freshWater);
            }

            unuseCells();
        }

        private function resolveDepressions():void {
            var depressions:int;
            do {
                depressions = 0;
                for each (var cell:Cell in cells) {
                    if (cell.neighbors.length > 0) {
                        var d:Boolean = cell.elevation >= SEA_LEVEL;
                        for each (var neighbor:Cell in cell.neighbors) {
                            if (neighbor.elevation < cell.elevation)
                                d = false;
                        }
                    }
                    if (d) {
                        depressions++;
                        cell.elevation += .1;
                    }
                }
            } while (depressions > 0);
        }

        private function calculateMoisture():void {
            for each (var cell:Cell in cells) {
                var m:Number = 0;

                for each (var neighbor:Cell in cell.neighbors)
                    m += neighbor.elevation;
                m /= cell.neighbors.length;

                cell.moisture = m;
                cell.precipitation = Util.round(200 + (cell.moisture * 1800), 2);
            }
        }

        private function calculateTemperature():void {
            for each (var cell:Cell in cells) {
                // Mapping 0 to 90 realLatitude for this section of the world
                cell.latitude = 1 - (cell.point.y / height);
                cell.realLatitude = Util.round(cell.latitude * 90, 2);
                var temperature:Number = 1 - cell.latitude;

                // Consider elevation in the temperature (higher places are colder)
                cell.temperature = temperature - (cell.elevation * .3);
                if (cell.temperature < 0)
                    cell.temperature = 0;
                if (cell.temperature > 1)
                    cell.temperature = 1;

                cell.realTemperature = Util.round(-10 + (cell.temperature * 40), 2);
            }
        }

        private function determineOceanLandsAndLakes():void {
            var queue:Array = [];

            // Start with a site that is at 0 elevation and is in the upper left
            // Don't pick a border site because they're fucky
            for each (var start:Cell in cells) {
                if (start.elevation == 0 && start.neighbors.length > 0)
                    break;
            }

            var ocean:String = geo.registerFeature(Geography.OCEAN);
            geo.addCellToFeature(start, ocean);
            start.used = true;
            queue.push(start);

            // Define Ocean
            var biome:String = geo.registerFeature(Biome.SALT_WATER);
            while (queue.length > 0) {
                var cell:Cell = queue.shift();
                for each (var neighbor:Cell in cell.neighbors) {
                    if (!neighbor.used && neighbor.elevation < SEA_LEVEL) {
                        geo.addCellToFeature(neighbor, ocean);
                        geo.addCellToFeature(neighbor, biome);
                        queue.push(neighbor);
                        neighbor.used = true;
                    }
                }
            }

            // Override list edges to be part of the Ocean
            for each (cell in borders) {
                geo.addCellToFeature(cell, ocean);
                geo.addCellToFeature(cell, biome);
            }


            // Define Land and Lakes
            var nonOceans:Vector.<Cell> = new Vector.<Cell>();
            for each (cell in cells)
                if (Util.getLengthOfObject(cell.features) == 0)
                    nonOceans.push(cell);

            var currentFeature:String;
            while (nonOceans.length > 0) {
                start = nonOceans[0];

                var lower:Number;
                var upper:Number;

                // If the elevation of the cell is higher than sea level, define it as Land otherwise define it as a Lake
                if (start.elevation >= SEA_LEVEL) {
                    // Define it as land
                    currentFeature = geo.registerFeature(Geography.LAND);
                    biome = null;

                    lower = SEA_LEVEL;
                    upper = Number.POSITIVE_INFINITY;
                } else {
                    // Define it as a lake
                    currentFeature = geo.registerFeature(Geography.LAKE);
                    biome = geo.registerFeature(Biome.FRESH_WATER);

                    lower = Number.NEGATIVE_INFINITY;
                    upper = SEA_LEVEL;
                }

                geo.addCellToFeature(start, currentFeature);
                if (biome)
                    geo.addCellToFeature(start, biome);

                start.used = true;

                // Fill touching Land or Lake cells
                queue.push(start);
                while (queue.length > 0) {
                    cell = queue[0];
                    queue.shift();
                    for each (neighbor in cell.neighbors) {
                        if (!neighbor.used && neighbor.elevation >= lower && neighbor.elevation < upper) {
                            geo.addCellToFeature(neighbor, currentFeature);
                            if (biome)
                                geo.addCellToFeature(neighbor, biome);

                            queue.push(neighbor);
                            neighbor.used = true;
                        }
                    }
                }

                nonOceans = new Vector.<Cell>();
                for each (cell in cells)
                    if (Util.getLengthOfObject(cell.features) == 0)
                        nonOceans.push(cell);
            }

            unuseCells();
        }

        private function generateHeightMap():void {
            // Generate a height map
            reset();

            // Random generator uses a seed
            var rand:Rand = new Rand(seed);

            var cell:Cell;
            var w:Number = width / 2;
            var h:Number = height / 2;

            // Add mountain
            placeMountain(cellFromDistribution(0), .8, .95, .2);

            // Add hills
            for (var i:int = 0; i < 30; i++)
                placeHill(cellFromDistribution(.25), rand.between(.5, .8), rand.between(.95, .99), rand.between(.1, .2));

            // Add troughs

            // Add pits
            for (i = 0; i < 15; i++)
                placePit(cellFromDistribution(.35), rand.between(.2, .7), rand.between(.8, .95), rand.between(0, .2));

            // Subtract .05 from land cells
            addToLandCells(-.05);

            // Multiply land cells by .9
            multiplyLandCellsBy(.9);

            function cellFromDistribution(distribution:Number):Cell {
                // 0 is map cell
                // 1 is map border
                var dw:Number = distribution * width;
                var dh:Number = distribution * height;
                var px:Number = w + ((rand.next() * 2 * dw) - dw);
                var py:Number = h + ((rand.next() * 2 * dh) - dh);

                return getCellClosestToPoint(new Point(px, py));
            }

            function addToLandCells(value:Number):void {
                for each (cell in cells)
                    if (cell.elevation > SEA_LEVEL)
                        cell.elevation += value;
            }

            function multiplyLandCellsBy(value:Number):void {
                for each (cell in cells)
                    if (cell.elevation > SEA_LEVEL)
                        cell.elevation *= value;
            }
        }

        private function placeMountain(start:Cell, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0):void {
            // Random generator uses a seed
            var rand:Rand = new Rand(seed);

            // Can only be placed once, at the beginning
            var queue:Array = [];
            start.elevation += elevation;
            if (start.elevation > 1)
                start.elevation = 1;
            start.used = true;
            queue.push(start);

            for (var i:int = 0; i < queue.length && elevation > 0.01; i++) {
                elevation = (queue[i] as Cell).elevation * radius;
                for each (var neighbor:Cell in (queue[i] as Cell).neighbors) {
                    if (!neighbor.used) {
                        var mod:Number = (rand.next() * sharpness) + 1.1 - sharpness;
                        if (sharpness == 0)
                            mod = 1;

                        neighbor.elevation += elevation * mod;

                        if (neighbor.elevation > 1)
                            neighbor.elevation = 1;

                        neighbor.used = true;
                        queue.push(neighbor);
                    }
                }
            }

            unuseCells();
        }

        private function placeHill(start:Cell, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0):void {
            // Random generator uses a seed
            var rand:Rand = new Rand(seed);

            var queue:Array = [];
            start.elevation += elevation;
            if (start.elevation > 1)
                start.elevation = 1;

            start.used = true;
            queue.push(start);

            for (var i:int = 0; i < queue.length && elevation > 0.01; i++) {
                elevation *= radius;
                for each (var neighbor:Cell in (queue[i] as Cell).neighbors) {
                    if (!neighbor.used) {
                        var mod:Number = sharpness > 0 ? rand.next() * sharpness + 1.1 - sharpness : 1;
                        neighbor.elevation += elevation * mod;

                        if (neighbor.elevation > 1)
                            neighbor.elevation = 1;

                        neighbor.used = true;
                        queue.push(neighbor);
                    }
                }
            }

            unuseCells();
        }

        private function placePit(start:Cell, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0):void {
            // Random generator uses a seed
            var rand:Rand = new Rand(seed);

            var queue:Array = [];
            elevation *= -1;
            start.elevation += elevation;
            if (start.elevation < 0)
                start.elevation = 0;

            start.used = true;
            queue.push(start);

            for (var i:int = 0; i < queue.length && elevation < SEA_LEVEL - .01; i++) {
                elevation *= radius;
                for each (var neighbor:Cell in (queue[i] as Cell).neighbors) {
                    if (!neighbor.used) {
                        var mod:Number = sharpness > 0 ? rand.next() * sharpness + 1.1 - sharpness : 1;
                        neighbor.elevation += elevation * mod;

                        if (neighbor.elevation < 0)
                            neighbor.elevation = 0;

                        neighbor.used = true;
                        queue.push(neighbor);
                    }
                }
            }

            unuseCells();
        }

        private function unuseCells():void {
            for each (var cell:Cell in cells) {
                cell.used = false;
            }
        }

        private function relaxPoints():void {
            points = new Vector.<Point>();
            for each (var cell:Cell in cells) {
                var centroid:Point = new Point();
                for each (var corner:Corner in cell.corners) {
                    centroid.x += corner.point.x;
                    centroid.y += corner.point.y;
                }

                centroid.x /= cell.corners.length;
                centroid.y /= cell.corners.length;

                points.push(Point.interpolate(cell.point, centroid, 0.5));
            }

            // Rebuild graph
            build();
        }

        public function getCellClosestToPoint(p:Point):Cell {
            var shortestDistance:Number = Number.POSITIVE_INFINITY;
            var closestCell:Cell;
            var distance:Number;

            for each (var cell:Cell in cells) {
                distance = (cell.point.x - p.x) * (cell.point.x - p.x) + (cell.point.y - p.y) * (cell.point.y - p.y);
                if (distance < shortestDistance) {
                    closestCell = cell;
                    shortestDistance = distance;
                }
            }

            return closestCell;
        }

        public function draw():void {
            /**
             * Main Draw Call
             */

            // Clear all layers
            for each (var layer:Shape in layers)
                layer.graphics.clear();

            drawOceanLayer();
            drawCoastlinesLayer();
            drawTerrainLayer();
            drawRiversLayer();
            drawForestsLayer();
            drawMountainsLayer();
            drawSettlementsLayer();
            drawOverlayRegionsLayer();
            drawElevationLayer();
            drawTemperatureLayer();
            drawDesirabilityLayer();
            drawOutlinesLayer();

            if (showMountains) {
                // Draw mountains
                // todo overhaul this
                canvas.graphics.lineStyle(1, 0xff000);
                for each (var mountain:Object in geo.getFeaturesByType(Biome.MOUNTAIN)) {
                    var mountainBase:Array = [];
                    var mountainBody:Array = [];
                    for each (cell in mountain.cells) {
                        var isBase:Boolean = false;
                        for each (var neighbor:Cell in cell.neighbors) {
                            if (!neighbor.hasFeatureType(Biome.MOUNTAIN)) {
                                isBase = true;
                                break;
                            }
                        }
                        if (!isBase)
                            mountainBody.push(cell);
                        else
                            mountainBase.push(cell);
                    }

                    // Mark the highest point
                    mountainBody.sortOn("elevation", Array.DESCENDING);
                    canvas.graphics.lineStyle(2, 0x000000);
                    canvas.graphics.beginFill(0xffffff);
                    canvas.graphics.drawCircle(mountainBody[0].point.x, mountainBody[0].point.y, 5);
                    canvas.graphics.endFill();

                    canvas.graphics.lineStyle(1, 0x000000);
                    // Draw an outline of the mountain
                    for each (cell in mountainBase) {
                        for each (edge in cell.edges) {
                            if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                                canvas.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                                //if (!edge.d0.hasFeatureType(Biome.MOUNTAIN) || !edge.d1.hasFeatureType(Biome.MOUNTAIN))
                                canvas.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                            }
                        }
                    }
                }
            }

            if (showTemperature) {
                // Draw temperature
                canvas.graphics.lineStyle();
                for each (cell in cells) {
                    if (cell.elevation > SEA_LEVEL) {
                        canvas.graphics.beginFill(getColorFromTemperature(cell.temperature), .6);
                        for each (edge in cell.edges) {
                            if (edge.v0 && edge.v1) {
                                canvas.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                                canvas.graphics.lineTo(cell.point.x, cell.point.y);
                                canvas.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                            } else {
                            }
                        }
                        canvas.graphics.endFill();
                    }
                }
            }

            if (showTerrain) {
                // Draw terrain
                canvas.graphics.lineStyle();
                for each (cell in cells) {
                    canvas.graphics.beginFill(getColorFromElevation(cell.elevation), 1);

                    for each (edge in cell.edges) {
                        if (edge.v0 && edge.v1) {
                            canvas.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                            canvas.graphics.lineTo(cell.point.x, cell.point.y);
                            canvas.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                        } else {
                        }
                    }
                }
                canvas.graphics.endFill();
            }

            if (showDesirability) {
                // Draw desirability
                canvas.graphics.lineStyle();
                for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                    for each (cell in land.cells) {
                        canvas.graphics.beginFill(Util.getColorBetweenColors(0x0000ff, 0xffff00, cell.desirability / 10));

                        for each (edge in cell.edges) {
                            if (edge.v0 && edge.v1) {
                                canvas.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                                canvas.graphics.lineTo(cell.point.x, cell.point.y);
                                canvas.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                            } else {
                            }
                        }
                    }
                    canvas.graphics.endFill();
                }
            }

            if (showRegions) {
                // Draw regions
                canvas.graphics.lineStyle();
                for each (var region:Object in civ.regions) {
                    color = 0xffffff * rand.next();
                    canvas.graphics.beginFill(color);
                    for each (cell in region.cells) {
                        for each (edge in cell.edges) {
                            if (edge.v0 && edge.v1) {
                                canvas.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                                canvas.graphics.lineTo(cell.point.x, cell.point.y);
                                canvas.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                            } else {
                            }
                        }
                    }
                    canvas.graphics.endFill();
                }
            }

            if (showSettlements) {
                // Draw settlements
                canvas.graphics.lineStyle(1, 0x000000);
                for each (var settlement:Settlement in civ.settlements) {
                    canvas.graphics.beginFill(0xffffff);
                    canvas.graphics.drawCircle(settlement.point.x, settlement.point.y, 3);
                    canvas.graphics.endFill();
                }
            }

            if (showBiomeLinkage) {
                // Draw biome influence
                var c:Rand = new Rand(1);
                for each (biomeType in Biome.list) {
                    var color:uint = c.next() * 0xffffff;
                    for each (biome in geo.getFeaturesByType(biomeType)) {
                        canvas.graphics.lineStyle(1, color);
                        canvas.graphics.beginFill(0xffffff);
                        canvas.graphics.drawCircle(biome.centroid.x, biome.centroid.y, 3);
                        canvas.graphics.endFill();

                        if (biome.influence > 6)
                            canvas.graphics.drawCircle(biome.centroid.x, biome.centroid.y, biome.influence);

                        for each (var linkedBiome:Object in biome.linked) {
                            canvas.graphics.moveTo(biome.centroid.x, biome.centroid.y);
                            canvas.graphics.lineTo(linkedBiome.centroid.x, linkedBiome.centroid.y);
                        }
                    }
                }
            }

            if (showOutlines) {
                // Draw outlines
                for each (edge in edges) {
                    // Draw voronoi diagram
                    outlines.graphics.lineStyle(1, 0x000000, .2);
                    if (edge.v0 && edge.v1) {
                        outlines.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                        outlines.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                    } else {
                    }
                }
            }


            staticModeOff();
        }

        private function fillCell(canvas:Graphics, cell:Cell, color:uint):void {
            // Draw a filled cell
            canvas.beginFill(color);
            for each (var edge:Edge in cell.edges) {
                if (edge.v0 && edge.v1) {
                    canvas.moveTo(edge.v0.point.x, edge.v0.point.y);
                    canvas.lineTo(cell.point.x, cell.point.y);
                    canvas.lineTo(edge.v1.point.x, edge.v1.point.y);
                }
            }
            canvas.endFill();
        }

        private function addCellDetail(canvas:Graphics, cell:Cell):void {
            // Add detail to a cell
            var rand:Rand = new Rand(int(cell.point.x));
            var iconDensity:Number = 0;
            var c:Point = new Point(cell.point.x + rand.between(-4, 4), cell.point.y + rand.between(-4, 4));
            var d:Number;

            if (cell.hasFeatureType(Biome.TEMPERATE_FOREST)) {
                iconDensity = .4;

                if (rand.next() > iconDensity)
                    return;

                if (bordersForeignType(Biome.TEMPERATE_FOREST))
                    return;

                canvas.lineStyle(rand.between(1, 1.5), Biome.colors["temperateForest_stroke"], rand.between(.6, 1));
                canvas.moveTo(c.x - (d = rand.between(1, 2)), c.y);
                canvas.curveTo(c.x, c.y - rand.between(1, 5), c.x + d, c.y);
            }
            if (cell.hasFeatureType(Biome.BOREAL_FOREST)) {
                iconDensity = .8;

                if (rand.next() > iconDensity)
                    return;

                canvas.lineStyle(rand.between(.5, 1.5), Biome.colors["borealForest_stroke"], rand.between(.6, 1));
                canvas.moveTo(c.x - (d = rand.between(1, 2)), c.y);
                canvas.lineTo(c.x, c.y - rand.between(1, 3));
                canvas.lineTo(c.x + d, c.y);
            }

            function bordersForeignType(type:String):Boolean {
                // Check that the cell isn't bordering any foreign biome types
                for each (var neighbor:Cell in cell.neighbors)
                    if (!neighbor.hasFeatureType(type))
                        return true;
                return false;
            }

            if (rand.next() < iconDensity)
                addCellDetail(canvas, cell);
        }

        private function drawOceanLayer():void {
            /**
             * Draw Ocean
             */

            // Fill in the ocean so the voronoi-bare corners get some ocean
            // Just make a big honking rectangle of salt water
            oceanLayer.graphics.beginFill(Biome.colors[Biome.SALT_WATER]);
            oceanLayer.graphics.drawRect(0, 0, width, height);
        }

        private function drawCoastlinesLayer():void {
            /**
             * Draw Coastlines
             */

            var coastlineFeatureTypes:Array = [Geography.LAND, Geography.LAKE];
            for (var featureType:String in coastlineFeatureTypes) {
                for (var key:String in geo.getFeaturesByType(featureType)) {
                    var feature:Object = geo.features[key];
                    coastlinesLayer.graphics.lineStyle(1, Biome.colors.saltWater_stroke);
                    if (feature.type != Geography.OCEAN) {
                        for each (var cell:Cell in feature.cells) {
                            for each (var edge:Edge in cell.edges) {
                                if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                                    coastlinesLayer.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                                    if (!edge.d0.features[key] || !edge.d1.features[key])
                                        coastlinesLayer.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                                }
                            }
                        }
                    }
                }
            }
        }

        private function drawTerrainLayer():void {
            /**
             * Draw Terrain
             */

            terrainLayer.graphics.lineStyle();
            for each (var biomeType:String in Biome.list) {
                for each (var biome:Object in geo.getFeaturesByType(biomeType)) {
                    for each (var cell:Cell in biome.cells) {
                        fillCell(terrainLayer.graphics, cell, Biome.colors[biomeType]);
                    }
                }
            }

            // Draw details for all cells
            for each (cell in cells)
                addCellDetail(terrainLayer.graphics, cell);
        }

        private function drawRiversLayer():void {
            /**
             * Draw Rivers
             */

            var seaColor:uint = Biome.colors[Biome.FRESH_WATER];
            for each (var river:Object in geo.getFeaturesByType(Geography.RIVER)) {
                // Create an array of river points
                riversLayer.graphics.moveTo(river.cells[0].point.x, river.cells[0].point.y);
                var i:int = 0;
                for each (var cell:Cell in river.cells) {
                    i++;
                    riversLayer.graphics.lineStyle(1 + ((i / river.cells.length) * river.cells.length) / 5, seaColor);
                    riversLayer.graphics.lineTo(cell.point.x, cell.point.y);
                }
            }
        }

        private function drawForestsLayer():void {
            /**
             * Draw Forests
             */

            // Draw Temperate Forests
            drawForests(Biome.TEMPERATE_FOREST, Biome.colors["temperateForest"], Biome.colors["temperateForest_stroke"], Biome.colors["temperateForest_bottomStroke"]);

            // Draw Boreal Forests (Draw these second because when they overlap, boreal should be on top)
            drawForests(Biome.BOREAL_FOREST, Biome.colors["borealForest"], Biome.colors["borealForest_stroke"], Biome.colors["borealForest_bottomStroke"]);

            function drawForests(type:String, fillColor:uint, outlineColor:uint, bottomOutlineColor:uint):void {
                // Draw forests
                for each (var forest:Object in geo.getFeaturesByType(type)) {
                    // Fill
                    forestsLayer.graphics.lineStyle();
                    forestsLayer.graphics.beginFill(fillColor);
                    for each (var cell:Cell in forest.cells) {
                        for (var i:int = 0; i < cell.edges.length; i++) {
                            var edge:Edge = cell.edges[i];
                            if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                                forestsLayer.graphics.moveTo(cell.point.x, cell.point.y);
                                forestsLayer.graphics.lineTo(edge.v0.point.x, edge.v0.point.y);
                                if (!edge.d0.features[forest.id]) {
                                    // Draw a curved line
                                    forestsLayer.graphics.curveTo(edge.d0.point.x, edge.d0.point.y, edge.v1.point.x, edge.v1.point.y);
                                } else if (!edge.d1.features[forest.id]) {
                                    // Draw a curved line (opposite direction)
                                    forestsLayer.graphics.curveTo(edge.d1.point.x, edge.d1.point.y, edge.v1.point.x, edge.v1.point.y);
                                } else {
                                    forestsLayer.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                                }
                            }
                        }
                    }
                    forestsLayer.graphics.endFill();

                    // Outline
                    for each (cell in forest.cells) {
                        for (i = 0; i < cell.edges.length; i++) {
                            edge = cell.edges[i];
                            if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                                forestsLayer.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                                if (!edge.d0.features[forest.id]) {
                                    // Draw a curved line
                                    forestsLayer.graphics.lineStyle(1, outlineColor);
                                    forestsLayer.graphics.curveTo(edge.d0.point.x, edge.d0.point.y, edge.v1.point.x, edge.v1.point.y);
                                } else if (!edge.d1.features[forest.id]) {
                                    forestsLayer.graphics.lineStyle(1, bottomOutlineColor);
                                    // Draw a curved line (opposite direction)
                                    forestsLayer.graphics.curveTo(edge.d1.point.x, edge.d1.point.y, edge.v1.point.x, edge.v1.point.y);
                                }
                            }
                        }
                    }
                }
            }
        }

        private function getColorFromElevation(elevation:Number):uint {
            if (elevation > 1)
                elevation = 1;

            var colors:Array = [0x4890B1, 0x6DC0A8, 0xC9E99F, 0xE6F5A3, 0xFECC7B];

            var preciseIndex:Number = (colors.length - 1) * elevation;
            var index:int = Math.floor(preciseIndex);

            var color:uint = colors[index];
            if (index < colors.length - 1 && elevation >= SEA_LEVEL)
                color = Util.getColorBetweenColors(colors[index], colors[index + 1], preciseIndex - index);

            return color;
        }

        private function getColorFromTemperature(temperature:Number):uint {
            var colors:Array = [0x0000ff, 0xf49242];

            var preciseIndex:Number = (colors.length - 1) * temperature;
            var index:int = Math.floor(preciseIndex);

            var color:uint = colors[index];
            if (index < colors.length - 1)
                color = Util.getColorBetweenColors(colors[index], colors[index + 1], preciseIndex - index);

            return color;
        }

        public function pickRandomPoints():void {
            // Pick points
            points = new Vector.<Point>;
            for (var i:int = 0; i < NUM_POINTS; i++) {
                points.push(new Point(rand.next() * width, rand.next() * height));
            }
        }

        public function build():void {
            // Setup
            var voronoi:Voronoi = new Voronoi(points, null, new Rectangle(0, 0, width, height));
            cells = new Vector.<Cell>();
            corners = new Vector.<Corner>();
            edges = new Vector.<Edge>();

            /**
             * Cells
             */

            var cellDictionary:Dictionary = new Dictionary();
            for each (var point:Point in points) {
                var cell:Cell = new Cell();
                cell.index = cells.length;
                cell.point = point;
                cells.push(cell);
                cellDictionary[point] = cell;
            }

            for each (cell in cells) {
                voronoi.region(cell.point);
            }

            /**
             * Corners
             */

            var _cornerMap:Array = [];

            function makeCorner(point:Point):Corner {
                var corner:Corner;

                if (point == null) return null;
                for (var bucket:int = int(point.x) - 1; bucket <= int(point.x) + 1; bucket++) {
                    for each (corner in _cornerMap[bucket]) {
                        var dx:Number = point.x - corner.point.x;
                        var dy:Number = point.y - corner.point.y;
                        if (dx * dx + dy * dy < 1e-6) {
                            return corner;
                        }
                    }
                }

                bucket = int(point.x);

                if (!_cornerMap[bucket]) _cornerMap[bucket] = [];

                corner = new Corner();
                corner.index = corners.length;
                corners.push(corner);

                corner.point = point;
                corner.border = (point.x == 0 || point.x == width
                        || point.y == 0 || point.y == height);

                _cornerMap[bucket].push(corner);
                return corner;
            }

            /**
             * Edges
             */

            var libEdges:Vector.<com.nodename.Delaunay.Edge> = voronoi.edges();
            for each (var libEdge:com.nodename.Delaunay.Edge in libEdges) {
                var dEdge:LineSegment = libEdge.delaunayLine();
                var vEdge:LineSegment = libEdge.voronoiEdge();

                var edge:Edge = new Edge();
                edge.index = edges.length;
                edges.push(edge);
                edge.midpoint = vEdge.p0 && vEdge.p1 && Point.interpolate(vEdge.p0, vEdge.p1, 0.5);

                edge.v0 = makeCorner(vEdge.p0);
                edge.v1 = makeCorner(vEdge.p1);
                edge.d0 = cellDictionary[dEdge.p0];
                edge.d1 = cellDictionary[dEdge.p1];

                setupEdge(edge);
            }

            /**
             * Deal with edges
             */

            borders = new Vector.<Cell>();
            for each (cell in cells) {
                for each (var corner:Corner in cell.corners) {
                    if (corner.border) {
                        borders.push(cell);
                        cell.neighbors = new Vector.<Cell>();
                        break;
                    }
                }
            }
        }

        private function setupEdge(edge:Edge):void {
            if (edge.d0 != null)
                edge.d0.edges.push(edge);

            if (edge.d1 != null)
                edge.d1.edges.push(edge);

            if (edge.v0 != null)
                edge.v0.protrudes.push(edge);

            if (edge.v1 != null)
                edge.v1.protrudes.push(edge);

            if (edge.d0 != null && edge.d1 != null) {
                addToCellList(edge.d0.neighbors, edge.d1);
                addToCellList(edge.d1.neighbors, edge.d0);
            }

            if (edge.v0 != null && edge.v1 != null) {
                addToCornerList(edge.v0.adjacent, edge.v1);
                addToCornerList(edge.v1.adjacent, edge.v0);
            }

            if (edge.d0 != null) {
                addToCornerList(edge.d0.corners, edge.v0);
                addToCornerList(edge.d0.corners, edge.v1);
            }

            if (edge.d1 != null) {
                addToCornerList(edge.d1.corners, edge.v0);
                addToCornerList(edge.d1.corners, edge.v1);
            }

            if (edge.v0 != null) {
                addToCellList(edge.v0.touches, edge.d0);
                addToCellList(edge.v0.touches, edge.d1);
            }

            if (edge.v1 != null) {
                addToCellList(edge.v1.touches, edge.d0);
                addToCellList(edge.v1.touches, edge.d1);
            }

            // Calculate Angles
            if (edge.d0 && edge.d1)
                edge.delaunayAngle = Math.atan2(edge.d1.point.y - edge.d0.point.y, edge.d1.point.x - edge.d0.point.x);

            if (edge.v0 && edge.v1)
                edge.voronoiAngle = Math.atan2(edge.v1.point.y - edge.v0.point.y, edge.v1.point.x - edge.v0.point.x);

            function addToCornerList(v:Vector.<Corner>, x:Corner):void {
                if (x != null && v.indexOf(x) < 0) {
                    v.push(x);
                }
            }

            function addToCellList(v:Vector.<Cell>, x:Cell):void {
                if (x != null && v.indexOf(x) < 0) {
                    v.push(x);
                }
            }
        }

        private function humanReadablePoint(p:Point):String {
            return "(" + p.x.toFixed(1) + ", " + p.y.toFixed(1) + ")";
        }

        private function reset():void {
            // Reset Geography
            geo.reset();
            civ.reset();

            // Reset cells
            for each (var cell:Cell in cells)
                cell.reset();

            unuseCells();
        }

        private function onClick(event:MouseEvent):void {
            var cell:Cell = getCellClosestToPoint(mouse);
            trace(humanReadableCell(cell));

            // Highlight feature
            for each (var feature:Object in cell.features) {
                if (feature.type != Geography.LAND && feature.type != Geography.LAKE)
                    break;
            }

            //highlightFeature(feature);
        }

        private function highlightFeature(feature:Object):void {
            // Highlight a feature
            highlights.graphics.clear();
            highlights.graphics.lineStyle(2, 0x000000, .4);
            for each (var cell:Cell in feature.cells) {
                for each (var edge:Edge in cell.edges) {
                    if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                        highlights.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                        if (!edge.d0.features[feature.id] || !edge.d1.features[feature.id])
                            highlights.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
                    }
                }
            }
        }

        private function humanReadableCell(cell:Cell):String {
            var str:String = "#" + cell.index;
            if (cell.settlement)
                str += "\n settlement: (" + cell.settlement.influence + ") " + cell.settlement.id;

            for each (var feature:Object in cell.features) {
                str += "\n > " + feature.type + " (" + feature.cells.length + ")";
                if (feature.ecosystem) {
                    str += " - " + feature.ecosystem.size;
                    if (feature.ecosystem.trees.length > 0)
                        str += "\n   > " + feature.ecosystem.trees;
                    if (feature.ecosystem.plants.length > 0)
                        str += "\n   > " + feature.ecosystem.plants;
                    if (feature.ecosystem.smallAnimals.length > 0)
                        str += "\n   > " + feature.ecosystem.smallAnimals;
                    if (feature.ecosystem.bigAnimals.length > 0)
                        str += "\n   > " + feature.ecosystem.bigAnimals;
                }
            }

            return str;
        }

        private function onRightClick(event:MouseEvent):void {
            highlights.graphics.clear();
        }

        public function get mouse():Point {
            // Return a point referring to the current mouse position
            return new Point(mouseX, mouseY);
        }

        public function staticModeOn():void {
            // Take screenshot
            staticMode.visible = true;
            canvas.visible = false;
        }

        public function staticModeOff():void {
            staticMode.visible = false;
            canvas.visible = true;

            // Static Mode
            var source:BitmapData = new BitmapData(this.width, this.height);
            source.draw(this);
//            const rc:Number = 1 / 3, gc:Number = 1 / 3, bc:Number = 1 / 3;
//            source.applyFilter(source, source.rect, new Point(), new ColorMatrixFilter([rc, gc, bc, 0, 0, rc, gc, bc, 0, 0, rc, gc, bc, 0, 0, 0, 0, 0, 1, 0]));
            staticMode.bitmapData = source;
            staticMode.smoothing = true;
        }
    }
}