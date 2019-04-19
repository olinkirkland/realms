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
    import generation.Civilization;
    import generation.Ecosystem;
    import generation.Geography;
    import generation.Names;
    import generation.Settlement;

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

        public var masterSeed:int;

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

        private var oceanLayer:Shape = new Shape();
        private var terrainLayer:Shape = new Shape();
        private var coastlinesLayer:Shape = new Shape();
        private var riversLayer:Shape = new Shape();
        private var forestsLayer:Shape = new Shape();
        private var mountainsLayer:Shape = new Shape();
        private var reliefLayer:Shape = new Shape();
        private var settlementsLayer:Shape = new Shape();
        private var roadsLayer:Shape = new Shape();
        private var regionsLayer:Shape = new Shape();
        private var elevationLayer:Shape = new Shape();
        private var temperatureLayer:Shape = new Shape();
        private var desirabilityLayer:Shape = new Shape();
        private var outlinesLayer:Shape = new Shape();

        // Toggles
        public var drawOcean:Boolean = true;
        public var drawTerrain:Boolean = true;
        public var drawCoastlines:Boolean = true;
        public var drawRivers:Boolean = true;
        public var drawForests:Boolean = true;
        public var drawMountains:Boolean = true;
        public var drawSettlements:Boolean = true;
        public var drawRoads:Boolean = true;
        public var drawRegions:Boolean = false;
        public var drawElevation:Boolean = false;
        public var drawTemperature:Boolean = false;
        public var drawDesirability:Boolean = false;
        public var drawOutlines:Boolean = false;


        // Miscellaneous
        private var staticMode:Bitmap;
        public static var MAP_PROGRESS:String = "mapProgress";

        public function Map() {
            // Initialize Singletons
            geo = Geography.getInstance();
            civ = Civilization.getInstance();
            names = Names.getInstance();

            // Add layers
            layers = [
                oceanLayer,
                terrainLayer,
                coastlinesLayer,
                riversLayer,
                forestsLayer,
                mountainsLayer,
                reliefLayer,
                settlementsLayer,
                roadsLayer,
                regionsLayer,
                elevationLayer,
                temperatureLayer,
                desirabilityLayer,
                outlinesLayer
            ];

            addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }

        private function onCreationComplete(event:FlexEvent):void {
            progress(0, "Preparing points");

            setTimeout(tryToLoadPoints, 500);

            addEventListener(MouseEvent.CLICK, onClick);
        }

        override protected function createChildren():void {
            super.createChildren();

            staticMode = new Bitmap();
            addChild(staticMode);

            for each (var layer:Shape in layers)
                addChild(layer);
        }

        private function tryToLoadPoints():void {
            // Does the points file exist?
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
            // Set map seed
            this.masterSeed = seed;

            reset();

            var tasks:Array = [{f: generateHeightMap, m: "Height map"},
                {f: smoothHeightMap, m: "Smoothing"},
                {f: determineOceanLandsAndLakes, m: "Oceans and lakes"},
                {f: calculateTemperature, m: "Temperature"},
                {f: calculateMoisture, m: "Moisture"},
                {f: determineRivers, m: "Rivers"},
                {f: determineBiomes, m: "Biomes"},
                {f: determineSettlements, m: "Settlements"},
                {f: determineRegions, m: "Regions (1)"},
                {f: analyzeRegionsAndDetermineNames, m: "Regions (2)"},
                {f: determineRoads, m: "Roads"},
                {f: draw, m: "Drawing"}];

            progress(0, tasks[0].m);
            setTimeout(performTask, 100, 0);

            function performTask(i:int):void {
                var timeStarted:Number = new Date().time;

                tasks[i].f();

                trace(tasks[i].m + " (" + ((new Date().time - timeStarted) / 1000).toFixed(2) + "s)");

                i++;

                if (i > tasks.length - 1) {
                    progress(1, "");
                } else {
                    progress(i / tasks.length, tasks[i].m);
                    setTimeout(performTask, 100, i);
                }
            }
        }

        private function generateHeightMap():void {
            // Initially sort cells and their neighbors
            cells.sort(Sort.sortByIndex);
            for each (var cell:Cell in cells)
                cell.neighbors.sort(Sort.sortByIndex);


            // Generate a height map
            var rand:Rand = new Rand(masterSeed);

            var w:Number = width / 2;
            var h:Number = height / 2;

            // Add mountain
            placeMountain(cellFromDistribution(0), .8, .95, .2);

            // Add hills
            for (var i:int = 0; i < 30; i++)
                placeHill(cellFromDistribution(.25), rand.between(.5, .8), rand.between(.95, .99), rand.between(1, .2));

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

            function placeMountain(start:Cell, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0):void {
                var rand:Rand = new Rand(masterSeed);

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

            function placeHill(start:Cell, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0):void {
                var rand:Rand = new Rand(masterSeed);

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

            function placePit(start:Cell, elevation:Number = 1, radius:Number = .95, sharpness:Number = 0):void {
                var rand:Rand = new Rand(masterSeed);

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
        }

        private function smoothHeightMap():void {
            cells.sort(Sort.sortByIndex);

            var depressions:int;
            do {
                depressions = 0;
                for each (var cell:Cell in cells) {

                    // Is it a depression?
                    if (cell.neighbors.length > 0) {
                        var d:Boolean = cell.elevation >= SEA_LEVEL;
                        for each (var neighbor:Cell in cell.neighbors) {
                            if (neighbor.elevation < cell.elevation)
                                d = false;
                        }
                    }

                    if (d) {
                        // If it's a depression, raise its elevation a little and increment the depression count
                        depressions++;
                        cell.elevation += .1;
                    }
                }
            } while (depressions > 0);
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

        private function determineRivers():void {
            // Create rivers
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                // Set the flux on all land cells first
                for each (var cell:Cell in land.cells)
                    cell.flux = cell.moisture;

                land.cells.sort(Sort.sortByHighestElevation);
                for each (cell in land.cells) {
                    // Pour to the lowest neighbor
                    cell.neighbors.sort(Sort.sortByLowestElevation);
                    pour(cell, cell.neighbors[0]);
                }
            }

            // Register rivers as freshwater biomes
            for each (var river:Object in geo.getFeaturesByType(Geography.RIVER)) {
                river.centroid = river.cells[int(river.cells.length / 2)].point;
                var freshWater:String = geo.registerFeature(Biome.FRESH_WATER);
                for each (cell in river.cells)
                    geo.addCellToFeature(cell, freshWater);
            }

            unuseCells();

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
        }

        private function determineBiomes():void {
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
                                coastal.coastal = true;
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

            describeBiomes();

            function describeBiomes():void {
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
                        biome.ecosystem.spreadProperties();
                }
            }
        }

        private function determineSettlements():void {
            determineStaticDesirability();

            var i:int = 0;
            do {
                determineDesirability();

                civ.registerSettlement(cells[0]);
                i++;
            } while (i < 100);
        }

        private function determineRegions():void {
            // If there are no settlements on a land mass, add one to a haven or a random place
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
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

            // Determine regionNameDictionary
            var settlements:Array = [];
            for each (var s:Settlement in civ.settlements)
                settlements.push(s);
            // Sort by a unique value - point should do
            settlements.sort(Sort.sortByCellIndex);

            for each (var settlement:Settlement in settlements) {
                var start:Cell = settlement.cell;
                // Define region
                var regionId:String = civ.registerRegion();

                var r:Rand = new Rand(1);
                civ.addCellToRegion(start, regionId, 200 + int(r.next() * 5) * 4);

                for each (land in start.getFeaturesByType(Geography.LAND))
                    break;

                civ.regions[regionId].land = land;
                civ.regions[regionId].settlement = settlement;

                start.used = true;

                var queue:Array = [start];

                while (queue.length > 0) {
                    cell = queue.shift();

                    if (cell.regionInfluence > 0) {
                        for each (var neighbor:Cell in cell.neighbors) {
                            // What's the cost of adding this cell to the region?
                            var cost:int = 1;
                            if (neighbor.hasFeatureType(Geography.OCEAN))
                                cost = 999;
                            if (neighbor.hasFeatureType(Biome.MOUNTAIN))
                                cost = 20;
                            if ((cell.hasFeatureType(Biome.TUNDRA) || cell.hasFeatureType(Biome.GRASSLAND) || cell.hasFeatureType(Biome.SAVANNA)) && (neighbor.hasFeatureType(Biome.BOREAL_FOREST) || neighbor.hasFeatureType(Biome.TEMPERATE_FOREST) || neighbor.hasFeatureType(Biome.RAIN_FOREST)))
                                cost = 10;
                            if (neighbor.hasFeatureType(Geography.RIVER) || neighbor.hasFeatureType(Geography.LAKE))
                                cost = 20;

                            var influence:int = cell.regionInfluence - cost;

                            if (!neighbor.used && neighbor.regionInfluence < influence) {
                                // Use ocean tiles, but don't add them to the region
                                if (!neighbor.hasFeatureType(Geography.OCEAN))
                                    civ.addCellToRegion(neighbor, regionId, influence);
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

            for each (var region:Object in civ.regions) {
                // Determine the center point of the region
                var avgX:Number = 0;
                var avgY:Number = 0;

                for each (cell in region.cells) {
                    avgX += cell.point.x;
                    avgY += cell.point.y;
                }

                region.centroid = new Point(avgX /= region.cells.length, avgY /= region.cells.length);

                // Lands contain a list of their contained regions
                region.land.regions.push(region);
            }
        }

        private function analyzeRegionsAndDetermineNames():void {
            names.reset();
            names.nameLands(geo.getFeaturesByType(Geography.LAND));
            names.nameRegions(civ.regions);
        }

        private function determineRoads():void {
            var settlements:Array = [];
            for each (var settlement:Settlement in civ.settlements)
                settlements.push(settlement);

            settlements.sort(Sort.sortByCellIndex);

            var settlementPoints:Vector.<Point> = new Vector.<Point>();
            for each (settlement in settlements)
                settlementPoints.push(settlement.point);

            // Create a voronoi diagram of the settlements to determine settlement neighbors
            var voronoi:Voronoi = new Voronoi(settlementPoints, null, new Rectangle(0, 0, width, height));
            for each (settlement in settlements)
                voronoi.region(settlement.point);

            for each (settlement in settlements) {
                var neighborPoints:Vector.<Point> = voronoi.neighborSitesForSite(settlement.point);
                for each (var neighborPoint:Point in neighborPoints) {
                    for each (var possibleNeighbor:Settlement in settlements) {
                        if (possibleNeighbor.point == neighborPoint) {
                            // Add a road to this neighbor
                            var road:String = civ.registerRoad(settlement, possibleNeighbor);
                            var cells:Vector.<Cell> = new Vector.<Cell>();
                            cells.push(settlement.cell, possibleNeighbor.cell);
                            civ.addCellsToRoad(cells, road);
                        }
                    }
                }
            }
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

            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                var avgX:Number = 0;
                var avgY:Number = 0;

                for each (cell in land.cells) {
                    avgX += cell.point.x;
                    avgY += cell.point.y;
                }

                land.regions = [];

                land.centroid = new Point(avgX /= land.cells.length, avgY /= land.cells.length);
            }
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

            // Draw all the layers
            drawOceanLayer();
            drawTerrainLayer();
            drawCoastlinesLayer();
            drawRiversLayer();
            drawForestsLayer();
            drawMountainsLayer();
            drawSettlementsLayer();
            drawRoadsLayer();
            drawRegionsLayer();
            drawElevationLayer();
            drawTemperatureLayer();
            drawDesirabilityLayer();
            drawOutlinesLayer();

            // The show function toggles visibility on and off for specific layers
            show();

            // Make sure it starts live, not static
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
            var rand:Rand = new Rand(Math.random() * 99);
            var iconDensity:Number = 0;
            var c:Point = new Point(cell.point.x + rand.between(-4, 4), cell.point.y + rand.between(-4, 4));
            var d:Number;

            if (cell.hasFeatureType(Biome.TEMPERATE_FOREST)) {
                iconDensity = .6;

                if (rand.next() > iconDensity)
                    return;

                if (bordersForeignType(cell, Biome.TEMPERATE_FOREST))
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
        }

        private function bordersForeignType(cell:Cell, type:String):Boolean {
            // Check that the cell isn't bordering any foreign biome types
            for each (var neighbor:Cell in cell.neighbors)
                if (!neighbor.hasFeatureType(type))
                    return true;
            return false;
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

        private function drawTerrainLayer():void {
            /**
             * Draw Terrain
             */

            terrainLayer.graphics.lineStyle();
            for each (var biomeType:String in Biome.list) {
                for each (var biome:Object in geo.getFeaturesByType(biomeType)) {
                    for each (var cell:Cell in biome.cells) {
                        fillCell(terrainLayer.graphics, cell, Biome.colors[biomeType]);
                        cell.terrainColor = Biome.colors[biomeType];
                    }
                }
            }

            // Draw details for all cells
            for each (cell in cells)
                addCellDetail(reliefLayer.graphics, cell);
        }

        private function drawCoastlinesLayer():void {
            /**
             * Draw Coastlines
             */

            var coastlineFeatureTypes:Array = [Geography.OCEAN, Geography.LAND, Geography.LAKE];
            var coastlineColors:Object = {"land": Biome.colors.saltWater_stroke, "lake": Biome.colors.freshWater_stroke}
            for each (var featureType:String in coastlineFeatureTypes) {
                for (var key:String in geo.getFeaturesByType(featureType)) {
                    var feature:Object = geo.features[key];
                    for each (var cell:Cell in feature.cells) {
                        for each (var edge:Edge in cell.edges) {
                            if (edge.v0 && edge.v1 && edge.d0 && edge.d1) {
                                if (!edge.d0.features[key] || !edge.d1.features[key]) {
                                    var noisyPoints:Array = Util.generateNoisyPoints(edge.v0.point, edge.v1.point, 2);

                                    // Fill
                                    coastlinesLayer.graphics.lineStyle();
                                    for (var i:int = 0; i < noisyPoints.length - 1; i++) {
                                        coastlinesLayer.graphics.beginFill(cell.terrainColor);
                                        coastlinesLayer.graphics.moveTo(noisyPoints[i].x, noisyPoints[i].y);
                                        coastlinesLayer.graphics.lineTo(cell.point.x, cell.point.y);
                                        coastlinesLayer.graphics.lineTo(noisyPoints[i + 1].x, noisyPoints[i + 1].y);
                                        coastlinesLayer.graphics.endFill();
                                    }

                                    // Outline
                                    if (feature.type != Geography.OCEAN) {
                                        coastlinesLayer.graphics.moveTo(noisyPoints[0].x, noisyPoints[0].y);
                                        coastlinesLayer.graphics.lineStyle(1, coastlineColors[featureType]);
                                        for each (var point:Point in noisyPoints)
                                            coastlinesLayer.graphics.lineTo(point.x, point.y);
                                    }
                                }
                            }
                        }
                    }
                }
            }
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
                // Draw forests of a specific type
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

        private function drawMountainsLayer():void {
            /**
             * Draw Mountains
             */

            // todo
        }

        private function drawSettlementsLayer():void {
            /**
             * Draw Settlements
             */

            settlementsLayer.graphics.lineStyle(1, 0x000000);
            for each (var settlement:Settlement in civ.settlements) {
                settlementsLayer.graphics.beginFill(0xffffff);
                settlementsLayer.graphics.drawCircle(settlement.point.x, settlement.point.y, 3);
                settlementsLayer.graphics.endFill();
            }
        }

        private function drawRoadsLayer():void {
            /**
             * Draw Roads
             */

            for each (var road:Object in civ.roads) {
                roadsLayer.graphics.lineStyle(1, Util.randomColor());
                roadsLayer.graphics.drawCircle(road.cells[0].point.x, road.cells[0].point.y, 7);
                roadsLayer.graphics.moveTo(road.cells[0].point.x, road.cells[0].point.y);
                for each (var cell:Cell in road.cells) {
                    roadsLayer.graphics.lineTo(cell.point.x, cell.point.y);
                }
            }
        }

        private function drawRegionsLayer():void {
            /**
             * Draw Regions
             */

            var rand:Rand = new Rand(1);
            regionsLayer.graphics.lineStyle();
            for each (var region:Object in civ.regions) {
                var color:uint = 0xffffff * rand.next();
                for each (var cell:Cell in region.cells)
                    fillCell(regionsLayer.graphics, cell, color);
            }
        }

        private function drawElevationLayer():void {
            /**
             * Draw Elevation
             */

            elevationLayer.graphics.lineStyle();
            for each (var cell:Cell in cells)
                fillCell(elevationLayer.graphics, cell, getColorFromElevation(cell.elevation));
        }

        private function drawTemperatureLayer():void {
            /**
             * Draw Temperature
             */

            temperatureLayer.graphics.lineStyle();
            for each (var cell:Cell in cells) {
                if (cell.elevation > SEA_LEVEL)
                    fillCell(temperatureLayer.graphics, cell, getColorFromTemperature(cell.temperature));
            }
        }

        private function drawDesirabilityLayer():void {
            /**
             * Draw Desirability
             */

            desirabilityLayer.graphics.lineStyle();
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                for each (var cell:Cell in land.cells)
                    fillCell(desirabilityLayer.graphics, cell, Util.getColorBetweenColors(0x0000ff, 0xffff00, cell.desirability / 10));
            }
        }

        private function drawOutlinesLayer():void {
            /**
             * Draw outlines
             */
            for each (var edge:Edge in edges) {
                // Draw voronoi diagram
                outlinesLayer.graphics.lineStyle(1, 0x000000, .1);
                if (edge.v0 && edge.v1) {
                    outlinesLayer.graphics.moveTo(edge.v0.point.x, edge.v0.point.y);
                    outlinesLayer.graphics.lineTo(edge.v1.point.x, edge.v1.point.y);
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
            var rand:Rand = new Rand(1);
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

            cells.sort(Sort.sortByIndex);

            unuseCells();
        }

        private function onClick(event:MouseEvent):void {
            var cell:Cell = getCellClosestToPoint(mouse);
            trace(humanReadableCell(cell));
        }

        private function humanReadableCell(cell:Cell):String {
            var str:String = "#" + cell.index;
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

            //var region:Object = civ.regions[cell.region];

            return str;
        }

        public function get mouse():Point {
            // Return a point referring to the current mouse position
            return new Point(mouseX, mouseY);
        }

        public function staticModeOn():void {
            // Show screenshot
            staticMode.visible = true;
            hide();
        }

        public function staticModeOff():void {
            // Hide screenshot
            staticMode.visible = false;
            show();

            // Static Mode
            var source:BitmapData = new BitmapData(this.width, this.height);
            source.draw(this);
            staticMode.bitmapData = source;
            staticMode.smoothing = true;
        }

        public function hide():void {
            for each (var layer:Shape in layers)
                layer.visible = false;
        }

        public function show():void {
            oceanLayer.visible = drawOcean;
            terrainLayer.visible = drawTerrain;
            reliefLayer.visible = drawTerrain;
            coastlinesLayer.visible = drawCoastlines;
            riversLayer.visible = drawRivers;
            forestsLayer.visible = drawForests;
            mountainsLayer.visible = drawMountains;
            settlementsLayer.visible = drawSettlements;
            roadsLayer.visible = drawRoads;
            regionsLayer.visible = drawRegions;
            elevationLayer.visible = drawElevation;
            temperatureLayer.visible = drawTemperature;
            desirabilityLayer.visible = drawDesirability;
            outlinesLayer.visible = drawOutlines;
        }
    }
}